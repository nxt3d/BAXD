//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBAXD20Upgrade {
    function upgradeMint(
        string calldata label,
        address owner,
        uint32 fuses,
        uint64 expiry,
        address royaltyOwner,
        uint96 royalty
        
    ) external;
}
