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

contract Processor_Storage {
    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 public immutable usdc;

    uint256 public totalBalance;

    // Mapping to track deployer/owner deposits
    mapping(address => uint256) public totalFunded;
}
