// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Processor} from "../../src/protocol/processor/Processor.sol";
import {IProcessorAddressesProvider} from "../../src/interfaces/IProcessorAddressesProvider.sol";
import {Errors} from "../../src/libraries/helpers/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ProcessorInstanceV2
 * @notice Mock V2 implementation for testing upgrades
 */
contract MockProcessorInstanceV2 is Processor {
    uint256 public constant PROCESSOR_REVISION = 2;

    constructor(IProcessorAddressesProvider provider) Processor(provider) {}

    /**
     * @notice Initializes the Processor with the addresses provider address and the set stablecoin address.
     * @dev Function is invoked by the proxy contract when the Processor contract is added to the
     * ProcessorAddressesProvider.
     * @dev The passed ProcessorAddressesProvider is validated against the PROCESSOR.ADDRESSES_PROVIDER, to ensure the upgrade is done with correct intention.
     * @param _provider The address of the ProcessorAddressesProvider
     * @param _stablecoin The stablecoin address (USDC, USDT, DAI, etc.)
     */
    function initialize(
        IProcessorAddressesProvider _provider,
        address _stablecoin
    ) external virtual override initializer {
        if (address(_provider) != address(ADDRESSES_PROVIDER)) {
            revert Errors.PPP__InvalidAddressesProvider();
        }

        if (_stablecoin == address(0)) {
            revert Errors.PPP__InvalidStablecoin();
        }

        stablecoin = IERC20(_stablecoin);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return PROCESSOR_REVISION;
    }
}
