/**
 * ## Deployment Flow
 * 
_deployCore(admin)
       │
       ▼
┌──────────────────────────────────────┐
│ Step 1: Deploy AddressesProvider     │
│ new ProcessorAddressesProvider(admin)│
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ Step 2: Deploy Implementation        │
│ new ProcessorInstance(provider)      │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ Step 3: Register → Creates Proxy     │
│ setProcessorImpl(implementation)     │
│                                      │
│ Internally:                          │
│  • Creates proxy                     │
│  • Sets implementation               │
│  • Calls initialize()                │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ Return: processorProxy               │
│ (This is what users interact with)   │
└──────────────────────────────────────┘
 */

/**
 # Deploy using your encrypted account
forge script script/DeployProcessor.s.sol \
    --rpc-url $RPC_URL \
    --account deployer \
    --broadcast

# It will prompt for your password (hidden input) 
 */

/**
 # Local (Anvil)
forge script script/DeployProcessor.s.sol \
    --rpc-url http://localhost:8545 \
    --account deployer \
    --broadcast

# Testnet (Sepolia)
forge script script/DeployProcessor.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --account deployer \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

# Mainnet (with confirmation)
forge script script/DeployProcessor.s.sol \
    --rpc-url $MAINNET_RPC_URL \
    --account deployer \
    --broadcast \
    --verify \
    --slow
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {Processor} from "../src/protocol/processor/Processor.sol";
import {ProcessorInstance} from "../src/instances/ProcessorInstance.sol";
import {ProcessorAddressesProvider} from "../src/protocol/configuration/ProcessorAddressesProvider.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProcessor is Script {
    IERC20 public usdc;
    uint256 public constant initialAmount = 1000e6;

    // Deployed contract addresses
    ProcessorInstance public processorImplementation;
    ProcessorAddressesProvider public addressesProvider;

    // Proxy addresses (what users interact with)
    address public processorProxy;

    /**
     * # 1. Approve USDC to contract (needs to happen before or during deploy)
     * # 2. Deploy contract with constructor args
     * # 3. Contract receives initial funding via transferFrom
     * # 4. User can call fundSmartContract() for additional funding
     */

    function setUp() public {}

    function run() public returns (address processor) {
        console.log("Starting Aave V3 deployment...");

        vm.startBroadcast();

        processor = _deployCore(msg.sender);

        vm.stopBroadcast();

        _logDeployment();

        return processor;
    }

    /**
     * @notice Deploy all core contracts
     * @return processorProxy The address of the Processor proxy (user-facing)
     */
    function _deployCore(address admin) internal returns (address) {
        // Step 1. Deploy ProcessorAddressesProvider
        // This is the central registry and proxy factory

        addressesProvider = new ProcessorAddressesProvider(admin);
        console.log(
            "1. ProcessorAddressesProvider deployed:",
            address(addressesProvider)
        );

        // Step 2. Deploy ProcessorInstance (Implementation)
        processorImplementation = new ProcessorInstance(
            addressesProvider,
            address(usdc),
            initialAmount
        );

        console.log(
            "2. ProcessorInstance (implementation) deployed:",
            address(processorImplementation)
        );

        // Step 3. Register Implementation → Creates Proxy
        addressesProvider.setProcessorImpl(address(processorImplementation));

        processorProxy = addressesProvider.getProcessor();
        console.log("3. Processor Proxy created:", processorProxy);

        return processorProxy;
    }

    function _logDeployment() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Processor AddressesProvider:", address(addressesProvider));
        console.log("Processor (Proxy):         ", processorProxy);
        console.log(
            "Processor (Implementation):",
            address(processorImplementation)
        );
        console.log("========================================\n");
    }
}
