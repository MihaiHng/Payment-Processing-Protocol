// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PlatformNFT
 * @author mhng
 * @notice Football Match Ticket NFT - MVP Demo
 * @dev Features:
 *      - 100 tickets minted at deployment to owner
 *      - Off-chain metadata (baseURI points to IPFS/server)
 *      - Owner approves Processor to transfer tickets on sale
 */
contract PlatformNFT is ERC721, Ownable {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Total number of tickets minted
    uint256 private _totalSupply;

    /// @dev Base URI for metadata (IPFS or HTTP)
    string private _baseTokenURI;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event TicketMinted(uint256 indexed tokenId, address indexed to);
    event BatchMinted(
        uint256 indexed startId,
        uint256 indexed endId,
        address indexed to
    );
    event BaseURIUpdated(string oldURI, string newURI);

    /*//////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error PlatformNFT__InvalidAddress();
    error PlatformNFT__TicketDoesNotExist();
    error PlatformNFT__InvalidAmount();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy and mint 100 tickets to owner
     * @param owner_ The platform owner who receives all tickets
     * @param baseURI_ Base URI for metadata (e.g., "ipfs://Qm.../")
     */
    constructor(
        address owner_,
        string memory baseURI_
    ) ERC721("Champions League Final 2026", "TICKET") Ownable(owner_) {
        if (owner_ == address(0)) revert PlatformNFT__InvalidAddress();

        _baseTokenURI = baseURI_;

        // Mint 100 tickets to owner
        _mintBatch(owner_, 100);
    }

    /*//////////////////////////////////////////////////////////////
                          MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a single ticket to owner
     * @return tokenId The minted token ID
     */
    function mint() external onlyOwner returns (uint256 tokenId) {
        tokenId = ++_totalSupply;
        _safeMint(msg.sender, tokenId);
        emit TicketMinted(tokenId, msg.sender);
    }

    /**
     * @notice Mint a single ticket to specific address
     * @param to Recipient address
     * @return tokenId The minted token ID
     */
    function mintTo(address to) external onlyOwner returns (uint256 tokenId) {
        if (to == address(0)) revert PlatformNFT__InvalidAddress();
        tokenId = ++_totalSupply;
        _safeMint(to, tokenId);
        emit TicketMinted(tokenId, to);
    }

    /**
     * @notice Mint batch of tickets to owner
     * @param amount Number of tickets to mint
     */
    function mintBatch(uint256 amount) external onlyOwner {
        if (amount == 0) revert PlatformNFT__InvalidAmount();
        _mintBatch(msg.sender, amount);
    }

    /**
     * @notice Mint batch of tickets to specific address
     * @param to Recipient address
     * @param amount Number of tickets to mint
     */
    // aderyn-ignore-next-line(centralization-risk)
    function mintBatchTo(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert PlatformNFT__InvalidAddress();
        if (amount == 0) revert PlatformNFT__InvalidAmount();
        _mintBatch(to, amount);
    }

    /**
     * @dev Internal batch mint function
     */
    function _mintBatch(address to, uint256 amount) internal {
        uint256 startId = _totalSupply + 1;

        for (uint256 i = 0; i < amount; ) {
            _safeMint(to, ++_totalSupply);
            unchecked {
                ++i;
            }
        }

        emit BatchMinted(startId, _totalSupply, to);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update base URI for metadata
     * @param newBaseURI New base URI
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        string memory oldURI = _baseTokenURI;
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(oldURI, newBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                          METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Base URI for computing tokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns metadata URI for a token
     * @dev Returns baseURI + tokenId (e.g., "ipfs://Qm.../42")
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0))
            revert PlatformNFT__TicketDoesNotExist();

        string memory base = _baseURI();
        return
            bytes(base).length > 0 // aderyn-ignore-next-line(abi-encode-packed-hash-collision)
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }
}
