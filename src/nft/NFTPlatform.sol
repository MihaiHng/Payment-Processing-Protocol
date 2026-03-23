// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PlatformNFT
 * @notice Simple NFT contract for e-commerce platform inventory
 * @dev Owner mints NFTs, approves Processor to transfer on sales
 */
contract PlatformNFT is ERC721, Ownable {
    string private _baseTokenURI;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner_
    ) ERC721(name_, symbol_) Ownable(owner_) {
        _baseTokenURI = baseURI_;
    }

    /// @notice Owner mints NFT to themselves (inventory)
    function mint(uint256 tokenId) external onlyOwner {
        _safeMint(msg.sender, tokenId);
        _totalSupply++;
    }

    /// @notice Owner mints batch of NFTs
    function mintBatch(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
        _totalSupply += tokenIds.length;
    }

    /// @notice Update base URI
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
