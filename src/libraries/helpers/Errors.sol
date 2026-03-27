// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

/**
 * @title Errors library
 * @author mhng
 * @notice Defines different error messages emitted by the contracts of the protocol
 */
library Errors {
    /*//////////////////////////////////////////////////////////////
                        ADDRESSES PROVIDER ERRORS
    //////////////////////////////////////////////////////////////*/

    error PPP__InvalidAddressesProvider();

    /*//////////////////////////////////////////////////////////////
                          PROCESSOR ERRORS
    //////////////////////////////////////////////////////////////*/

    error PPP__NothingToWithdraw();
    error PPP__InsufficientBalance();
    error PPP__TransferFailed();
    error PPP__ZeroAmount();

    /*//////////////////////////////////////////////////////////////
                        MARKETPLACE ERRORS
    //////////////////////////////////////////////////////////////*/

    error PPP__StablecoinNotSet();
    error PPP__SellerNotSet();
    error PPP__NFTContractNotSet();
    error PPP__InvalidStablecoin();
    error PPP__InvalidSeller();
    error PPP__InvalidNFTContract();
    error PPP__InvalidBuyer();
    error PPP__InvalidAmount();
    error PPP__PaymentAlreadyProcessed();
}
