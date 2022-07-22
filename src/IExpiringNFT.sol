// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IMetadataService.sol";

uint32 constant CANNOT_BURN_BEFORE_EXPIRY = 1;
uint32 constant CANNOT_BURN_FUSES = 2;
uint32 constant CANNOT_TRANSFER = 4;
uint32 constant CANNOT_BURN_AFTER_EXPIRY = 8;
uint32 constant STAKE_TO_ROYALTY_RECIPIENT = 16;
uint32 constant NO_FUSES_SET = 0;

interface IExpiringNFT is IERC1155 {

    event FusesSet(uint256 indexed tokenId, uint32 fuses, uint64 expiry);

    function burn(uint256 tokenId) external;

    function metadataService() external view returns (IMetadataService);

    function setMetadataService(IMetadataService _newMetadataService) external;

    function isTokenOwnerOrApproved(uint256 tokenId, address addr)
        external
        returns (bool);
    
    function setFuses(uint256 tokenId, uint32 fuses)
        external
        returns (uint32);

    function allFusesBurned(uint256 tokenId, uint32 fuseMask)
        external
        view
        returns (bool);
}
