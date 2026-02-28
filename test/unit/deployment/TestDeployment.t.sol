// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Test, console, console2} from "forge-std/Test.sol";
import {BaseTest} from "../../BaseTest.t.sol";
import {ProcessorAddressesProvider} from "../../../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {ProcessorInstance} from "../../../src/instances/ProcessorInstance.sol";
import {MockProcessorInstanceV2} from "../../mocks/MockProcessorInstanceV2.sol";
import {IProcessorAddressesProvider} from "../../../src/interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../../../src/interfaces/IProcessor.sol";
import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestProcessorAddressesProvider is BaseTest {
    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    // Using BaseTest setUp()

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Deployment_Sets_Owner() public view {
        assertEq(addressesProvider.owner(), owner);
    }

    function test_Deployment_Sets_Stablecoin() public view {
        assertEq(addressesProvider.getStablecoin(), address(usdc));
    }

    function test_Deployment_CreatesProxy() public view {
        assertTrue(processorProxy != address(0), "Proxy not created");
    }

    function test_Deployment_ProcessorMatchesProxy() public view {
        assertEq(addressesProvider.getProcessor(), processorProxy);
    }
}
