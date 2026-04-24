/**
 * ## Deployment Flow
 *
 * _deployCore(admin, seller, nftContract, stablecoin)
 *
 * ┌──────────────────────────────────────────────────────┐
 * │ Step 1: Deploy AddressesProvider with ALL config     │
 * │ new ProcessorAddressesProvider(                      │
 * │     admin,                                           │
 * │     seller,                                          │
 * │     nftContract,                                     │
 * │     stablecoin                                       │
 * │ )                                                    │
 * │                                                      │
 * │ Configuration stored immediately!                    │
 * └──────────────────────┬───────────────────────────────┘
 *                        │
 *                        ▼
 * ┌──────────────────────────────────────────────────────┐
 * │ Step 2: Deploy Implementation                        │
 * │ new ProcessorInstance(provider)                      │
 * │                                                      │
 * │ Only sets immutable ADDRESSES_PROVIDER               │
 * └──────────────────────┬───────────────────────────────┘
 *                        │
 *                        ▼
 * ┌──────────────────────────────────────────────────────┐
 * │ Step 3: Register → Creates Proxy                     │
 * │ setProcessorImpl(implementation)                     │
 * │                                                      │
 * │ Internally:                                          │
 * │  • Creates proxy                                     │
 * │  • Calls initialize(provider)                        │
 * │  • Reads config from provider                        │
 * └──────────────────────┬───────────────────────────────┘
 *                        │
 *                        ▼
 * ┌──────────────────────────────────────────────────────┐
 * │ Return: processorProxy                               |
 * |(This is what users interact with)                    │
 * │                                                      │
 * │ Proxy has:                                           │                       │
 * │  • totalBalance = 0                                  │
 * │  • Ready for fundProcessor()                         │
 * │                                                      │
 * │ Ready to use! Configuration complete.                │
 * └──────────────────────────────────────────────────────┘
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

// ========================================================================================================================
// RUN THIS TO DEPLOY!
// forge script script/DeployProcessor.s.sol --rpc-url $SEPOLIA_RPC_URL --account Test01 --broadcast
// ========================================================================================================================

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {ProcessorInstance} from "../src/instances/ProcessorInstance.sol";
import {ProcessorAddressesProvider} from "../src/protocol/configuration/ProcessorAddressesProvider.sol";
import {IProcessorAddressesProvider} from "../src/interfaces/IProcessorAddressesProvider.sol";

contract DeployProcessor is Script {
    // Deployed contract addresses
    ProcessorInstance public processorImplementation;
    ProcessorAddressesProvider public addressesProvider;

    // Proxy addresses (what users interact with)
    address public processorProxy;

    function setUp() public {}

    function run() public returns (address processor) {
        address sellerAddress = vm.envAddress("SELLER");
        address nftAddress = vm.envAddress("NFT_CONTRACT");
        // User can override stablecoin via environment variable
        address stablecoinAddress = vm.envOr(
            "STABLECOIN",
            _getDefaultStablecoin()
        );

        console.log("Starting Payment Processor deployment...");
        console.log("Chain ID:", block.chainid);
        console.log("Seller:", sellerAddress);
        console.log("NFT Contract:", nftAddress);
        console.log("Stablecoin:", stablecoinAddress);

        vm.startBroadcast();

        processor = _deployCore(
            msg.sender,
            sellerAddress,
            nftAddress,
            stablecoinAddress
        );

        vm.stopBroadcast();

        _logDeployment();

        return processor;
    }

    /**
     * @notice Deploy all core contracts
     * @param admin Address that deploys and owns Payment Protocol
     * @param seller Seller wallet address (receives USDC)
     * @param nftContract NFT contract address
     * @param stablecoin Stablecoin address used with the Payment Protocol
     * @return processorProxy The address of the Processor proxy (user-facing)
     */
    function _deployCore(
        address admin,
        address seller,
        address nftContract,
        address stablecoin
    ) internal returns (address) {
        // Step 1. Deploy ProcessorAddressesProvider
        // This is the central registry and proxy factory

        addressesProvider = new ProcessorAddressesProvider(
            admin,
            seller,
            nftContract,
            stablecoin
        );
        console.log(
            "1. ProcessorAddressesProvider deployed:",
            address(addressesProvider)
        );

        // Step 2. Deploy ProcessorInstance (Implementation)
        processorImplementation = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
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

    function _getDefaultStablecoin() internal view returns (address) {
        uint256 chainId = block.chainid;

        /*//////////////////////////////////////////////////////////////
                              MAINNETS
        //////////////////////////////////////////////////////////////*/

        // Ethereum Mainnet
        if (chainId == 1) return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        // Base
        if (chainId == 8453) return 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

        // Polygon PoS
        if (chainId == 137) return 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;

        // Arbitrum One
        if (chainId == 42161) return 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

        // Optimism
        if (chainId == 10) return 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

        // Avalanche C-Chain
        if (chainId == 43114) return 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

        // BNB Smart Chain
        if (chainId == 56) return 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

        /*//////////////////////////////////////////////////////////////
                              TESTNETS
        //////////////////////////////////////////////////////////////*/

        // Sepolia (Ethereum testnet)
        if (chainId == 11155111)
            return 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

        // Base Sepolia
        if (chainId == 84532) return 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        // Arbitrum Sepolia
        if (chainId == 421614)
            return 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

        // Polygon Amoy (testnet)
        if (chainId == 80002) return 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;

        /*//////////////////////////////////////////////////////////////
                              LOCAL
        //////////////////////////////////////////////////////////////*/

        // Anvil / Hardhat local (deploy MockUSDC or use fork)
        if (chainId == 31337)
            revert("Deploy MockUSDC or use --fork-url for local testing");

        revert("Unsupported chain - set STABLECOIN env var");
    }

    function _logDeployment() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Chain ID:                  ", block.chainid);
        console.log(
            "Seller:                     ",
            addressesProvider.getSeller()
        );
        console.log(
            "NFT Contract:               ",
            addressesProvider.getNFTContract()
        );
        console.log(
            "Stablecoin:                ",
            addressesProvider.getStablecoin()
        );
        console.log("Processor AddressesProvider:", address(addressesProvider));
        console.log("Processor (Proxy):         ", processorProxy);
        console.log(
            "Processor (Implementation):",
            address(processorImplementation)
        );
        console.log("========================================\n");
    }
}
