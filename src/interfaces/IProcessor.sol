// SPDX-License-Identifier: MIT

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

    event ProcessorFunded(
        address user,
        uint256 indexed amount,
        uint256 indexed totalBalance
    );
    event ProcessorWithdraw(
        address user,
        uint256 indexed amount,
        uint256 indexed totalBalance
    );
    event ProcessorWithdrawAll(address user, uint256 indexed totalWithdraw);

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the owner to fund the Payment Processor with stablecoins (i.e. USDC)
     * @param amount The amount of USDC deposited
     */
    function fundProcessor(uint256 amount) external;

    /**
     * @notice Allows the owner to withdraw from the Payment Processor an amount
     * @param amount The amount of USDC to withdraw
     */
    function withdrawFromProcessor(uint256 amount) external;

    /**
     * @notice Allows the owner to withdraw from the Payment Processor all the balance
     */
    function withdrawAllFromProcessor() external;

    /**
     *
     */
    function extractPaymentData()
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

    /*//////////////////////////////////////////////////////////////
                        GETTER/VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Get the current stablecoin balance of the processor
     * @return The stablecoin balance of the Processor as stored in a state variable
     */
    function getBalance() external view returns (uint256);

    /**
     * @notice Get the actual stablecoin balance in the contract (for verification)
     * @return The stablecoin balance of the Processor returned by balanceOf()
     */
    function getActualBalance() external view returns (uint256);

    /**
     * @notice Get the stablecoin address used by the Processor
     * @return The address of the stablecoin used by the Processor
     */
    function getStablecoin() external view returns (address);
}
