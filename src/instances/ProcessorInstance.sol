// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Processor} from "../protocol/processor/Processor.sol";
import {IProcessorAddressesProvider} from "../interfaces/IProcessorAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ProcessorInstance
 * @author mhng
 * @notice Concrete implementation of the Payment Processor
 * @dev Deploy this and register with setProcessorImpl()
 */
contract ProcessorInstance is Processor {
    uint256 public constant PROCESSOR_REVISION = 1;

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
        if (config.stablecoin == address(0)) {
            revert Errors.PPP__StablecoinNotSet();
        }
        if (config.seller == address(0)) {
            revert Errors.PPP__SellerNotSet();
        }
        if (config.nftContract == address(0)) {
            revert Errors.PPP__NFTContractNotSet();
        }

        // aderyn-ignore-next-line(reentrancy-state-change)
        _transferOwnership(_provider.owner());

        stablecoin = IERC20(config.stablecoin);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return PROCESSOR_REVISION;
    }
}
