// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Processor} from "../src/protocol/Processor.sol";

contract DeployProcessor is Script {
    Processor public processor;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        processor = new Processor();

        vm.stopBroadcast();
    }
}
