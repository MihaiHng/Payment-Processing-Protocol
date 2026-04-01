// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";

/**
 * @title DataTypes
 * @author mhng
 * @notice Library containing data structures for the Payment Processor Protocol
 */

library DataTypes {
    /**
     * @notice Seller platform configuration
     * @param seller The seller's wallet address (receives stablecoin payments)
     * @param nftContract The NFT contract address (items to be transferred)
     * @param stablecoin The stablecoin address for payments (USDC, USDT, etc.)
     */
    struct SellerConfiguration {
        address seller;
        address nftContract;
        address stablecoin;
    }

    /**
     * @notice Payment information for processing
     * @param paymentId Unique payment identifier
     * @param buyer Buyer's wallet address
     * @param tokenId NFT token ID to transfer
     * @param amount Payment amount in stablecoin
     */
    struct PaymentData {
        bytes32 paymentId;
        address buyer;
        uint256 tokenId;
        uint256 amount;
    }
}
