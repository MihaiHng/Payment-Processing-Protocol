// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {IProcessor} from "../../interfaces/IProcessor.sol";
import {Errors} from "../helpers/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *
 */
library WithdrawProcessorLogic {
    using SafeERC20 for IERC20;

    /**
     * @notice Handles the funding of the processor with USDC
     * @param usdc The USDC token contract
     * @param deposits Mapping that tracks user deposits
     * @param amount The amount to deposit
     * @dev msg.sender is always the depositor
     */
    function executeWithdrawProcessor(
        IERC20 usdc,
        mapping(address => uint256) storage deposits,
        uint256 amount
    ) external {
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }

        address user = msg.sender;
        if (user == address(0)) {
            revert Errors.PPP__InvalidUser();
        }

        deposits[user] += amount;
        usdc.safeTransferFrom(user, address(this), amount);

        emit IProcessor.ProcessorFunded(user, amount);
    }
}
