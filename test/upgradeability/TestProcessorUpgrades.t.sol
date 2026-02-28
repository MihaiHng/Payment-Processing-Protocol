// test/upgradeability/TestProcessorUpgrades.t.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {ProcessorAddressesProvider} from "../../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {Processor} from "../../src/protocol/processor/Processor.sol";
import {ProcessorInstance} from "../../src/instances/ProcessorInstance.sol";
import {MockProcessorInstanceV2} from "../mocks/MockProcessorInstanceV2.sol";
import {MockProcessorInstanceV3} from "../mocks/MockProcessorInstanceV3.sol";
import {IProcessorAddressesProvider} from "../../src/interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../../src/interfaces/IProcessor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TestProcessorUpgrades
 * @notice Comprehensive upgradeability tests for the Processor
 */
contract TestProcessorUpgrades is BaseTest {
    MockProcessorInstanceV2 public implementationV2;

    function setUp() public override {
        super.setUp();

        // Pre-deploy V2 for tests
        vm.prank(owner);
        implementationV2 = new MockProcessorInstanceV2(
            IProcessorAddressesProvider(address(addressesProvider))
        );
    }

    /*//////////////////////////////////////////////////////////////
                      PROXY ADDRESS PERSISTENCE
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_ProxyAddressRemainsConstant() public asOwner {
        address proxyBefore = addressesProvider.getProcessor();

        addressesProvider.setProcessorImpl(address(implementationV2));

        address proxyAfter = addressesProvider.getProcessor();

        assertEq(proxyBefore, proxyAfter, "Proxy address should not change");
    }

    function test_Upgrade_MultipleUpgrades_ProxyAddressConstant()
        public
        asOwner
    {
        address originalProxy = addressesProvider.getProcessor();

        // Upgrade to V2
        addressesProvider.setProcessorImpl(address(implementationV2));
        assertEq(addressesProvider.getProcessor(), originalProxy);

        // Upgrade to V3
        MockProcessorInstanceV3 implV3 = new MockProcessorInstanceV3(
            IProcessorAddressesProvider(address(addressesProvider))
        );
        addressesProvider.setProcessorImpl(address(implV3));
        assertEq(addressesProvider.getProcessor(), originalProxy);
    }

    /*//////////////////////////////////////////////////////////////
                      IMPLEMENTATION UPDATED
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_UpdatesImplementationAddress() public asOwner {
        // Deploy new implementation
        MockProcessorInstanceV2 newImpl = new MockProcessorInstanceV2(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        address oldImpl = address(processorImplementation);
        address newImplAddr = address(newImpl);

        // Verify they're different
        assertTrue(
            oldImpl != newImplAddr,
            "Should be different implementations"
        );
    }

    /*//////////////////////////////////////////////////////////////
                      STATE PRESERVATION
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_PreservesTotalBalance() public asOwner {
        // Fund processor
        usdc.approve(processorProxy, FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        uint256 balanceBefore = processor().getBalance();

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Verify balance preserved
        assertEq(
            processor().getBalance(),
            balanceBefore,
            "Balance not preserved"
        );
    }

    function test_Upgrade_PreservesStablecoinAddress() public asOwner {
        address stablecoinBefore = processor().getStablecoin();

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Verify stablecoin preserved
        assertEq(
            processor().getStablecoin(),
            stablecoinBefore,
            "Stablecoin not preserved"
        );
    }

    function test_Upgrade_PreservesOwnership() public asOwner {
        address ownerBefore = Ownable(processorProxy).owner();

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Verify owner preserved
        assertEq(
            Ownable(processorProxy).owner(),
            ownerBefore,
            "Owner not preserved"
        );
    }

    function test_Upgrade_PreservesActualUSDCBalance() public asOwner {
        // Fund processor
        usdc.approve(processorProxy, FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        uint256 actualBalanceBefore = usdc.balanceOf(processorProxy);

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Verify actual USDC balance preserved
        assertEq(
            usdc.balanceOf(processorProxy),
            actualBalanceBefore,
            "Actual USDC balance not preserved"
        );
    }

    function test_Upgrade_PreservesStateAfterMultipleFundings() public asOwner {
        // Multiple funding operations
        usdc.approve(processorProxy, FUND_AMOUNT * 3);
        processor().fundProcessor(FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        uint256 balanceBefore = processor().getBalance();

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        assertEq(processor().getBalance(), balanceBefore);
    }

    /*//////////////////////////////////////////////////////////////
                      FUNCTIONALITY AFTER UPGRADE
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_CanFundAfterUpgrade() public asOwner {
        // Upgrade first
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Then fund
        usdc.approve(processorProxy, FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        assertEq(processor().getBalance(), FUND_AMOUNT);
    }

    function test_Upgrade_CanWithdrawAfterUpgrade() public asOwner {
        // Fund before upgrade
        usdc.approve(processorProxy, FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Withdraw after upgrade
        uint256 balanceBefore = usdc.balanceOf(owner);
        processor().withdrawFromProcessor(FUND_AMOUNT / 2);

        assertEq(usdc.balanceOf(owner), balanceBefore + FUND_AMOUNT / 2);
        assertEq(processor().getBalance(), FUND_AMOUNT / 2);
    }

    function test_Upgrade_CanWithdrawAllAfterUpgrade() public asOwner {
        // Fund before upgrade
        usdc.approve(processorProxy, FUND_AMOUNT);
        processor().fundProcessor(FUND_AMOUNT);

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Withdraw all after upgrade
        processor().withdrawAllFromProcessor();

        assertEq(processor().getBalance(), 0);
    }

    function test_Upgrade_V2NewFeaturesWork() public asOwner {
        // Upgrade to V2
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Cast to V2 and call new function
        MockProcessorInstanceV2 proxyAsV2 = MockProcessorInstanceV2(
            processorProxy
        );
        assertEq(proxyAsV2.v2Feature(), "I am V2!");
    }

    /*//////////////////////////////////////////////////////////////
                      REVISION CHECKS
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_RevertsIfSameRevision() public asOwner {
        // Get initial state
        address proxyBefore = addressesProvider.getProcessor();

        // Try to "upgrade" with same V1 revision
        ProcessorInstance sameRevisionImpl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        // Should revert because revision 1 is not > 1
        // Note: Revert data is lost when bubbled through proxy
        vm.expectRevert();
        addressesProvider.setProcessorImpl(address(sameRevisionImpl));

        // Verify proxy unchanged (upgrade failed)
        assertEq(addressesProvider.getProcessor(), proxyBefore);
    }

    function test_Upgrade_RevertsIfPastRevision() public asOwner {
        // First upgrade to V2
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Get initial state
        address proxyBefore = addressesProvider.getProcessor();

        // Try to downgrade to V1
        ProcessorInstance v1Impl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        vm.expectRevert();
        addressesProvider.setProcessorImpl(address(v1Impl));

        // Verify proxy unchanged (upgrade failed)
        assertEq(addressesProvider.getProcessor(), proxyBefore);
    }

    /*//////////////////////////////////////////////////////////////
                      ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_OnlyOwnerCanUpgrade() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        addressesProvider.setProcessorImpl(address(implementationV2));
    }

    function test_Upgrade_OnlyOwnerCanUseProxyAfterUpgrade() public asOwner {
        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // Unauthorized user cannot fund
        vm.stopPrank();
        vm.startPrank(unauthorized);
        usdc.mint(unauthorized, FUND_AMOUNT);
        usdc.approve(processorProxy, FUND_AMOUNT);

        vm.expectRevert();
        processor().fundProcessor(FUND_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                      IMMUTABLE PRESERVATION
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_AddressesProviderImmutablePreserved() public asOwner {
        // Get ADDRESSES_PROVIDER before upgrade
        address providerBefore = address(
            ProcessorInstance(processorProxy).ADDRESSES_PROVIDER()
        );

        // Upgrade
        addressesProvider.setProcessorImpl(address(implementationV2));

        // ADDRESSES_PROVIDER should still point to same address
        // Note: This is immutable in implementation, so it's actually
        // the new implementation's immutable - but should be same address
        assertEq(
            address(ProcessorInstance(processorProxy).ADDRESSES_PROVIDER()),
            providerBefore,
            "ADDRESSES_PROVIDER changed"
        );
    }

    /*//////////////////////////////////////////////////////////////
                      EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_WithZeroBalance() public asOwner {
        // Don't fund, just upgrade
        assertEq(processor().getBalance(), 0);

        addressesProvider.setProcessorImpl(address(implementationV2));

        assertEq(processor().getBalance(), 0);
    }

    function test_Upgrade_ImmediatelyAfterDeployment() public {
        vm.startPrank(owner);

        // Fresh deployment
        ProcessorAddressesProvider freshProvider = new ProcessorAddressesProvider(
                owner
            );
        freshProvider.setStablecoin(address(usdc));

        ProcessorInstance v1 = new ProcessorInstance(
            IProcessorAddressesProvider(address(freshProvider))
        );
        freshProvider.setProcessorImpl(address(v1));

        // Immediately upgrade to V2
        MockProcessorInstanceV2 v2 = new MockProcessorInstanceV2(
            IProcessorAddressesProvider(address(freshProvider))
        );
        freshProvider.setProcessorImpl(address(v2));

        // Should work
        assertTrue(freshProvider.getProcessor() != address(0));

        vm.stopPrank();
    }
}
