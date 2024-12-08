// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library VolatilityLib {
    function isVolatile(uint256[] memory /*prices*/, uint256 /*threshold*/) internal pure returns (bool) {
        return false;
    }
}
