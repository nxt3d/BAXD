// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint32 constant CANNOT_UPDATE_LABEL = 32;

interface IBAXD20 {

    event BAXD20Minted(uint256 indexed tokenId);
        
    function labels(uint256) external view returns (string memory);

    function tokenAddress() external view returns (IERC20);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 _mintFee) external;

    function setLabel(uint256 tokenId, string calldata label) external;

    function mint(        
        string memory label,
        address owner,
        uint96 royalty,
        address royaltyOwner
        )
        external
        payable;

    function upgrade( uint256 tokenId) external;
}
