// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ILightClient {
    function getLatestBlockHeight() external view returns (uint256);
    function verifyTransaction(bytes calldata proof) external view returns (bool);
}
