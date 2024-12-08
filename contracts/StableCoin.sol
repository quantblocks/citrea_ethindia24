// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IStableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title StableCoin
 * @dev A simple stablecoin implementation that uses cBTC as collateral.
 *      Supports accruing a stability fee over time, minting, burning, and liquidation.
 */
contract StableCoin is ERC20, Ownable, IStableCoin {
    IERC20 public cBTC;
    IPriceOracle public oracle;

    uint256 public collateralRatio; // expressed as a scaled integer with 1e18 = 100%
    uint256 public stabilityFee;    // annual stability fee in basis points (bps)
    uint256 public lastAccrualTime;

    mapping(address => uint256) public cBTCDeposits; // Track how much cBTC each user has deposited

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Minted(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 debtRepaid, uint256 collateralSeized);

    constructor(
        address _cBTC,
        uint256 _collateralRatio,
        address _oracle,
        uint256 _stabilityFee
    ) ERC20("Citrea USD", "cUSD") Ownable(msg.sender) {
        require(_cBTC != address(0), "Invalid cBTC address");
        require(_oracle != address(0), "Invalid oracle");
        require(_collateralRatio >= 1e18, "Ratio must be >= 100%");

        cBTC = IERC20(_cBTC);
        collateralRatio = _collateralRatio;
        oracle = IPriceOracle(_oracle);
        stabilityFee = _stabilityFee;
        lastAccrualTime = block.timestamp;
    }

    /**
     * @dev Accrues interest on the stablecoin supply by minting stability fee to owner.
     *      Stability fee accumulates over time, increasing total supply.
     */
    function accrueInterest() public override {
        uint256 timeElapsed = block.timestamp - lastAccrualTime;
        if (timeElapsed > 0 && totalSupply() > 0) {
            // stabilityFee is annual bps, so feeFraction = (stabilityFee * timeElapsed / secondsPerYear) / 10000
            uint256 feeFraction = (stabilityFee * timeElapsed) / 31536000; // seconds per year
            uint256 additionalSupply = (totalSupply() * feeFraction) / 10000;
            if (additionalSupply > 0) {
                _mint(owner(), additionalSupply);
            }
            lastAccrualTime = block.timestamp;
        }
    }

    function getCollateralRatio() external view override returns (uint256) {
        return collateralRatio;
    }

    /**
     * @dev Deposit cBTC as collateral.
     */
    function depositCollateral(address user, uint256 amount) external override {
        require(amount > 0, "Amount must be > 0");
        require(cBTC.transferFrom(user, address(this), amount), "cBTC transfer failed");
        cBTCDeposits[user] += amount;
        emit CollateralDeposited(user, amount);
    }

    /**
     * @dev Withdraw cBTC collateral as long as the user remains over-collateralized.
     */
    function withdrawCollateral(address user, uint256 amount) external override {
        accrueInterest();
        require(amount <= cBTCDeposits[user], "Not enough collateral");

        uint256 userDebt = balanceOf(user);
        uint256 price = oracle.getPrice(address(cBTC));
        uint256 requiredCollateral = (userDebt * collateralRatio) / 1e18;
        // Convert required cUSD collateral value to cBTC amount
        requiredCollateral = (requiredCollateral * 1e18) / price;

        uint256 maxWithdraw = cBTCDeposits[user] > requiredCollateral
            ? cBTCDeposits[user] - requiredCollateral
            : 0;

        require(amount <= maxWithdraw, "Withdrawal would undercollateralize");
        cBTCDeposits[user] -= amount;
        require(cBTC.transfer(user, amount), "cBTC transfer failed");
        emit CollateralWithdrawn(user, amount);
    }

    /**
     * @dev Mint stablecoins if the user has enough collateral.
     */
    function mintStableCoin(address to, uint256 cUSDAmount) external override {
        accrueInterest();
        uint256 price = oracle.getPrice(address(cBTC));
        uint256 requiredCollateral = (cUSDAmount * collateralRatio) / 1e18;
        requiredCollateral = (requiredCollateral * 1e18) / price;
        require(cBTCDeposits[msg.sender] >= requiredCollateral, "Not enough collateral");
        _mint(to, cUSDAmount);
        emit Minted(msg.sender, cUSDAmount);
    }

    /**
     * @dev Burn stablecoins from the user's balance.
     */
    function burnStableCoin(address from, uint256 cUSDAmount) external override {
        accrueInterest();
        require(balanceOf(from) >= cUSDAmount, "Not enough cUSD");
        _burn(from, cUSDAmount);
        emit Redeemed(from, cUSDAmount);
    }

    /**
     * @dev Liquidate an undercollateralized user.
     *      A liquidator repays a portion of the user's debt, and in return seizes collateral
     *      at a discount.
     */
    function liquidate(address user, uint256 cUSDAmount) external override {
        accrueInterest();
        uint256 price = oracle.getPrice(address(cBTC));
        uint256 userDebt = balanceOf(user);
        if (userDebt == 0) return;

        // Check if undercollateralized
        // Required value in cUSD = userDebt * collateralRatio
        uint256 requiredValue = (userDebt * collateralRatio) / 1e18; // cUSD value required
        uint256 userCollateralValue = (cBTCDeposits[user] * price) / 1e18;

        if (userCollateralValue < requiredValue) {
            uint256 repayAmount = cUSDAmount > userDebt ? userDebt : cUSDAmount;
            require(balanceOf(msg.sender) >= repayAmount, "Liquidator not enough cUSD");
            _transfer(msg.sender, address(this), repayAmount);
            _burn(address(this), repayAmount);

            // Seize collateral with a 10% liquidation bonus
            uint256 collateralSeize = (repayAmount * collateralRatio) / 1e18;
            collateralSeize = (collateralSeize * 1e18) / price;
            collateralSeize = (collateralSeize * 110) / 100; 
            if (collateralSeize > cBTCDeposits[user]) {
                collateralSeize = cBTCDeposits[user];
            }

            cBTCDeposits[user] -= collateralSeize;
            require(cBTC.transfer(msg.sender, collateralSeize), "cBTC transfer failed");

            // Reduce userDebt
            // Already done by burning the repaid cUSD
            emit Liquidated(user, repayAmount, collateralSeize);
        }
    }

    /**
     * @dev Owner can update collateral ratio.
     */
    function setCollateralRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio >= 1e18, "Ratio must be >= 100%");
        collateralRatio = _newRatio;
    }

    /**
     * @dev Owner can set the stability fee (annualized in bps).
     */
    function setStabilityFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 2000, "Fee too high");
        stabilityFee = _newFee;
    }

    /**
     * @dev Get how much cBTC collateral a user has deposited.
     */
    function getUserCollateral(address user) external view returns (uint256) {
        return cBTCDeposits[user];
    }
}
