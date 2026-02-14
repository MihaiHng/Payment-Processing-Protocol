// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";

// Core contracts
// import {PoolAddressesProvider} from "@aave-v3-origin/contracts/protocol/configuration/PoolAddressesProvider.sol";
// import {PoolInstance} from "@aave-v3-origin/contracts/instances/PoolInstance.sol";
// import {PoolConfiguratorInstance} from "@aave-v3-origin/contracts/instances/PoolConfiguratorInstance.sol";
// import {ACLManager} from "@aave-v3-origin/contracts/protocol/configuration/ACLManager.sol";
// import {AaveOracle} from "@aave-v3-origin/contracts/misc/AaveOracle.sol";
// import {AaveProtocolDataProvider} from "@aave-v3-origin/contracts/misc/AaveProtocolDataProvider.sol";
// import {DefaultReserveInterestRateStrategyV2} from "@aave-v3-origin/contracts/misc/DefaultReserveInterestRateStrategyV2.sol";

// Interfaces
// import {IPoolAddressesProvider} from "@aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol";
// import {IPool} from "@aave-v3-origin/contracts/interfaces/IPool.sol";

/**
 * @title DeployAaveV3
 * @notice Foundry script to deploy Aave V3 core contracts
 * @dev This demonstrates the deployment order and how contracts are wired together
 *
 * Deployment Order:
 * 1. PoolAddressesProvider (the registry)
 * 2. ACLManager (access control)
 * 3. DefaultReserveInterestRateStrategy (shared rate strategy)
 * 4. PoolInstance (implementation)
 * 5. Register Pool via setPoolImpl() → creates proxy
 * 6. PoolConfiguratorInstance (implementation)
 * 7. Register PoolConfigurator via setPoolConfiguratorImpl()
 * 8. AaveOracle
 * 9. AaveProtocolDataProvider
 */
