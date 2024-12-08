// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IInsuranceFund.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InsuranceFund is Ownable, IInsuranceFund {
    // Constructor to initialize the owner
    constructor(address initialOwner) Ownable(initialOwner) {}

    // The fund can hold multiple tokens, primarily cUSD, cBTC, etc.
    function deposit(address token, uint256 amount) external {
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function withdraw(address token, uint256 amount, address to) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "Transfer failed");
    }
}

