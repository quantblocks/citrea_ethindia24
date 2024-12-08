// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/MathLib.sol";
import "./libraries/TWAPLib.sol";
import "./libraries/VolatilityLib.sol";
import "./interfaces/ILightClient.sol";
import "./interfaces/IBridge.sol";
import "./CBTC.sol";
import "./StableCoin.sol";
import "./interfaces/IAggregatorOracle.sol";
import "./interfaces/ICGOV.sol";

contract AMMDEX is Ownable {
    using MathLib for uint256;
    using TWAPLib for TWAPLib.TWAPData;

    CBTC public cBTC;
    StableCoin public cUSD;
    ILightClient public lightClient;
    IBridge public bridge;
    IAggregatorOracle public aggregator;
    ICGOV public cGOV;

    uint256 public cBTCReserve;   
    uint256 public cUSDReserve;   

    uint256 public lpFeeBasisPoints; 
    uint256 public protocolFeeBasisPoints;
    address public treasury;

    mapping(address => uint256) public lpBalances;
    uint256 public totalLPSupply;

    TWAPLib.TWAPData public twapData;
    uint256[] public recentPrices;
    uint256 public volatilityThreshold = 100000; // Stub

    event LiquidityAdded(address indexed provider, uint256 cBTCAmount, uint256 cUSDAmount, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 cBTCAmount, uint256 cUSDAmount, uint256 lpTokensBurned);
    event Swapped(address indexed trader, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event BTCBridgedIn(address indexed user, uint256 amount, bytes btcTxProof);
    event BTCBridgedOut(address indexed user, bytes32 btcAddress, uint256 amount);
    event FlashLoan(address indexed borrower, address token, uint256 amount, uint256 fee);

    constructor(
        address _cBTC,
        address _cUSD,
        address _lightClient,
        address _bridge,
        address _aggregatorOracle,
        address _cGOV,
        uint256 _lpFeeBasisPoints,
        uint256 _protocolFeeBasisPoints,
        address _treasury
    ) Ownable(msg.sender) {
        require(_cBTC != address(0), "Invalid cBTC");
        require(_cUSD != address(0), "Invalid cUSD");
        require(_lightClient != address(0), "Invalid Light Client");
        require(_bridge != address(0), "Invalid Bridge");
        require(_aggregatorOracle != address(0), "Invalid Aggregator");
        require(_cGOV != address(0), "Invalid cGOV");
        require(_treasury != address(0), "Invalid treasury");

        cBTC = CBTC(_cBTC);
        cUSD = StableCoin(_cUSD);
        lightClient = ILightClient(_lightClient);
        bridge = IBridge(_bridge);
        aggregator = IAggregatorOracle(_aggregatorOracle);
        cGOV = ICGOV(_cGOV);
        lpFeeBasisPoints = _lpFeeBasisPoints;
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
        treasury = _treasury;

        twapData.lastTimestamp = block.timestamp;
        twapData.lastPrice = 1e18;
    }

    function addLiquidity(uint256 cBTCAmount, uint256 cUSDAmount) external {
        require(cBTCAmount > 0 && cUSDAmount > 0, "Amounts must be >0");
        require(cBTC.transferFrom(msg.sender, address(this), cBTCAmount), "cBTC transfer failed");
        require(IERC20(address(cUSD)).transferFrom(msg.sender, address(this), cUSDAmount), "cUSD transfer failed");

        uint256 lpTokens;
        if (cBTCReserve == 0 && cUSDReserve == 0) {
            lpTokens = (cBTCAmount * cUSDAmount).sqrt();
        } else {
            require((cBTCAmount * 1e18) / cBTCReserve == (cUSDAmount * 1e18) / cUSDReserve, "Incorrect ratio");
            lpTokens = (cBTCAmount * totalLPSupply) / cBTCReserve;
        }

        lpBalances[msg.sender] += lpTokens;
        totalLPSupply += lpTokens;
        cBTCReserve += cBTCAmount;
        cUSDReserve += cUSDAmount;

        cGOV.mint(msg.sender, lpTokens / 100);
        emit LiquidityAdded(msg.sender, cBTCAmount, cUSDAmount, lpTokens);

        updateTWAP();
    }

    function removeLiquidity(uint256 lpTokens) external {
        require(lpBalances[msg.sender] >= lpTokens, "Not enough LP");

        uint256 cBTCAmt = (lpTokens * cBTCReserve) / totalLPSupply;
        uint256 cUSDAmt = (lpTokens * cUSDReserve) / totalLPSupply;

        lpBalances[msg.sender] -= lpTokens;
        totalLPSupply -= lpTokens;

        cBTCReserve -= cBTCAmt;
        cUSDReserve -= cUSDAmt;

        require(cBTC.transfer(msg.sender, cBTCAmt), "cBTC transfer failed");
        require(IERC20(address(cUSD)).transfer(msg.sender, cUSDAmt), "cUSD transfer failed");

        emit LiquidityRemoved(msg.sender, cBTCAmt, cUSDAmt, lpTokens);
        updateTWAP();
    }

    function swapCBTCForCUSD(uint256 cBTCAmtIn, uint256 minCUSDOut) external {
        require(cBTCAmtIn > 0, "Amount in must be > 0");
        require(cBTC.transferFrom(msg.sender, address(this), cBTCAmtIn), "cBTC in failed");

        uint256 totalFee = (cBTCAmtIn * (lpFeeBasisPoints + protocolFeeBasisPoints)) / 10000;
        uint256 cBTCAmtInAfterFee = cBTCAmtIn - totalFee;

        uint256 k = cBTCReserve * cUSDReserve;
        uint256 newCBTCReserve = cBTCReserve + cBTCAmtInAfterFee;
        uint256 newCUSDReserve = k / newCBTCReserve;
        uint256 cUSDOut = cUSDReserve - newCUSDReserve;

        require(cUSDOut >= minCUSDOut, "Slippage too high");
        require(cUSDOut > 0, "No output");

        uint256 protocolFee = (cBTCAmtIn * protocolFeeBasisPoints) / 10000;
        cBTCReserve = newCBTCReserve;
        cUSDReserve = newCUSDReserve;

        cBTC.transfer(treasury, protocolFee);

        require(IERC20(address(cUSD)).transfer(msg.sender, cUSDOut), "cUSD out failed");

        emit Swapped(msg.sender, address(cBTC), address(cUSD), cBTCAmtIn, cUSDOut);
        updateTWAP();
    }

    function swapCUSDForCBTC(uint256 cUSDAmtIn, uint256 minCBTCOut) external {
        require(cUSDAmtIn > 0, "Amount in must be > 0");
        require(IERC20(address(cUSD)).transferFrom(msg.sender, address(this), cUSDAmtIn), "cUSD in failed");

        uint256 totalFee = (cUSDAmtIn * (lpFeeBasisPoints + protocolFeeBasisPoints)) / 10000;
        uint256 cUSDAmtInAfterFee = cUSDAmtIn - totalFee;

        uint256 k = cBTCReserve * cUSDReserve;
        uint256 newCUSDReserve = cUSDReserve + cUSDAmtInAfterFee;
        uint256 newCBTCReserve = k / newCUSDReserve;
        uint256 cBTCOut = cBTCReserve - newCBTCReserve;

        require(cBTCOut >= minCBTCOut, "Slippage too high");
        require(cBTCOut > 0, "No output");

        uint256 protocolFee = (cUSDAmtIn * protocolFeeBasisPoints) / 10000;

        cUSDReserve = newCUSDReserve;
        cBTCReserve = newCBTCReserve;

        IERC20(address(cUSD)).transfer(treasury, protocolFee);
        require(cBTC.transfer(msg.sender, cBTCOut), "cBTC out failed");

        emit Swapped(msg.sender, address(cUSD), address(cBTC), cUSDAmtIn, cBTCOut);
        updateTWAP();
    }

    function updateTWAP() internal {
        if (cBTCReserve > 0) {
            uint256 currentPrice = (cUSDReserve * 1e18) / cBTCReserve;
            twapData.updateTWAP(currentPrice);
        }
    }

    function getTWAP() external view returns (uint256) {
        return twapData.getTWAP();
    }

    function setFee(uint256 _lpFeeBasisPoints, uint256 _protocolFeeBasisPoints) external onlyOwner {
        require(_lpFeeBasisPoints + _protocolFeeBasisPoints <= 500, "Fee too high");
        lpFeeBasisPoints = _lpFeeBasisPoints;
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
    }

    function getBTCBlockHeight() external view returns (uint256) {
        return lightClient.getLatestBlockHeight();
    }

    function bridgeBTCIn(uint256 amount, bytes calldata btcTxProof) external {
        require(lightClient.verifyTransaction(btcTxProof), "Invalid BTC tx proof");
        bool success = bridge.transferFromBitcoin(address(this), amount, btcTxProof);
        require(success, "Bridge in failed");
        cBTC.mint(msg.sender, amount);
        emit BTCBridgedIn(msg.sender, amount, btcTxProof);
    }

    function bridgeBTCOut(bytes32 btcAddress, uint256 amount) external {
        require(cBTC.balanceOf(msg.sender) >= amount, "Not enough cBTC");
        cBTC.transferFrom(msg.sender, address(this), amount);
        cBTC.burn(address(this), amount);
        bool success = bridge.transferToBitcoin(btcAddress, amount);
        require(success, "Bridge out failed");
        emit BTCBridgedOut(msg.sender, btcAddress, amount);
    }

    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Not enough liquidity");

        uint256 fee = (amount * 5) / 10000;
        IERC20(token).transfer(msg.sender, amount);

        (bool success, ) = msg.sender.call(data);
        require(success, "Flash loan callback failed");

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "Flash loan not returned with fee");

        IERC20(token).transfer(treasury, fee);
        emit FlashLoan(msg.sender, token, amount, fee);
    }
}
