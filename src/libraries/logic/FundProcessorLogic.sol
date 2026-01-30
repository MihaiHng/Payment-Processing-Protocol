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
     * @param usdc The USDC token contract
     * @param user The user depositing funds
     * @param deposits Mapping that tracks user deposits
     * @param amount The amount to deposit
     */
    function executeFundProcessor(
        IERC20 usdc,
        address user,
        mapping(address => uint256) storage deposits,
        uint256 amount
    ) external {
        if (amount == 0) {
            revert Errors.PPP__InvalidAmount();
        }

        if (user == address(0)) {
            revert Errors.PPP__InvalidUser();
        }

        usdc.safeTransferFrom(user, address(this), amount);
        deposits[user] += amount;

        emit IProcessor.ProcessorFunded(user, amount);
    }
}
