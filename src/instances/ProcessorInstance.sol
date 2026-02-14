// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Processor} from "../protocol/processor/Processor.sol";
import {IProcessorAddressesProvider} from "../interfaces/IProcessorAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title Payment Processor Instance
 * @author mhng
 * @notice Instance of the Payment Processor
 */
contract ProcessorInstance is Processor {
    uint256 public constant PROCESSOR_REVISION = 1;

    constructor(
        IProcessorAddressesProvider provider,
        address _usdc,
        uint256 _initialAmount
    ) Processor(provider, _usdc, _initialAmount) {}

    /**
     * @notice Initializes the Processor.
     * @dev Function is invoked by the proxy contract when the Processor contract is added to the
     * ProcessorAddressesProvider.
     * @dev The passed ProcessorAddressesProvider is validated against the PROCESSOR.ADDRESSES_PROVIDER, to ensure the upgrade is done with correct intention.
     * @param provider The address of the ProcessorAddressesProvider
     */
    function initialize(
        IProcessorAddressesProvider provider
    ) external virtual override initializer {
        require(
            address(provider) == address(ADDRESSES_PROVIDER),
            Errors.PPP_InvalidAddressesProvider()
        );
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return PROCESSOR_REVISION;
    }
}
