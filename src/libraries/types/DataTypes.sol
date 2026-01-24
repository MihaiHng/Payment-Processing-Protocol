// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

library DataTypes {
    /**
     * This exists specifically to maintain the `getReserveData()` interface, since the new, internal
     * `ReserveData` struct includes the reserve's `virtualUnderlyingBalance`.
     */
    struct PaymentData {
        uint256 paymentId;
        address seller;
        address buyer;
        address item;
        uint256 price;
    }
}
