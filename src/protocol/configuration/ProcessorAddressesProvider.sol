// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {IProcessor} from "../../interfaces/IProcessor.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../../misc/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title ProcessorAddressesProvider
 * @author mhng
 * @notice Main registry and configuration for the Payment Processor Protocol
 * @dev Stores seller configuration and manages Processor proxy deployment/upgrades
 */
contract ProcessorAddressesProvider is Ownable, IProcessorAddressesProvider {
    // Identifier for different Processor versions on the same chain -> possible future development
    // string private _versionId;

    // Map of registered addresses (identifier => registeredAddress)
    mapping(bytes32 => address) private _addresses;

    /// @dev Seller platform configuration
    DataTypes.SellerConfiguration private _configuration;

    // Main identifiers
    bytes32 private constant PROCESSOR = "PROCESSOR";

    // Future modules:
    // bytes32 private constant FEE_MANAGER = "FEE_MANAGER";
    // bytes32 private constant PROCESSOR_CONFIGURATOR = "PROCESSOR_CONFIGURATOR";

    /**
     * @notice Initialize the AddressesProvider
     * @param initOwner The owner address of this contract.
     */
    constructor(
        address initOwner /*, string memory versionId*/
    ) Ownable(initOwner) {
        // _setVersionId(versionId); // Possible future development, different processor for different projects and needs
    }

    /*//////////////////////////////////////////////////////////////
                    CONFIGURATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProcessorAddressesProvider
    function setConfiguration(
        address seller,
        address nftContract,
        address stablecoin
    ) external override onlyOwner {
        _configuration = DataTypes.SellerConfiguration({
            seller: seller,
            nftContract: nftContract,
            stablecoin: stablecoin
        });

        emit ConfigurationUpdated(seller, nftContract, stablecoin);
    }

    /// @inheritdoc IProcessorAddressesProvider
    function setStablecoin(address newStablecoin) external override onlyOwner {
        address oldStablecoin = _configuration.stablecoin;
        _configuration.stablecoin = newStablecoin;
        emit StablecoinUpdated(oldStablecoin, newStablecoin);
    }

    /// @inheritdoc IProcessorAddressesProvider
    function setSeller(address newSeller) external override onlyOwner {
        address oldSeller = _configuration.seller;
        _configuration.seller = newSeller;
        emit SellerUpdated(oldSeller, newSeller);
    }

    /// @inheritdoc IProcessorAddressesProvider
    function setNFTContract(
        address newNFTContract
    ) external override onlyOwner {
        address oldNFT = _configuration.nftContract;
        _configuration.nftContract = newNFTContract;
        emit NFTContractUpdated(oldNFT, newNFTContract);
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
        address stablecoinAddress = _configuration.stablecoin;

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
    function getConfiguration()
        external
        view
        override
        returns (DataTypes.SellerConfiguration memory)
    {
        return _configuration;
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getStablecoin() external view override returns (address) {
        return _configuration.stablecoin;
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getSeller() external view override returns (address) {
        return _configuration.seller;
    }

    /// @inheritdoc IProcessorAddressesProvider
    function getNFTContract() external view override returns (address) {
        return _configuration.nftContract;
    }
}
