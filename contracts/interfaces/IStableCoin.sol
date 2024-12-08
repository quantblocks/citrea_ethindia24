// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStableCoin {
    function mintStableCoin(address to, uint256 cUSDAmount) external;
    function burnStableCoin(address from, uint256 cUSDAmount) external;
    function depositCollateral(address user, uint256 amount) external;
    function withdrawCollateral(address user, uint256 amount) external;
    function getCollateralRatio() external view returns (uint256);
    function accrueInterest() external;
    function liquidate(address user, uint256 cUSDAmount) external;
}
