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

/**
 # Deploy with default USDC
forge script script/DeployProcessor.s.sol \
    --rpc-url $BASE_RPC_URL \
    --account deployer \
    --broadcast

# Deploy with USDT instead
STABLECOIN=0xdAC17F958D2ee523a2206206994597C13D831ec7 \
forge script script/DeployProcessor.s.sol \
    --rpc-url $ETH_RPC_URL \
    --account deployer \
    --broadcast

# Deploy with DAI
STABLECOIN=0x6B175474E89094C44Da98b954EesfddfE3C4Beba \
forge script script/DeployProcessor.s.sol \
    --rpc-url $ETH_RPC_URL \
    --account deployer \
    --broadcast
 */

/**
 Usage Examples

 # Example 1: No env var → Uses default USDC for the chain
forge script script/DeployProcessor.s.sol --rpc-url $BASE_RPC_URL --broadcast
# Result: stablecoinAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 (Base USDC)


# Example 2: Set STABLECOIN env var → Uses provided address
STABLECOIN=0xdAC17F958D2ee523a2206206994597C13D831ec7 \
forge script script/DeployProcessor.s.sol --rpc-url $ETH_RPC_URL --broadcast
# Result: stablecoinAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7 (USDT)


# Example 3: Export first, then run
export STABLECOIN=0x6B175474E89094C44Da98b954EesdeadE3C4Beba
forge script script/DeployProcessor.s.sol --rpc-url $ETH_RPC_URL --broadcast
# Result: stablecoinAddress = 0x6B175474E89094C44Da98b954EeadeadE3C4Beba (DAI)
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {ProcessorInstance} from "../src/instances/ProcessorInstance.sol";
import {ProcessorAddressesProvider} from "../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {IProcessorAddressesProvider} from "../src/interfaces/IProcessorAddressesProvider.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployProcessor is Script {
    // Deployed contract addresses
    ProcessorInstance public processorImplementation;
    ProcessorAddressesProvider public addressesProvider;

    // Proxy addresses (what users interact with)
    address public processorProxy;

    function setUp() public {}

    function run() public returns (address processor) {
        // User can override stablecoin via environment variable
        address stablecoinAddress = vm.envOr(
            "STABLECOIN",
            _getDefaultStablecoin()
        );

        console.log("Starting Payment Processor deployment...");
        console.log("Chain ID:", block.chainid);
        console.log("Stablecoin:", stablecoinAddress);

        vm.startBroadcast();

        processor = _deployCore(msg.sender, stablecoinAddress);

        vm.stopBroadcast();

        _logDeployment();

        return processor;
    }

    /**
     * @notice Deploy all core contracts
     * @param admin User that deploys and owns Payment Protocol
     * @param stablecoinAddress Stablecoin address used with the Payment Protocol
     * @return processorProxy The address of the Processor proxy (user-facing)
     */
    function _deployCore(
        address admin,
        address stablecoinAddress
    ) internal returns (address) {
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
