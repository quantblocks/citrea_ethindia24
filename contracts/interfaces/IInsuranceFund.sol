// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IInsuranceFund {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount, address to) external;
}
