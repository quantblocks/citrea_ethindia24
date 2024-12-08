// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IAggregatorOracle.sol";
import "./interfaces/ICollateralManager.sol";

contract CollateralManager is Ownable, ICollateralManager {
    struct CollateralInfo {
        bool isActive;
        uint256 collateralFactor; 
        uint256 liquidationPenalty;
    }

    mapping(address => CollateralInfo) public collaterals;
    IAggregatorOracle public aggregator;

    constructor(address initialOwner, address _aggregator) Ownable(initialOwner) {
        aggregator = IAggregatorOracle(_aggregator);
    }

    function addCollateral(address token, uint256 factor, uint256 penalty) external onlyOwner {
        collaterals[token] = CollateralInfo({
            isActive: true,
            collateralFactor: factor,
            liquidationPenalty: penalty
        });
    }

    function removeCollateral(address token) external onlyOwner {
        collaterals[token].isActive = false;
    }

    function getCollateralFactor(address token) external view returns (uint256) {
        return collaterals[token].collateralFactor;
    }

    function getLiquidationPenalty(address token) external view returns (uint256) {
        return collaterals[token].liquidationPenalty;
    }

    function isCollateralActive(address token) external view returns (bool) {
        return collaterals[token].isActive;
    }

    function getPrice(address token) external view returns (uint256) {
        return aggregator.getMedianPrice(token);
    }
}
