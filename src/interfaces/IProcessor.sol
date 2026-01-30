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

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IProcessor
 * @author mhng
 * @notice Defines the basic interface for a Processor Smart Contract.
 */
interface IProcessor {
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProcessorFunded(address user, uint256 amount);
    event ProcessorWithdraw(address user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** */
    function fundProcessor(uint256 amount) external;

    /** */
    function withdrawFromProcessor(uint256 amount) external;

    /**
     *
     */
    function extractPaymentProcessingData()
        external
        returns (DataTypes.PaymentData memory paymentData);

    /**
     * @notice Handles the logic associated with the on-chain transactions, transfer price amount to seller, transfer item to buyer, confirmations
     * @param paymentId The Id of the payment
     * @param seller The address of the seller
     * @param buyer The address of the buyer
     * @param item The address. of the digital item
     * @param price The price to be paid in name of the buyer
     * @return Returns confirmation of payment processing success or failure
     */
    function processPayment(
        uint256 paymentId,
        address seller,
        uint256 buyer,
        address item,
        uint256 price
    ) external returns (bool);
}
