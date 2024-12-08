// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStableCoin is IERC20 {
    // If we want to call specialized functions from  StableCoin
}

interface IAggregatorOracle {
    function getMedianPrice(address token) external view returns (uint256);
}

interface IDexInterface {
    function swapCBTCForCUSD(uint256 cBTCAmtIn, uint256 minCUSDOut) external;
}

interface ICBTC is IERC20 {
    // If our cBTC contract has special methods, add them here.
}

contract PaymentGateway is Ownable(msg.sender) {
    struct Merchant {
        address payable payoutAddress;
        bool active;
    }

    mapping(bytes32 => Merchant) public merchants;
    mapping(bytes32 => uint256) public merchantBalances;

    IStableCoin public stableCoin;
    ICBTC public cBTC;
    IAggregatorOracle public aggregator;
    IDexInterface public dex;

    event MerchantRegistered(bytes32 indexed merchantId, address payoutAddress);
    event MerchantUpdated(bytes32 indexed merchantId, address payoutAddress, bool active);
    event PaymentReceived(bytes32 indexed merchantId, address indexed buyer, uint256 amount);
    event MerchantWithdrawn(bytes32 indexed merchantId, uint256 amount, address payoutAddress);

    /**
     * @dev Constructor setting the addresses of stablecoin, aggregator, cBTC, and dex
     * @param _stableCoin The address of cUSD stablecoin
     * @param _cBTC The address of the cBTC token
     * @param _aggregator The address of the aggregator oracle
     * @param _dex The address of the AMM DEX
     */
    constructor(
        address _stableCoin,
        address _cBTC,
        address _aggregator,
        address _dex
    ) {
        require(_stableCoin != address(0), "Invalid stablecoin address");
        require(_cBTC != address(0), "Invalid cBTC address");
        require(_aggregator != address(0), "Invalid aggregator address");
        require(_dex != address(0), "Invalid DEX address");

        stableCoin = IStableCoin(_stableCoin);
        cBTC = ICBTC(_cBTC);
        aggregator = IAggregatorOracle(_aggregator);
        dex = IDexInterface(_dex);
    }

    /**
     * @dev Register a merchant.
     * @param merchantId A unique identifier for the merchant (e.g. keccak256("merchantName"))
     * @param payoutAddress The address where merchant wants to receive funds
     */
    function registerMerchant(bytes32 merchantId, address payable payoutAddress) external onlyOwner {
        require(merchantId != 0x0, "Invalid merchantId");
        require(payoutAddress != address(0), "Invalid payout address");
        require(!merchants[merchantId].active, "Merchant already registered");

        merchants[merchantId] = Merchant({
            payoutAddress: payoutAddress,
            active: true
        });

        emit MerchantRegistered(merchantId, payoutAddress);
    }

    /**
     * @dev Update merchant info.
     * @param merchantId The merchant identifier
     * @param payoutAddress New payout address
     * @param active New active status
     */
    function updateMerchant(bytes32 merchantId, address payable payoutAddress, bool active) external onlyOwner {
        require(merchants[merchantId].active, "Merchant not registered");
        require(payoutAddress != address(0), "Invalid payout address");

        merchants[merchantId].payoutAddress = payoutAddress;
        merchants[merchantId].active = active;
        emit MerchantUpdated(merchantId, payoutAddress, active);
    }

    /**
     * @dev Pay a merchant directly in cUSD. User must have approved this contract to spend cUSD.
     * @param merchantId The merchant to pay
     * @param amount The amount of cUSD to pay
     */
    function payMerchant(bytes32 merchantId, uint256 amount) external {
        Merchant memory m = merchants[merchantId];
        require(m.active, "Merchant not active");

        require(stableCoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        merchantBalances[merchantId] += amount;

        emit PaymentReceived(merchantId, msg.sender, amount);
    }

    /**
     * @dev Merchant withdraws their accumulated cUSD funds.
     * Only owner can trigger this withdrawal in the current example.
     * A real scenario would allow the merchant themselves to withdraw.
     * @param merchantId The merchant ID
     */
    function withdrawMerchantFunds(bytes32 merchantId) external onlyOwner {
        require(merchants[merchantId].active, "Merchant not active");
        uint256 balance = merchantBalances[merchantId];
        require(balance > 0, "No balance to withdraw");

        merchantBalances[merchantId] = 0;
        address payable payout = merchants[merchantId].payoutAddress;

        require(stableCoin.transfer(payout, balance), "Transfer failed");
        emit MerchantWithdrawn(merchantId, balance, payout);
    }

    /**
     * @dev Pay a merchant using cBTC. This function:
     * 1. Calculates how much cBTC is needed for the target cUSD amount using aggregator prices.
     * 2. Transfers cBTC from the user.
     * 3. Approves the DEX to spend cBTC.
     * 4. Calls the DEX to swap cBTC into cUSD.
     * 5. Credits the merchant in cUSD.
     *
     * User must have approved this contract to spend cBTC.
     *
     * @param merchantId The merchant to pay
     * @param cUSDTargetAmount How many cUSD the merchant should receive
     */
    function payMerchantInCBTC(bytes32 merchantId, uint256 cUSDTargetAmount) external {
        Merchant memory m = merchants[merchantId];
        require(m.active, "Merchant not active");

        // Get price of cBTC in terms of cUSD from the aggregator
        uint256 cBTCPriceInCUSD = aggregator.getMedianPrice(address(cBTC));
        require(cBTCPriceInCUSD > 0, "Invalid price");

        // Calculate required cBTC: cUSDTargetAmount / (cBTCPriceInCUSD/1e18) = (cUSDTargetAmount * 1e18) / cBTCPriceInCUSD
        uint256 cBTCAmount = (cUSDTargetAmount * 1e18) / cBTCPriceInCUSD;

        // Transfer cBTC from user
        require(cBTC.transferFrom(msg.sender, address(this), cBTCAmount), "Transfer failed");

        // Approve DEX to spend cBTC
        require(cBTC.approve(address(dex), cBTCAmount), "cBTC approve failed");

        // Perform the swap on the DEX
        // We expect at least cUSDTargetAmount out. If market conditions changed,
        // you might want to allow some slippage. Here we require exact or better.
        dex.swapCBTCForCUSD(cBTCAmount, cUSDTargetAmount);

        // After swap, this contract now has at least cUSDTargetAmount in stableCoin
        merchantBalances[merchantId] += cUSDTargetAmount;

        emit PaymentReceived(merchantId, msg.sender, cUSDTargetAmount);
    }
}
