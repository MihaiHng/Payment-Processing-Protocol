// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Processor_Storage} from "../../protocol/Processor_Storage.sol";

/**
 *
 */
library FundProcessorLogic {
    error PPP__InvalidAmount();

    function executeFundProcessor(uint256 amount) external {
        if (amount == 0) {
            revert PPP__InvalidAmount();
        }
        //require(amount > 0, "Amount must be > 0");
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        //emit Deposit(msg.sender, amount);
    }
}
