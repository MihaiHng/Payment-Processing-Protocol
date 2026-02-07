// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IProcessorAddressesProvider
 * @author mhng
 * @notice Defines the basic interface for a Processor Address Provider.
 */
interface IProcessorAddressProvider {
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);
    event PoolUpdated(address indexed oldImpl, address indexed newImpl);
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

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMarketId() external view returns (string memory);

    function getAddress(bytes32 id) external view returns (address);

    function getPool() external view returns (address);

    function setMarketId(string memory newMarketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setPoolImpl(address newPoolImpl) external;
}
