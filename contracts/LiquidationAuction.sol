// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILiquidationAuction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidationAuction is Ownable, ILiquidationAuction {
    struct Auction {
        address user;
        address collateralToken;
        uint256 collateralAmount;
        uint256 debtToRepay;
        uint256 startTime;
        bool active;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;
    IERC20 public stableCoin; // cUSD

    event AuctionCreated(uint256 indexed auctionId, address user, address collateralToken, uint256 collateralAmount, uint256 debtToRepay);
    event Bid(uint256 indexed auctionId, address bidder, uint256 bidAmount);
    event AuctionWon(uint256 indexed auctionId, address winner, uint256 collateralReceived);

    constructor(address initialOwner, address _stableCoin) Ownable(initialOwner) {
        stableCoin = IERC20(_stableCoin);
    }

    function createAuction(
        address user,
        address collateralToken,
        uint256 collateralAmount,
        uint256 debtToRepay
    ) external onlyOwner returns (uint256) {
        auctionCount++;
        auctions[auctionCount] = Auction({
            user: user,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount,
            debtToRepay: debtToRepay,
            startTime: block.timestamp,
            active: true
        });
        emit AuctionCreated(auctionCount, user, collateralToken, collateralAmount, debtToRepay);
        return auctionCount;
    }

    function bidAuction(uint256 auctionId, uint256 bidAmount) external {
        Auction storage a = auctions[auctionId];
        require(a.active, "Auction not active");
        // For simplicity, highest bid wins instantly
        require(stableCoin.transferFrom(msg.sender, address(this), bidAmount), "Transfer failed");
        // Close the auction
        a.active = false;
        // Transfer collateral to bidder
        IERC20(a.collateralToken).transfer(msg.sender, a.collateralAmount);
        emit AuctionWon(auctionId, msg.sender, a.collateralAmount);
    }
}
