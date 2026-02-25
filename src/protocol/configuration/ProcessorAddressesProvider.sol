// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../../misc/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

contract ProcessorAddressesProvider is Ownable, IProcessorAddressesProvider {
    // Identifier for different Processor versions on the same chain -> possible future development
    // string private _versionId;

    // Map of registered addresses (identifier => registeredAddress)
    mapping(bytes32 => address) private _addresses;

    // Main identifiers
    bytes32 private constant PROCESSOR = "PROCESSOR";
    bytes32 private constant STABLECOIN = "STABLECOIN";

    // Future modules:
    // bytes32 private constant FEE_MANAGER = "FEE_MANAGER";
    // bytes32 private constant PROCESSOR_CONFIGURATOR = "PROCESSOR_CONFIGURATOR";

    /**
     * @dev Constructor.
     * @param initOwner The owner address of this contract.
     */
    constructor(
        address initOwner /*, string memory versionId*/
    ) Ownable(initOwner) {
        // _setVersionId(versionId); // Possible future development, different processor for different projects and needs
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the owner of the contract
     * @dev Overrides both Ownable and IProcessorAddressesProvider
     */
    function owner()
        public
        view
        override(Ownable, IProcessorAddressesProvider)
        returns (address)
    {
        return super.owner(); // Calls Ownable's owner()
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getProcessor() external view override returns (address) {
        return getAddress(PROCESSOR);
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getStablecoin() external view override returns (address) {
        return getAddress(STABLECOIN);
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
    function setStablecoin(
        address stablecoinAddress
    ) external override onlyOwner {
        if (stablecoinAddress == address(0)) {
            revert Errors.PPP__InvalidStablecoin();
        }
        address oldStablecoin = _addresses[STABLECOIN];
        _addresses[STABLECOIN] = stablecoinAddress;
        emit StablecoinSet(oldStablecoin, stablecoinAddress);
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
        address stablecoinAddress = _addresses[STABLECOIN];

        if (stablecoinAddress == address(0)) {
            revert Errors.PPP__StablecoinNotSet();
        }

        InitializableImmutableAdminUpgradeabilityProxy proxy;

        bytes memory params = abi.encodeWithSignature(
            "initialize(address,address)",
            address(this),
            stablecoinAddress
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

    //   /**
    //    * @dev Possible future development
    //    * @notice Updates the version of the Processor.
    //    * @param newVersionId The new version id of the Processor
    //    */
    //   function _setVersionId(string memory newVersionId) internal {
    //     string memory oldVersionId = _versionId;
    //     _versionId = newVersionId;
    //     emit VersionIdSet(oldVersionId, newVersionId);
    //   }
}
