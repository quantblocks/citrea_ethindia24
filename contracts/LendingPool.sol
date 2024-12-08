// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IStableCoin.sol";
import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool is Ownable, ILendingPool {
    IStableCoin public stableCoin;
    IERC20 public cBTC;
    IPriceOracle public oracle;

    constructor(address _stableCoin, address _cBTC, address _oracle) Ownable(msg.sender) {
        require(_stableCoin != address(0), "Invalid StableCoin");
        require(_cBTC != address(0), "Invalid cBTC");
        require(_oracle != address(0), "Invalid Oracle");

        stableCoin = IStableCoin(_stableCoin);
        cBTC = IERC20(_cBTC);
        oracle = IPriceOracle(_oracle);
    }

    function borrow(address borrower, uint256 amount) external override {
        require(borrower != address(0), "Invalid borrower");
        stableCoin.accrueInterest();
      
        uint256 price = oracle.getPrice(address(cBTC));
        uint256 userCollateral = stableCoinDeposits(borrower);
        uint256 userDebt = IERC20(address(stableCoin)).balanceOf(borrower) + amount;

        require(
            userCollateral * price * 1e18 >= userDebt * stableCoin.getCollateralRatio(),
            "Not enough collateral"
        );

        stableCoin.mintStableCoin(borrower, amount);
    }

    function repay(address borrower, uint256 amount) external override {
        require(borrower != address(0), "Invalid borrower");
        require(amount > 0, "Amount must be greater than 0");

        bool success = IERC20(address(stableCoin)).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        stableCoin.burnStableCoin(address(this), amount);
    }

    function checkHealth(address user) external view override returns (uint256) {
        require(user != address(0), "Invalid user");

        uint256 price = oracle.getPrice(address(cBTC));
        uint256 userCollateral = stableCoinDeposits(user);
        uint256 userDebt = IERC20(address(stableCoin)).balanceOf(user);

        if (userDebt == 0) return type(uint256).max;

        return (userCollateral * price * 1e18) / (userDebt * stableCoin.getCollateralRatio());
    }

    function liquidateBorrower(address borrower) external override {
        require(borrower != address(0), "Invalid borrower");

        uint256 userDebt = IERC20(address(stableCoin)).balanceOf(borrower);
        require(userDebt > 0, "No outstanding debt");

        uint256 halfDebt = userDebt / 2;
        bool success = IERC20(address(stableCoin)).transferFrom(msg.sender, address(this), halfDebt);
        require(success, "Transfer failed");

        stableCoin.liquidate(borrower, halfDebt);
    }

    function stableCoinDeposits(address user) internal view returns (uint256) {
        require(user != address(0), "Invalid user");

        (bool success, bytes memory data) = address(stableCoin).staticcall(
            abi.encodeWithSignature("cBTCDeposits(address)", user)
        );

        require(success, "No cBTCDeposits method");
        return abi.decode(data, (uint256));
    }
}
