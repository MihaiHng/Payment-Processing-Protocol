// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Test, console, console2} from "forge-std/Test.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {ProcessorAddressesProvider} from "../../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {ProcessorInstance} from "../../src/instances/ProcessorInstance.sol";
import {MockProcessorInstanceV2} from "../mocks/MockProcessorInstanceV2.sol";
import {IProcessorAddressesProvider} from "../../src/interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../../src/interfaces/IProcessor.sol";
import {Errors} from "../../src/libraries/helpers/Errors.sol";
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

    /*//////////////////////////////////////////////////////////////
                    SET ADDRESS AS PROXY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetAddressAsProxy_CreatesNewProxy() public asOwner {
        bytes32 testId = keccak256("TEST_MODULE");

        // Deploy a mock implementation (using ProcessorInstance for simplicity)
        ProcessorInstance mockImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        // Set as proxy
        addressesProvider.setAddressAsProxy(testId, address(mockImpl));

        // Verify proxy was created
        address proxyAddress = addressesProvider.getAddress(testId);
        assertTrue(proxyAddress != address(0), "Proxy not created");
        assertTrue(
            proxyAddress != address(mockImpl),
            "Should be proxy, not implementation"
        );
    }

    function test_SetAddressAsProxy_EmitsEvent() public asOwner {
        bytes32 testId = keccak256("TEST_MODULE");

        ProcessorInstance mockImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        vm.expectEmit(true, false, false, false);
        emit AddressSetAsProxy(
            testId,
            address(0), // proxy address (unknown)
            address(0), // old impl (none)
            address(mockImpl)
        );

        addressesProvider.setAddressAsProxy(testId, address(mockImpl));
    }

    function test_SetAddressAsProxy_UpgradesExistingProxy() public asOwner {
        bytes32 testId = keccak256("TEST_MODULE");

        // Create first proxy
        ProcessorInstance impl1 = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );
        addressesProvider.setAddressAsProxy(testId, address(impl1));

        address proxyAddress = addressesProvider.getAddress(testId);

        // Upgrade to new implementation
        MockProcessorInstanceV2 impl2 = new MockProcessorInstanceV2(
            IProcessorAddressesProvider(address(addressesProvider))
        );
        addressesProvider.setAddressAsProxy(testId, address(impl2));

        // Proxy address should remain the same
        assertEq(addressesProvider.getAddress(testId), proxyAddress);
    }

    function test_SetAddressAsProxy_RevertsIfStablecoinNotSet() public {
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        // NOT setting stablecoin

        ProcessorInstance mockImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        bytes32 testId = keccak256("TEST_MODULE");

        vm.expectRevert(Errors.PPP__StablecoinNotSet.selector);
        freshProvider.setAddressAsProxy(testId, address(mockImpl));
        vm.stopPrank();
    }

    function test_SetAddressAsProxy_RevertsIfNotOwner() public {
        bytes32 testId = keccak256("TEST_MODULE");

        ProcessorInstance mockImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        vm.prank(unauthorized);
        vm.expectRevert();
        addressesProvider.setAddressAsProxy(testId, address(mockImpl));
    }

    /*//////////////////////////////////////////////////////////////
                      SET PROCESSOR IMPL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetProcessorImpl_CreatesProxy() public {
        // Deploy fresh provider without proxy
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        freshProvider.setStablecoin(address(usdc));

        // Verify no proxy exists yet
        assertEq(freshProvider.getProcessor(), address(0));

        // Deploy implementation
        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        // Set implementation - should create proxy
        freshProvider.setProcessorImpl(address(newImpl));

        // Verify proxy was created
        assertTrue(
            freshProvider.getProcessor() != address(0),
            "Proxy not created"
        );
        vm.stopPrank();
    }

    function test_SetProcessorImpl_EmitsProxyCreatedEvent() public {
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        freshProvider.setStablecoin(address(usdc));

        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        // Expect ProxyCreated event
        vm.expectEmit(true, false, true, false);
        emit ProxyCreated(
            bytes32("PROCESSOR"),
            address(0), // We don't know proxy address yet
            address(newImpl)
        );

        freshProvider.setProcessorImpl(address(newImpl));
        vm.stopPrank();
    }

    function test_SetProcessorImpl_EmitsProcessorUpdatedEvent() public {
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        freshProvider.setStablecoin(address(usdc));

        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        vm.expectEmit(true, true, false, false);
        emit ProcessorUpdated(address(0), address(newImpl));

        freshProvider.setProcessorImpl(address(newImpl));
        vm.stopPrank();
    }

    function test_SetProcessorImpl_InitializesProcessor() public {
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        freshProvider.setStablecoin(address(usdc));

        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        freshProvider.setProcessorImpl(address(newImpl));

        // Verify processor is initialized with correct stablecoin
        address proxyAddress = freshProvider.getProcessor();
        IProcessor proxy = IProcessor(proxyAddress);

        assertEq(proxy.getStablecoin(), address(usdc));
        vm.stopPrank();
    }

    function test_SetProcessorImpl_RevertsIfStablecoinNotSet() public {
        vm.startPrank(owner);
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        // NOT setting stablecoin

        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );

        vm.expectRevert(Errors.PPP__StablecoinNotSet.selector);
        freshProvider.setProcessorImpl(address(newImpl));
        vm.stopPrank();
    }

    function test_SetProcessorImpl_RevertsIfNotOwner() public {
        ProcessorInstance newImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        vm.prank(unauthorized);
        vm.expectRevert();
        addressesProvider.setProcessorImpl(address(newImpl));
    }

    /*//////////////////////////////////////////////////////////////
                      UPGRADE PROCESSOR TESTS
    //////////////////////////////////////////////////////////////*/
    // function test_SetProcessorImpl_RevertsIfSameRevision() public asOwner {
    //     // Get initial state
    //     address proxyBefore = addressesProvider.getProcessor();

    //     // Try to "upgrade" with same V1 revision
    //     ProcessorInstance sameRevisionImpl = new ProcessorInstance(
    //         IProcessorAddressesProvider(address(addressesProvider))
    //     );

    //     // Should revert because revision 1 is not > 1
    //     // Note: Revert data is lost when bubbled through proxy
    //     vm.expectRevert();
    //     addressesProvider.setProcessorImpl(address(sameRevisionImpl));

    //     // Verify proxy unchanged (upgrade failed)
    //     assertEq(addressesProvider.getProcessor(), proxyBefore);
    // }

    // function test_SetProcessorImpl_UpgradesExistingProxy() public asOwner {
    //     // Get current proxy
    //     address proxyBefore = addressesProvider.getProcessor();

    //     // Deploy new implementation
    //     MockProcessorInstanceV2 newImpl = new MockProcessorInstanceV2(
    //         IProcessorAddressesProvider(address(addressesProvider))
    //     );

    //     // Upgrade
    //     addressesProvider.setProcessorImpl(address(newImpl));

    //     // Proxy address should remain the same
    //     assertEq(addressesProvider.getProcessor(), proxyBefore);
    // }

    // function test_SetProcessorImpl_PreservesStateAfterUpgrade() public asOwner {
    //     // Fund the processor first
    //     usdc.approve(processorProxy, FUND_AMOUNT);
    //     processor().fundProcessor(FUND_AMOUNT);

    //     uint256 balanceBefore = processor().getBalance();
    //     console.log("Balance before: ", balanceBefore);

    //     // Deploy new implementation
    //     MockProcessorInstanceV2 newImpl = new MockProcessorInstanceV2(
    //         IProcessorAddressesProvider(address(addressesProvider))
    //     );

    //     // Upgrade
    //     addressesProvider.setProcessorImpl(address(newImpl));

    //     // Balance should be preserved (state lives in proxy)
    //     assertEq(processor().getBalance(), balanceBefore);
    // }

    // function test_SetProcessorImpl_UpdatesImplementationAddress()
    //     public
    //     asOwner
    // {
    //     // Deploy new implementation
    //     MockProcessorInstanceV2 newImpl = new MockProcessorInstanceV2(
    //         IProcessorAddressesProvider(address(addressesProvider))
    //     );

    //     address oldImpl = address(processorImplementation);
    //     address newImplAddr = address(newImpl);

    //     // Verify they're different
    //     assertTrue(
    //         oldImpl != newImplAddr,
    //         "Should be different implementations"
    //     );
    // }

    /*//////////////////////////////////////////////////////////////
                      OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferOwnership_TransfersToNewOwner() public asOwner {
        address newOwner = makeAddr("newOwner");

        addressesProvider.transferOwnership(newOwner);

        assertEq(addressesProvider.owner(), newOwner);
    }

    function test_TransferOwnership_RevertsIfNotOwner() public asUnauthorized {
        vm.expectRevert();
        addressesProvider.transferOwnership(unauthorized);
    }

    function test_TransferOwnership_RevertsIfZeroAddress() public asOwner {
        vm.expectRevert();
        addressesProvider.transferOwnership(address(0));
    }

    function test_RenounceOwnership_SetsOwnerToZero() public asOwner {
        addressesProvider.renounceOwnership();

        assertEq(addressesProvider.owner(), address(0));
    }

    function test_RenounceOwnership_PreventsAdminFunctions() public {
        vm.prank(owner);
        addressesProvider.renounceOwnership();

        // Now no one can call admin functions
        vm.prank(owner);
        vm.expectRevert();
        addressesProvider.setStablecoin(makeAddr("newStablecoin"));
    }
}
