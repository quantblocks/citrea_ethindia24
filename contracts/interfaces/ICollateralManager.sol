// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICollateralManager {
    function getCollateralFactor(address token) external view returns (uint256);
    function getLiquidationPenalty(address token) external view returns (uint256);
    function isCollateralActive(address token) external view returns (bool);
    function getPrice(address token) external view returns (uint256);
}
