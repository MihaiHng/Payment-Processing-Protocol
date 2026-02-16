// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {IProcessor} from "../../interfaces/IProcessor.sol";
import {Errors} from "../helpers/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *
 */
library FundProcessorLogic {
    using SafeERC20 for IERC20;

    /**
     * @notice Handles the funding of the processor with USDC
     * @param stablecoin The stablecoin address (USDC, USDT, DAI, etc.)
     * @param amount The amount to deposit
     * @param currentBalance The current USDC balance of the Processor
     * @dev msg.sender is always the depositor
     */
    function executeFundProcessor(
        IERC20 stablecoin,
        uint256 amount,
        uint256 currentBalance
    ) external returns (uint256) {
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }

        currentBalance += amount;
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        emit IProcessor.ProcessorFunded(msg.sender, amount, currentBalance);

        return currentBalance;
    }
}
