// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

/**
 * @title Errors library
 * @author mhng
 * @notice Defines different error messages emitted by the contracts of the protocol
 */
library Errors {
    error PPP__InvalidAddress();
    error PPP__InvalidAmount();
    error PPP__NothingToWithdraw();
    // error PPP__InvalidUser();
    error PPP__CallerNotProcessor();
    error PPP__InsufficientBalance();
    error PPP_InvalidAddressesProvider();
    error PPP_InvalidStablecoin();
    error PPP_StablecoinNotSet();
}
