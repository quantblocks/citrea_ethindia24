// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IConfigurable {
    function setFee(uint256 _lpFeeBasisPoints, uint256 _protocolFeeBasisPoints) external;
    function setCollateralRatio(uint256 ratio) external;
}

contract Governance is Ownable {
    constructor() Ownable(msg.sender) {}
    function updateDEXFee(IConfigurable dex, uint256 newLpFee, uint256 newProtocolFee) external onlyOwner {
        dex.setFee(newLpFee, newProtocolFee);
    }

    function updateCollateralRatio(IConfigurable stableCoin, uint256 ratio) external onlyOwner {
        stableCoin.setCollateralRatio(ratio);
    }
}
