// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.33;

import {Processor_Storage} from "./Processor_Storage.sol";
import {FundProcessorLogic} from "../../libraries/logic/FundProcessorLogic.sol";
import {WithdrawProcessorLogic} from "../../libraries/logic/WithdrawProcessorLogic.sol";
import {IProcessor} from "../../interfaces/IProcessor.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {IProcessorAddressesProvider} from "../../interfaces/IProcessorAddressesProvider.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../../misc/upgradeability/VersionedInitializable.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Payment Processor
 * @author mhng
 * @dev Supports any ERC20 stablecoin (USDC, USDT, DAI, etc.)
 */
abstract contract Processor is
    VersionedInitializable,
    Processor_Storage,
    IProcessor,
    OwnableUpgradeable,
    ReentrancyGuard
{
    /*//////////////////////////////////////////////////////////////
                          TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;
    using FundProcessorLogic for IERC20;
    using WithdrawProcessorLogic for IERC20;

    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IProcessorAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    // modifier onlyPaymentProcessor() {
    //     require(msg.sender == owner(), Errors.PPP__CallerNotProcessor());
    //     _;
    // }

    constructor(IProcessorAddressesProvider provider) /*Ownable(msg.sender)*/ {
        ADDRESSES_PROVIDER = provider;
    }

    // receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the Processor with the addresses provider address and the set stablecoin address.
     * @dev Function is invoked by the proxy contract when the Processor contract is added to the
     * ProcessorAddressesProvider.
     * @dev Caching the address of the ProcessorAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param _provider The address of the ProcessorAddressesProvider
     * @param _stablecoin The stablecoin address (USDC, USDT, DAI, etc.)
     */
    function initialize(
        IProcessorAddressesProvider _provider,
        address _stablecoin
    ) external virtual;

    /// @inheritdoc IProcessor
    function fundProcessor(
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        if (address(stablecoin) == address(0)) {
            revert Errors.PPP__StablecoinNotSet();
        }
        totalBalance = FundProcessorLogic.executeFundProcessor(
            stablecoin,
            amount,
            totalBalance
        );
    }

    /// @inheritdoc IProcessor
    function withdrawFromProcessor(
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        totalBalance = WithdrawProcessorLogic.executeWithdrawFromProcessor(
            stablecoin,
            amount,
            totalBalance
        );
    }

    /// @inheritdoc IProcessor
    function withdrawAllFromProcessor()
        external
        virtual
        override
        nonReentrant
        onlyOwner
    {
        totalBalance = WithdrawProcessorLogic.executeWithdrawAllFromProcessor(
            stablecoin
        );
    }

    /// @inheritdoc IProcessor
    function extractPaymentData()
        external
        virtual
        override
        nonReentrant
        onlyOwner
        returns (DataTypes.PaymentData memory paymentData)
    {}

    /// @inheritdoc IProcessor
    function processPayment(
        uint256 paymentId,
        address seller,
        uint256 buyer,
        address item,
        uint256 price
    ) external virtual override nonReentrant onlyOwner returns (bool) {}

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        GETTER/VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IProcessor
    function getBalance() external view virtual override returns (uint256) {
        return totalBalance;
    }

    /// @inheritdoc IProcessor
    function getActualBalance()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return stablecoin.balanceOf(address(this));
    }

    /// @inheritdoc IProcessor
    function getStablecoin() external view virtual override returns (address) {
        return address(stablecoin);
    }
}
