// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle {
    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    function getPrice(address token) external view override returns (uint256) {
        return prices[token];
    }
}

