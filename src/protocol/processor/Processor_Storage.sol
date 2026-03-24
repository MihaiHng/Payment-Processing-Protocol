// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Processor_Storage
 * @notice Storage layout for the Processor
 * @dev Variables live in PROXY storage, persist across upgrades
 *
 * ⚠️ UPGRADE SAFETY:
 * - Only ADD new variables at the END
 * - Never remove or reorder variables
 * - Never change variable types
 */
abstract contract Processor_Storage {
    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The stablecoin used by this processor (USDC, USDT, DAI, etc.)
    IERC20 public stablecoin;

    /// @notice Total balance tracked by the processor
    uint256 public totalBalance;

    // Mapping to track deployer/owner deposits
    mapping(address => uint256) public totalFunded;

    /// @dev The seller's wallet address (receives USDC payments)
    address public seller;

    /// @dev The NFT contract address (tickets to be transferred)
    IERC721 public nftContract;

    /// @dev Payment ID => processed status (prevents double processing)
    mapping(bytes32 => bool) public processedPayments;
}
