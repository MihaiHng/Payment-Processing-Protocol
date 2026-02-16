// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
}