contract DeployAaveV3 is Script {
    // Deployed contract addresses
    PoolAddressesProvider public addressesProvider;
    ACLManager public aclManager;
    DefaultReserveInterestRateStrategyV2 public interestRateStrategy;
    PoolInstance public poolImplementation;
    PoolConfiguratorInstance public poolConfiguratorImplementation;
    AaveOracle public aaveOracle;
    AaveProtocolDataProvider public protocolDataProvider;

    // Proxy addresses (what users interact with)
    address public poolProxy;
    address public poolConfiguratorProxy;

    // Configuration
    string public constant MARKET_ID = "Aave V3 Test Market";

    function run() external returns (address pool) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Starting Aave V3 deployment...");

        vm.startBroadcast(deployerPrivateKey);

        pool = _deployCore(deployer);

        vm.stopBroadcast();

        _logDeployment();

        return pool;
    }

    /**
     * @notice Deploy all core contracts
     * @param admin The admin address for the protocol
     * @return poolProxy The address of the Pool proxy (user-facing)
     */
    function _deployCore(address admin) internal returns (address) {
        // ═══════════════════════════════════════════════════════════════════
        // STEP 1: Deploy PoolAddressesProvider
        // This is the central registry and proxy factory
        // ═══════════════════════════════════════════════════════════════════
        addressesProvider = new PoolAddressesProvider(MARKET_ID, admin);
        console.log(
            "1. PoolAddressesProvider deployed:",
            address(addressesProvider)
        );

        // ═══════════════════════════════════════════════════════════════════
        // STEP 2: Deploy and configure ACLManager
        // Manages roles like POOL_ADMIN, RISK_ADMIN, etc.
        // ═══════════════════════════════════════════════════════════════════
        aclManager = new ACLManager(
            IPoolAddressesProvider(address(addressesProvider))
        );

        // Register ACLManager in the AddressesProvider
        addressesProvider.setACLManager(address(aclManager));
        addressesProvider.setACLAdmin(admin);

        // Grant admin the POOL_ADMIN role
        aclManager.addPoolAdmin(admin);

        console.log("2. ACLManager deployed:", address(aclManager));

        // ═══════════════════════════════════════════════════════════════════
        // STEP 3: Deploy Interest Rate Strategy
        // Shared strategy used by all reserves
        // ═══════════════════════════════════════════════════════════════════
        interestRateStrategy = new DefaultReserveInterestRateStrategyV2(
            address(addressesProvider)
        );
        console.log(
            "3. InterestRateStrategy deployed:",
            address(interestRateStrategy)
        );

        // ═══════════════════════════════════════════════════════════════════
        // STEP 4: Deploy Pool Implementation (PoolInstance)
        // This is the actual logic contract, NOT what users call directly
        // ═══════════════════════════════════════════════════════════════════
        poolImplementation = new PoolInstance(
            IPoolAddressesProvider(address(addressesProvider)),
            interestRateStrategy
        );
        console.log(
            "4. PoolInstance (implementation) deployed:",
            address(poolImplementation)
        );

        // ═══════════════════════════════════════════════════════════════════
        // STEP 5: Register Pool Implementation → Creates Proxy
        // This is the KEY step! setPoolImpl:
        //   - Creates InitializableImmutableAdminUpgradeabilityProxy
        //   - Sets PoolInstance as the implementation
        //   - Calls Pool.initialize(addressesProvider)
        // ═══════════════════════════════════════════════════════════════════
        addressesProvider.setPoolImpl(address(poolImplementation));

        // Get the proxy address (this is what users will interact with)
        poolProxy = addressesProvider.getPool();
        console.log("5. Pool Proxy created:", poolProxy);
        console.log("   -> Implementation:", address(poolImplementation));

        // ═══════════════════════════════════════════════════════════════════
        // STEP 6: Deploy PoolConfigurator Implementation
        // ═══════════════════════════════════════════════════════════════════
        poolConfiguratorImplementation = new PoolConfiguratorInstance();
        console.log(
            "6. PoolConfiguratorInstance deployed:",
            address(poolConfiguratorImplementation)
        );

        // ═══════════════════════════════════════════════════════════════════
        // STEP 7: Register PoolConfigurator → Creates Proxy
        // ═══════════════════════════════════════════════════════════════════
        addressesProvider.setPoolConfiguratorImpl(
            address(poolConfiguratorImplementation)
        );
        poolConfiguratorProxy = addressesProvider.getPoolConfigurator();
        console.log(
            "7. PoolConfigurator Proxy created:",
            poolConfiguratorProxy
        );

        // ═══════════════════════════════════════════════════════════════════
        // STEP 8: Deploy and register AaveOracle
        // ═══════════════════════════════════════════════════════════════════
        address[] memory emptyAssets = new address[](0);
        address[] memory emptySources = new address[](0);

        aaveOracle = new AaveOracle(
            IPoolAddressesProvider(address(addressesProvider)),
            emptyAssets,
            emptySources,
            address(0), // fallback oracle
            address(0), // base currency (ETH)
            1e8 // base currency unit
        );
        addressesProvider.setPriceOracle(address(aaveOracle));
        console.log("8. AaveOracle deployed:", address(aaveOracle));

        // ═══════════════════════════════════════════════════════════════════
        // STEP 9: Deploy and register ProtocolDataProvider
        // ═══════════════════════════════════════════════════════════════════
        protocolDataProvider = new AaveProtocolDataProvider(
            IPoolAddressesProvider(address(addressesProvider))
        );
        addressesProvider.setPoolDataProvider(address(protocolDataProvider));
        console.log(
            "9. ProtocolDataProvider deployed:",
            address(protocolDataProvider)
        );

        return poolProxy;
    }

    function _logDeployment() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("PoolAddressesProvider:", address(addressesProvider));
        console.log("Pool (Proxy):         ", poolProxy);
        console.log("Pool (Implementation):", address(poolImplementation));
        console.log("PoolConfigurator:     ", poolConfiguratorProxy);
        console.log("ACLManager:           ", address(aclManager));
        console.log("AaveOracle:           ", address(aaveOracle));
        console.log("DataProvider:         ", address(protocolDataProvider));
        console.log("InterestRateStrategy: ", address(interestRateStrategy));
        console.log("========================================\n");
    }
}
