// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITimelockController {
    function schedule(address target, uint256 value, string calldata signature, bytes calldata data, bytes32 salt) external;
    function execute(address target, uint256 value, string calldata signature, bytes calldata data, bytes32 salt) external payable;
}
