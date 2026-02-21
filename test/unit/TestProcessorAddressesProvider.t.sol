// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {BaseTest} from "../BaseTest.t.sol";
import {ProcessorAddressesProvider} from "../../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {IProcessorAddressesProvider} from "../../src/interfaces/IProcessorAddressesProvider.sol";
import {Errors} from "../../src/libraries/helpers/Errors.sol";

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

    /*//////////////////////////////////////////////////////////////
                        SET STABLECOIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetStablecoin_UpdatesAddress() public asOwner {
        address newStablecoin = makeAddr("newStablecoin");

        addressesProvider.setStablecoin(newStablecoin);

        assertEq(addressesProvider.getStablecoin(), newStablecoin);
    }

    function test_SetStablecoin_EmitsEvent() public asOwner {
        address newStablecoin = makeAddr("newStablecoin");

        vm.expectEmit(true, true, false, false);
        emit StablecoinSet(address(usdc), newStablecoin);

        addressesProvider.setStablecoin(newStablecoin);
    }

    function test_SetStablecoin_RevertsIfZeroAddress() public asOwner {
        vm.expectRevert(Errors.PPP__InvalidStablecoin.selector);
        addressesProvider.setStablecoin(address(0));
    }

    function test_SetStablecoin_RevertsIfNotOwner() public asUnauthorized {
        vm.expectRevert();
        addressesProvider.setStablecoin(makeAddr("newStablecoin"));
    }

    /*//////////////////////////////////////////////////////////////
                        SET ADDRESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetAddress_SetsNewAddress() public asOwner {
        bytes32 id = keccak256("TEST_ID");
        address newAddress = makeAddr("testAddress");

        addressesProvider.setAddress(id, newAddress);

        assertEq(addressesProvider.getAddress(id), newAddress);
    }

    function test_SetAddress_EmitsEvent() public asOwner {
        bytes32 id = keccak256("TEST_ID");
        address newAddress = makeAddr("testAddress");

        vm.expectEmit(true, true, true, false);
        emit AddressSet(id, address(0), newAddress);

        addressesProvider.setAddress(id, newAddress);
    }

    function test_SetAddress_RevertsIfNotOwner() public asUnauthorized {
        bytes32 id = keccak256("TEST_ID");

        vm.expectRevert();
        addressesProvider.setAddress(id, makeAddr("testAddress"));
    }

    /*//////////////////////////////////////////////////////////////
                      GET ADDRESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetAddress_ReturnsZeroForUnknownId() public view {
        bytes32 unknownId = keccak256("UNKNOWN");
        assertEq(addressesProvider.getAddress(unknownId), address(0));
    }

    function test_GetProcessor_ReturnsProxyAddress() public view {
        assertEq(addressesProvider.getProcessor(), processorProxy);
    }

    function test_GetStablecoin_ReturnsUSDCAddress() public view {
        assertEq(addressesProvider.getStablecoin(), address(usdc));
    }
}
