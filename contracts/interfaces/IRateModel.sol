// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRateModel {
    function getRate(uint256 utilization) external view returns (uint256);
}
