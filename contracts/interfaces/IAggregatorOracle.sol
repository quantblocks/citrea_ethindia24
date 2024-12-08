// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAggregatorOracle {
    function getMedianPrice(address token) external view returns (uint256);
    function addOracle(address token, address oracle) external;
    function removeOracle(address token, address oracle) external;
}
