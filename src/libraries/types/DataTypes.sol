// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

library DataTypes {
    /**
     *
     */
    struct PaymentData {
        uint256 paymentId;
        address seller;
        address buyer;
        address item;
        uint256 price;
    }
}
