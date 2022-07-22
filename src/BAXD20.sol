// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExpiringNFT.sol";
import "./Upgradable.sol";
import "./IBAXD20.sol";
import "./IBAXD20Upgrade.sol";


contract BAXD20 is 
    Ownable,
    ExpiringNFT, 
    Upgradable,
    IBAXD20 
{

    using SafeERC20 for IERC20;

    using Counters for Counters.Counter;
    Counters.Counter private nonce;

    //The address of the token used for staking
    IERC20 public tokenAddress;

    //The fee for minting tokens
    uint256 public mintFee;

    //The stake is 20 ERC20 tokens with 18 digits of precision
    uint256 private constant erc20precision = 10 ** 18;
    uint256 private constant stake = 20 * erc20precision;
    
    mapping(uint256 => string) public labels;

    constructor(
        IERC20 _tokenAdd,
        IMetadataService _metadataService 
    ) 
        ExpiringNFT(_metadataService) 
    {

        tokenAddress = _tokenAdd;
    }

    function setMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }
    
    function setLabel(uint256 tokenId, string calldata label) 
        public
        onlyTokenOwner(tokenId)
        operationAllowed(tokenId, CANNOT_UPDATE_LABEL)

    {

        labels[tokenId] = label; 

    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IBAXD20).interfaceId ||
            super.supportsInterface(interfaceId); 
    }

    function mint(        
        string memory label,
        address owner,
        uint96 royalty,
        address royaltyOwner
        )
        public
        payable
        {

        if (tokenAddress.balanceOf(msg.sender) < stake) {
            revert InsufficientFunds();
        }

        if (msg.value != mintFee ){
            revert IncorrectFee();
        }

        tokenAddress.safeTransferFrom(msg.sender, address(this), stake);

        //Create a labelhash using the label, a nonce, the address of this contract and the chain id.
        //This ensures that the chance of collision, even when migrating tokens across chains. 
        nonce.increment();
        uint256 tokenId = uint256(keccak256(abi.encode(nonce.current(), address(this), block.chainid)));
        labels[tokenId] = label;

        _mint( tokenId, owner, CANNOT_BURN_FUSES, 0);
        _setTokenRoyalty(tokenId, royaltyOwner, royalty);

        emit BAXD20Minted(tokenId);
    }
    
    /**
     * @notice Burn the token and return the stake. Only owners can do this. 
     * @param tokenId TokenId of the token to burn
     */

    function burn(uint256 tokenId) public override {
        if(!isTokenOwnerOrApproved(tokenId, msg.sender)){
            revert Unauthorised(tokenId, msg.sender);
        }
        if(!_canBurnToken(tokenId)){
            revert CannotBurnToken(tokenId);
        }

        ( , uint32 fuses, ) = getData(
            uint256(tokenId)
        );

        if (_stakeToRoyaltyRecipient(fuses)){

            (address receiver, ) = royaltyData(tokenId);

            _burn(tokenId);
            tokenAddress.safeTransfer( receiver, stake);

        } else { 
            //Sould the money be sent to the owner or msg.sender? 
            _burn(tokenId);
            tokenAddress.safeTransfer( msg.sender, stake);
        }
        
    }

    function approveUpgradeContract(uint256 value) public onlyOwner {

        tokenAddress.safeApprove(upgradeContract, value);
    }

    /**
     * @notice Upgrades a token to a new contract.
     * @dev Can be called by the owner or an authorised caller
     * @param tokenId Id of the token
     */

    function upgrade(
        uint256 tokenId
    ) public {

        if (upgradeContract == address(0)) {
            revert CannotUpgrade();
        }

        if (!isTokenOwnerOrApproved(tokenId, msg.sender)) {
            revert Unauthorised(tokenId, msg.sender);
        }

        (address owner, uint32 fuses, uint64 expiry) = getData(tokenId);
        (address royaltyOwner, uint96 royalty) = royaltyData(tokenId);

        // burn token and fuse data
        burn(tokenId);
        IBAXD20Upgrade(upgradeContract).upgradeMint(        
            labels[tokenId],
            owner,
            fuses,
            expiry, 
            royaltyOwner,
            royalty
        );
        // transfer the stake to the upgrade contrat 
        tokenAddress.safeTransfer(upgradeContract, stake);
    }

    function _stakeToRoyaltyRecipient(uint32 fuses) internal pure returns (bool) {
        return fuses & STAKE_TO_ROYALTY_RECIPIENT != 0;
    }    
}