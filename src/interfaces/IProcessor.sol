// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

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
    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        address seller
    );

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
    // function extractPaymentData()
    //     external
    //     returns (DataTypes.PaymentData memory paymentData);

    /**
     * @notice Process a confirmed fiat payment
     * @dev Transfers USDC to seller and NFT to buyer atomically
     * @param paymentId Unique payment identifier
     * @param buyer The address of the buyer
     * @param tokenId The address of the digital item
     * @param amount The stablecoin amount to transfer to seller
     * @return Returns confirmation of payment processing success
     */
    function processPayment(
        bytes32 paymentId,
        address buyer,
        uint256 tokenId,
        uint256 amount
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

    /**
     * @notice Get the seller address (from AddressesProvider)
     */
    function getSeller() external view returns (address);

    /**
     * @notice Get the NFT contract address (from AddressesProvider)
     */
    function getNftContract() external view returns (address);

    /**
     * @notice Check if a payment has been processed
     */
    function isPaymentProcessed(bytes32 paymentId) external view returns (bool);
}
