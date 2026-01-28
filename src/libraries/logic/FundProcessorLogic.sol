// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

/**
 *
 */
library FundProcessorLogic {
    function executeFundProcessor(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }
}
