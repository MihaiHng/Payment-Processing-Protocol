// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Test, console, console2} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Mocks
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {MockNFT} from "./mocks/MockNFT.sol";
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
    MockNFT public nft;
    ProcessorAddressesProvider public addressesProvider;
    ProcessorInstance public processorImplementation;
    address public processorProxy;

    /*//////////////////////////////////////////////////////////////
                              ACTORS
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public seller;
    address public buyer;
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
    uint256 public constant TICKET_PRICE = 100e6; // 100 USDC

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Declare events for expectEmit
    event StablecoinSet(
        address indexed oldStablecoin,
        address indexed newStablecoin
    );
    event SellerUpdated(address indexed oldSeller, address indexed newSeller);
    event NFTContractUpdated(address indexed oldNFT, address indexed newNFT);
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
    event PaymentProcessed(
        bytes32 indexed paymentId,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        address seller
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

    modifier asSeller() {
        vm.startPrank(seller);
        _;
        vm.stopPrank();
    }

    modifier asBuyer() {
        vm.startPrank(buyer);
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

        // Deploy mock
        _deployMocks();

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
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        unauthorized = makeAddr("unauthorized");
    }

    function _deployMocks() internal {
        usdc = new MockUSDC();
        nft = new MockNFT();
    }

    function _deployProtocol() internal {
        vm.startPrank(owner);

        // 1. Deploy AddressesProvider
        addressesProvider = new ProcessorAddressesProvider(
            owner,
            seller,
            address(nft),
            address(usdc)
        );

        // 2. Deploy Implementation
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
        usdc.mint(seller, INITIAL_USDC_BALANCE);
        usdc.mint(buyer, INITIAL_USDC_BALANCE);
        usdc.mint(user1, INITIAL_USDC_BALANCE);
        usdc.mint(user2, INITIAL_USDC_BALANCE);
        usdc.mint(user3, INITIAL_USDC_BALANCE);
    }

    // ???????????????????????
    // 100 Nfts are minted to owner?

    // Approve processor to transfer NFTs
    nft.setApprovalForAll(processorProxy, true);
    vm.stopPrank();

    // Fund processor with USDC
    _fundProcessor(FUND_AMOUNT);

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

    // @notice Generate a unique payment ID
    function _generatePaymentId(string memory seed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }

    /*//////////////////////////////////////////////////////////////
                          ASSERTION HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Assert processor balance matches expected
    function assertProcessorBalance(uint256 expected) internal view {
        assertEq(
            processor().getBalance(),
            expected,
            "Processor balance mismatch"
        );
    }

    /// @notice Assert processor actual USDC balance matches expected
    function assertProcessorActualBalance(uint256 expected) internal view {
        assertEq(
            processor().getActualBalance(),
            expected,
            "Processor actual USDC balance mismatch"
        );
    }

    /// @notice Assert user USDC balance
    function assertUserBalance(address user, uint256 expected) internal view {
        assertEq(usdc.balanceOf(user), expected, "User USDC balance mismatch");
    }

    function assertNFTOwner(
        uint256 tokenId,
        address expectedOwner
    ) internal view {
        assertEq(nft.ownerOf(tokenId), expectedOwner, "NFT owner mismatch");
    }
}
