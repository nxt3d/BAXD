// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IMetadataService.sol";
import "./Controllable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC2981Data.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC1155Expiry.sol";
import "./IExpiringNFT.sol";

error InsufficientFunds();
error Unauthorised(uint256 tokenId, address addr);
error CannotBurnToken(uint256 tokenId);
error IncorrectFee();

contract ExpiringNFT is
    IExpiringNFT,
    Ownable,
    Controllable,
    ERC1155Expiry,
    ERC2981Data
{

    IMetadataService public override metadataService;

    constructor( IMetadataService _metadataService){
        metadataService = _metadataService;
    }

    /**
     * @notice Burn the token and return. Only owners can do this. 
     * @param tokenId TokenId of the token to burn
     */

    function burn(uint256 tokenId) public virtual {
        if(!isTokenOwnerOrApproved(tokenId, msg.sender)){
            revert Unauthorised(tokenId, msg.sender);
        }

        if(!_canBurnToken(tokenId)){
            revert CannotBurnToken(tokenId);
        }
        
        _burn(tokenId);
    }

    /**
     * @notice Get the metadata uri
     * @return String uri of the metadata service
     */

    function uri(uint256 tokenId) public view override returns (string memory) {
        return metadataService.uri(tokenId);
    }

    /* Metadata service */

    /**
     * @notice Set the metadata service. Only the owner can do this
     */

    function setMetadataService(IMetadataService _newMetadataService)
        public
        onlyOwner
    {
        metadataService = _newMetadataService;
    }

    /**
     * @notice Checks if owner or approved by owner
     * @param tokenId tokenId of the token to check
     * @param addr which address to check permissions for
     * @return whether or not is owner or approved
     */

    function isTokenOwnerOrApproved(uint256 tokenId, address addr)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return owner == addr || isApprovedForAll(owner, addr);
    } 

    /**
     * @notice Sets fuses of a token
     * @param tokenId Token id of the token
     * @param fuses fuses to burn
     */

    function setFuses(uint256 tokenId, uint32 fuses)
        public
        onlyTokenOwner(tokenId)
        operationAllowed(tokenId, CANNOT_BURN_FUSES)
        returns (uint32)
    {

        (address owner, uint32 oldFuses, uint64 expiry) = getData(
            tokenId
        );

        fuses |= oldFuses;
        _setFuses(tokenId, owner, fuses, expiry);
        return fuses;
    }


    /**
     * @notice Checks all Fuses in the mask are burned for the tokenId
     * @param tokenId TokenId of the name
     * @param fuseMask the fuses you want to check
     * @return Boolean of whether or not all the selected fuses are burned
     */

    function allFusesBurned(uint256 tokenId, uint32 fuseMask)
        public
        view
        override
        returns (bool)
    {
        (, uint32 fuses, ) = getData(tokenId);
        return fuses & fuseMask == fuseMask;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Expiry, ERC2981Data, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IExpiringNFT).interfaceId ||
            ERC1155Expiry.supportsInterface(interfaceId) ||
            ERC2981Data.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows an operation only if none of the specified fuses are burned.
     * @param tokenId The id of the token to check fuses on.
     * @param fuseMask A bitmask of fuses that must not be burned.
     */

    modifier operationAllowed(uint256 tokenId, uint32 fuseMask) {
        (, uint32 fuses, ) = getData(tokenId);
        if (fuses & fuseMask != 0) {
            revert OperationProhibited(tokenId);
        }
        _;
    }

    /**
     * @notice Checks if msg.sender is the owner or approved by the owner of a name
     * @param tokenId Id of the token to check
     */

    modifier onlyTokenOwner(uint256 tokenId) {
        if (!isTokenOwnerOrApproved(tokenId, msg.sender)) {
            revert Unauthorised(tokenId, msg.sender);
        }

        _;
    }
    /***** Internal functions */

    function _setFuses(
        uint256 tokenId,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal {
        _setData(tokenId, owner, fuses, expiry);
        emit FusesSet(tokenId, fuses, expiry);
    }

    function _canTransfer(uint32 fuses) internal pure override returns (bool) {
        return fuses & CANNOT_TRANSFER == 0;
    }    

    
    function _canBurnToken(uint256 tokenId) internal view returns (bool) {

        (, uint32 fuses, uint64 expiry) = getData(tokenId);
        
        bool canBurnToken = true;

        if (fuses & CANNOT_BURN_BEFORE_EXPIRY != 0 && block.timestamp < expiry){
            canBurnToken = false;
        }
        
        if (fuses & CANNOT_BURN_AFTER_EXPIRY != 0 && block.timestamp >= expiry){
            canBurnToken = false;
        }

        return canBurnToken;
    }

}