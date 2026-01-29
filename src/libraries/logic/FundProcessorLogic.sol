// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Processor_Storage} from "../../protocol/Processor_Storage.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 *
 */
library FundProcessorLogic {
    function executeFundProcessor(
        mapping(address => uint256) storage deposits,
        uint256 amount
    ) external {
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }

        usdc.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;

        //emit Deposit(msg.sender, amount);
    }
}
