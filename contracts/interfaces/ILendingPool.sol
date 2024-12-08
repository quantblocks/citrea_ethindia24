// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ILendingPool {
    function borrow(address borrower, uint256 amount) external;
    function repay(address borrower, uint256 amount) external;
    function checkHealth(address user) external view returns (uint256);
    function liquidateBorrower(address borrower) external;
}
