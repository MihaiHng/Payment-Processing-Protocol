// script/FundProcessor.s.sol

/**
PROCESSOR_PROXY=0x... \
STABLECOIN=0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d \
AMOUNT=20000000 \
 */

// ========================================================================================================================
// RUN THIS TO FUND THE PROCESSOR!
// forge script script/FundProcessor.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --account deployer --broadcast
// ========================================================================================================================

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProcessor} from "../src/interfaces/IProcessor.sol";

contract FundProcessor is Script {
    function run() external {
        address processorProxy = vm.envAddress("PROCESSOR_PROXY");
        address stablecoin = vm.envAddress("STABLECOIN");
        uint256 amount = vm.envOr("AMOUNT", uint256(20e6));

        console.log("Processor:", processorProxy);
        console.log("Stablecoin:", stablecoin);
        console.log("Amount:", amount);

        vm.startBroadcast();

        // Approve
        IERC20(stablecoin).approve(processorProxy, amount);
        console.log("1. Approved USDC spending");

        // Fund
        IProcessor(processorProxy).fundProcessor(amount);
        console.log("2. Funded processor");

        vm.stopBroadcast();

        console.log("\n Processor funded with:", amount / 1e6, "USDC");
    }
}
