// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Processor} from "../src/protocol/Processor.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProcessor is Script {
    Processor public processor;
    IERC20 usdc;

    uint256 private constant initalAmount = 1000e6;

    /**
     * # 1. Approve USDC to contract (needs to happen before or during deploy)
     * # 2. Deploy contract with constructor args
     * # 3. Contract receives initial funding via transferFrom
     * # 4. User can call fundSmartContract() for additional funding
     */

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        //processor = new Processor(usdc, initalAmount);

        vm.stopBroadcast();
    }
}
