// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITimelockController.sol";

contract TimelockController is AccessControl, ITimelockController {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    uint256 public delay;
    struct Operation {
        bool queued;
        uint256 eta;
    }
    mapping(bytes32 => Operation) public operations;

    constructor(uint256 _delay, address[] memory proposers, address[] memory executors) {
        delay = _delay;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint i=0; i<proposers.length; i++) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }
        for (uint i=0; i<executors.length; i++) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }
    }

    function schedule(address target, uint256 value, string calldata signature, bytes calldata data, bytes32 salt) external override onlyRole(PROPOSER_ROLE) {
        bytes32 id = keccak256(abi.encode(target, value, signature, data, salt));
        require(!operations[id].queued, "Operation already queued");
        operations[id] = Operation({
            queued: true,
            eta: block.timestamp + delay
        });
    }

    function execute(address target, uint256 value, string calldata signature, bytes calldata data, bytes32 salt) external override onlyRole(EXECUTOR_ROLE) payable {
        bytes32 id = keccak256(abi.encode(target, value, signature, data, salt));
        require(operations[id].queued, "Not queued");
        require(block.timestamp >= operations[id].eta, "Not ready");
        operations[id].queued = false;
        (bool success,) = target.call{value:value}(abi.encodeWithSignature(signature, data));
        require(success, "Execution failed");
    }
}
