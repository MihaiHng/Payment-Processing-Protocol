// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Test, console, console2} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Mocks
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {MockProcessorInstanceV2} from "./mocks/MockProcessorInstanceV2.sol";

// Protocol contracts
import {ProcessorAddressesProvider} from "../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {ProcessorInstance} from "../src/instances/ProcessorInstance.sol";
import {Processor} from "../src/protocol/processor/Processor.sol";

// Interfaces
import {IProcessorAddressesProvider} from "../src/interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../src/interfaces/IProcessor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BaseTest
 * @notice Base contract for all unit tests
 * @dev Provides common setup, helpers, and utilities
 */
contract BaseTest is Test {
    /*//////////////////////////////////////////////////////////////
                              CONTRACTS
    //////////////////////////////////////////////////////////////*/

    MockUSDC public usdc;
    ProcessorAddressesProvider public addressesProvider;
    ProcessorInstance public processorImplementation;
    address public processorProxy;

    /*//////////////////////////////////////////////////////////////
                              ACTORS
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public user1;
    address public user2;
    address public user3;

    /// @dev Address with no special permissions
    address public unauthorized;

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant INITIAL_USDC_BALANCE = 1_000_000e6; // 1M USDC
    uint256 public constant FUND_AMOUNT = 10_000e6; // 10k USDC

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Declare events for expectEmit
    event StablecoinSet(
        address indexed oldStablecoin,
        address indexed newStablecoin
    );
    event ProcessorUpdated(address indexed oldImpl, address indexed newImpl);
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed oldImplementationAddress,
        address newImplementationAddress
    );

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Prank as owner for the duration of the test
    modifier asOwner() {
        vm.startPrank(owner);
        _;
        vm.stopPrank();
    }

    /// @notice Prank as user1 for the duration of the test
    modifier asUser1() {
        vm.startPrank(user1);
        _;
        vm.stopPrank();
    }

    /// @notice Prank as unauthorized user for the duration of the test
    modifier asUnauthorized() {
        vm.startPrank(unauthorized);
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create actors
        _createActors();

        // Deploy mock USDC
        _deployMockUSDC();

        // Deploy protocol
        _deployProtocol();

        // Setup initial state
        _setupInitialState();
    }

    /*//////////////////////////////////////////////////////////////
                          SETUP HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createActors() internal {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        unauthorized = makeAddr("unauthorized");
    }

    function _deployMockUSDC() internal {
        usdc = new MockUSDC();
    }

    function _deployProtocol() internal {
        vm.startPrank(owner);

        // 1. Deploy AddressesProvider
        addressesProvider = new ProcessorAddressesProvider(owner);

        // 2. Set stablecoin
        addressesProvider.setStablecoin(address(usdc));

        // 3. Deploy Implementation
        processorImplementation = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );

        // 4. Register Implementation → Creates Proxy
        addressesProvider.setProcessorImpl(address(processorImplementation));
        processorProxy = addressesProvider.getProcessor();

        vm.stopPrank();
    }

    function _setupInitialState() internal {
        // Mint USDC to actors
        usdc.mint(owner, INITIAL_USDC_BALANCE);
        usdc.mint(user1, INITIAL_USDC_BALANCE);
        usdc.mint(user2, INITIAL_USDC_BALANCE);
        usdc.mint(user3, INITIAL_USDC_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the Processor interface for the proxy
    function processor() public view returns (IProcessor) {
        return IProcessor(processorProxy);
    }

    /// @notice Fund the processor with USDC (as owner)
    function _fundProcessor(uint256 amount) internal {
        vm.startPrank(owner);
        usdc.approve(processorProxy, amount);
        processor().fundProcessor(amount);
        vm.stopPrank();
    }

    /// @notice Fund the processor with USDC (as specific user)
    // function _fundProcessorAs(address user, uint256 amount) internal {
    //     vm.startPrank(user);
    //     usdc.approve(processorProxy, amount);
    //     processor().fundProcessor(amount);
    //     vm.stopPrank();
    // }

    /// @notice Approve USDC spending for processor
    function _approveUSDC(address user, uint256 amount) internal {
        vm.prank(user);
        usdc.approve(processorProxy, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          ASSERTION HELPERS
    //////////////////////////////////////////////////////////////*/

    // /// @notice Assert processor balance matches expected
    // function assertProcessorBalance(uint256 expected) internal view {
    //     assertEq(
    //         processor().getBalance(),
    //         expected,
    //         "Processor balance mismatch"
    //     );
    // }

    // /// @notice Assert processor actual USDC balance matches expected
    // function assertProcessorActualBalance(uint256 expected) internal view {
    //     assertEq(
    //         processor().getActualBalance(),
    //         expected,
    //         "Processor actual USDC balance mismatch"
    //     );
    // }

    // /// @notice Assert user USDC balance
    // function assertUserBalance(address user, uint256 expected) internal view {
    //     assertEq(usdc.balanceOf(user), expected, "User USDC balance mismatch");
    // }
}
