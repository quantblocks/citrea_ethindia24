// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBridge {
    function transferFromBitcoin(
        address to,
        uint256 amount,
        bytes calldata btcTxProof
    ) external returns (bool);

    function transferToBitcoin(
        bytes32 btcAddress,
        uint256 amount
    ) external returns (bool);
}
