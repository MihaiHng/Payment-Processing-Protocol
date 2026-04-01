// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../../interfaces/IProcessor.sol";
import {Errors} from "../helpers/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *
 */
library ProcessingPaymentLogic {
    using SafeERC20 for IERC20;

    /**
     * @notice Settles a FIAT payment using a stablecoin on the blockchain
     * @param addressesProvider The address of the ProcessorAddressesProvider used
     * @param processedPayments Mapping that tracks processes and unprocessed payment Ids
     * @param stablecoin The address of the used stablecoin
     * @param currentBalance The stablecoin total balance of the contract
     * @param params Struct from DataTypes with the important parameters for a payment processing operation
     * @dev Performs several operations:
     *      - Safety checks
     *      - Updates contract balance and paymentId to processed
     *      - Sends the required amount to the seller
     *      - Sends the token to the buyer
     *@return newBalance Updated balance after payment
     */
    function executeProcessingPayment(
        IProcessorAddressesProvider addressesProvider,
        mapping(bytes32 => bool) storage processedPayments,
        IERC20 stablecoin,
        uint256 currentBalance,
        DataTypes.PaymentData memory params
    ) external returns (uint256 newBalance) {
        // Read configuration from provider
        // aderyn-fp-next-line(reentrancy-state-change)
        DataTypes.SellerConfiguration memory config = addressesProvider
            .getConfiguration();

        address seller = config.seller;
        address nftContract = config.nftContract;

        bytes32 paymentId = params.paymentId;
        address buyer = params.buyer;
        uint256 tokenId = params.tokenId;
        uint256 amount = params.amount;

        // Validations
        if (address(stablecoin) == address(0)) {
            revert Errors.PPP__StablecoinNotSet();
        }
        if (seller == address(0)) {
            revert Errors.PPP__SellerNotSet();
        }
        if (nftContract == address(0)) {
            revert Errors.PPP__NFTContractNotSet();
        }
        if (buyer == address(0)) {
            revert Errors.PPP__InvalidBuyer();
        }
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }
        if (processedPayments[paymentId]) {
            revert Errors.PPP__PaymentAlreadyProcessed();
        }
        if (currentBalance < amount) {
            revert Errors.PPP__InsufficientBalance();
        }

        // CEI Pattern: Mark as processed BEFORE external calls
        processedPayments[paymentId] = true;
        newBalance = currentBalance - amount;

        // Transfer USDC to seller
        stablecoin.safeTransfer(seller, amount);

        // Transfer NFT to buyer
        // NOTE: Seller must have called nftContract.setApprovalForAll(processor, true)
        IERC721(nftContract).transferFrom(seller, buyer, tokenId);

        emit IProcessor.PaymentProcessed(
            paymentId,
            buyer,
            tokenId,
            amount,
            seller
        );

        return newBalance;
    }
}
