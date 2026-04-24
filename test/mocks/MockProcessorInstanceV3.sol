// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Processor} from "../../src/protocol/processor/Processor.sol";
import {IProcessorAddressesProvider} from "../../src/interfaces/IProcessorAddressesProvider.sol";
import {Errors} from "../../src/libraries/helpers/Errors.sol";
import {DataTypes} from "../../src/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ProcessorInstanceV3
 * @notice Mock V3 implementation for testing upgrades
 */
contract MockProcessorInstanceV3 is Processor {
    uint256 public constant PROCESSOR_REVISION = 3;

    constructor(IProcessorAddressesProvider provider) Processor(provider) {}

    /**
     * @notice Initializes the Processor with the addresses provider address and the set stablecoin address.
     * @dev Function is invoked by the proxy contract when the Processor contract is added to the
     * ProcessorAddressesProvider.
     * @dev The passed ProcessorAddressesProvider is validated against the PROCESSOR.ADDRESSES_PROVIDER, to ensure the upgrade is done with correct intention.
     * @param _provider The address of the ProcessorAddressesProvider
     */
    function initialize(
        IProcessorAddressesProvider _provider
    ) external virtual override versionedInitializer {
        if (address(_provider) != address(ADDRESSES_PROVIDER)) {
            revert Errors.PPP__InvalidAddressesProvider();
        }

        DataTypes.SellerConfiguration memory config = _provider
            .getConfiguration();

        _transferOwnership(_provider.owner());

        stablecoin = IERC20(config.stablecoin);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return PROCESSOR_REVISION;
    }

    function v3Feature() external pure returns (string memory) {
        return "I am V3!";
    }
}
