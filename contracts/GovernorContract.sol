// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.0/governance/Governor.sol";
import "@openzeppelin/contracts@4.9.0/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts@4.9.0/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts@4.9.0/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts@4.9.0/governance/TimelockController.sol";

contract GovernorContract is Governor, GovernorCountingSimple, GovernorTimelockControl, GovernorVotes {
    constructor(ERC20Votes _token, TimelockController _timelock)
        Governor("CitreaGovernor")
        GovernorVotes(_token)
        GovernorTimelockControl(_timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1; // blocks
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // about 1 week @15s/block
    }

    function quorum(uint256) public pure override returns (uint256) {
        return 100e18;
    }

    // Overriding multiple inheritance
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        string memory description
    )
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal 
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }
}
