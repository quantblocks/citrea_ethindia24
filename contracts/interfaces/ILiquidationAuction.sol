// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ILiquidationAuction {
    function createAuction(
        address user,
        address collateralToken,
        uint256 collateralAmount,
        uint256 debtToRepay
    ) external returns (uint256);

    function bidAuction(uint256 auctionId, uint256 bidAmount) external;
}
