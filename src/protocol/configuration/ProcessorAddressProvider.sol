// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../../misc/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";

contract ProcessorAddressesProvider is Ownable, IProcessorAddressesProvider {
    // Chain identifier(ex. Ethereum mainnet)
    // string private _chainId;

    // Map of registered addresses (identifier => registeredAddress)
    mapping(bytes32 => address) private _addresses;

    // Main identifiers
    bytes32 private constant PROCESSOR = "PROCESSOR";

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract.
     */
    constructor(address owner) Ownable(owner) {}

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProcessorAddressesProvider
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getProcessor() external view override returns (address) {
        return getAddress(PROCESSOR);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProcessorAddressesProvider
    function setAddress(
        bytes32 id,
        address newAddress
    ) external override onlyOwner {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /// @inheritdoc IProcessorAddressesProvider
    function setAddressAsProxy(
        bytes32 id,
        address newImplementationAddress
    ) external override onlyOwner {
        address proxyAddress = _addresses[id];
        address oldImplementationAddress = _getProxyImplementation(id);
        _updateImpl(id, newImplementationAddress);
        emit AddressSetAsProxy(
            id,
            proxyAddress,
            oldImplementationAddress,
            newImplementationAddress
        );
    }

    /// @inheritdoc IProcessorAddressesProvider
    function setProcessorImpl(
        address newProcessorImpl
    ) external override onlyOwner {
        address oldProcessorImpl = _getProxyImplementation(PROCESSOR);
        _updateImpl(PROCESSOR, newProcessorImpl);
        emit ProcessorUpdated(oldProcessorImpl, newProcessorImpl);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Internal function to update the implementation of a specific proxied component of the protocol.
     * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
     *   as implementation and calls the initialize() function on the proxy
     * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     */
    function _updateImpl(bytes32 id, address newAddress) internal {
        address proxyAddress = _addresses[id];
        InitializableImmutableAdminUpgradeabilityProxy proxy;
        bytes memory params = abi.encodeWithSignature(
            "initialize(address)",
            address(this)
        );

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            _addresses[id] = proxyAddress = address(proxy);
            proxy.initialize(newAddress, params);
            emit ProxyCreated(id, proxyAddress, newAddress);
        } else {
            proxy = InitializableImmutableAdminUpgradeabilityProxy(
                payable(proxyAddress)
            );
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    //   /**
    //    * @notice Updates the identifier of the Aave market.
    //    * @param newMarketId The new id of the market
    //    */
    //   function _setMarketId(string memory newMarketId) internal {
    //     string memory oldMarketId = _marketId;
    //     _marketId = newMarketId;
    //     emit MarketIdSet(oldMarketId, newMarketId);
    //   }

    /**
     * @notice Returns the implementation contract of the proxy contract by its identifier.
     * @dev It returns ZERO if there is no registered address with the given id
     * @dev It reverts if the registered address with the given id is not `InitializableImmutableAdminUpgradeabilityProxy`
     * @param id The id
     * @return The address of the implementation contract
     */
    function _getProxyImplementation(bytes32 id) internal returns (address) {
        address proxyAddress = _addresses[id];
        if (proxyAddress == address(0)) {
            return address(0);
        } else {
            address payable payableProxyAddress = payable(proxyAddress);
            return
                InitializableImmutableAdminUpgradeabilityProxy(
                    payableProxyAddress
                ).implementation();
        }
    }
}
