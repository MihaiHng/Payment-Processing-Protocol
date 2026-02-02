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
     * @notice Handles withdrawing an amount of USDC from the processor
     * @param usdc The USDC token contract
     * @param amount The amount to withdraw
     * @param currentBalance The current USDC balance of the Processor
     
     * @dev msg.sender is always the address that executes the withdraw
     */
    function executeWithdrawFromProcessor(
        IERC20 usdc,
        uint256 amount,
        uint256 currentBalance
    ) public returns (uint256) {
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }

        if (amount > currentBalance) {
            revert Errors.PPP__InsufficientBalance();
        }

        currentBalance -= amount;

        usdc.safeTransfer(msg.sender, amount);

        emit IProcessor.ProcessorWithdraw(msg.sender, amount, currentBalance);

        return currentBalance;
    }

    /**
     * @notice Handles withdrawing the total balance of USDC from the processor
     * @param usdc The USDC token contract
     * @param currentBalance The current USDC balance of the Processor
     * @dev msg.sender is always the address that executes the withdraw
     */
    function executeWithdrawAllFromProcessor(
        IERC20 usdc,
        uint256 currentBalance
    ) external {
        uint256 totalWithdraw = usdc.balanceOf(address(this));

        if (totalWithdraw == 0) {
            revert Errors.PPP__NothingToWithdraw();
        }

        executeWithdrawFromProcessor(usdc, totalWithdraw, currentBalance);

        emit IProcessor.ProcessorWithdrawAll(msg.sender, totalWithdraw);
    }
}
