// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRateModel.sol";

contract RateModel is Ownable, IRateModel {
    uint256 public baseRate;
    uint256 public utilizationSlope;

    constructor(
        address initialOwner,
        uint256 _baseRate,
        uint256 _utilizationSlope
    ) Ownable(initialOwner) {
        baseRate = _baseRate;
        utilizationSlope = _utilizationSlope;
    }

    function getRate(uint256 utilization) external view override returns (uint256) {
        return baseRate + ((utilization * utilizationSlope) / 1e18);
    }

    function setBaseRate(uint256 _baseRate) external onlyOwner {
        baseRate = _baseRate;
    }

    function setUtilizationSlope(uint256 _utilizationSlope) external onlyOwner {
        utilizationSlope = _utilizationSlope;
    }
}
