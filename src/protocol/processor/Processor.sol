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

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Payment Processor
 * @author mhng
 * @notice 'usdc' and 'amount' can be included in a ProcessorConfiguration file in future developments, which will allow more modularity and flexibility
 */
abstract contract Processor is
    VersionedInitializable,
    Processor_Storage,
    IProcessor,
    Ownable,
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
    modifier onlyPaymentProcessor() {
        require(msg.sender == owner(), Errors.PPP__CallerNotProcessor());
        _;
    }

    constructor(
        IProcessorAddressesProvider provider,
        address _usdc,
        uint256 _initialAmount
    ) Ownable(msg.sender) {
        ADDRESSES_PROVIDER = provider;

        if (_usdc == address(0)) {
            revert Errors.PPP__InvalidAddress();
        }
        usdc = IERC20(_usdc);

        if (_initialAmount > 0) {
            usdc.safeTransferFrom(msg.sender, address(this), _initialAmount);
            totalBalance = _initialAmount;
        }
    }

    // receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the Processor.
     * @dev Function is invoked by the proxy contract when the Processor contract is added to the
     * ProcessorAddressesProvider.
     * @dev Caching the address of the ProcessorAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param provider The address of the ProcessorAddressesProvider
     */
    function initialize(IProcessorAddressesProvider provider) external virtual;

    /// @inheritdoc IProcessor
    function fundProcessor(
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        totalBalance = FundProcessorLogic.executeFundProcessor(
            usdc,
            amount,
            totalBalance
        );
    }

    function withdrawFromProcessor(
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        totalBalance = WithdrawProcessorLogic.executeWithdrawFromProcessor(
            usdc,
            amount,
            totalBalance
        );
    }

    function withdrawAllFromProcessor()
        external
        virtual
        override
        nonReentrant
        onlyOwner
    {
        totalBalance = WithdrawProcessorLogic.executeWithdrawAllFromProcessor(
            usdc
        );
    }

    function extractPaymentData()
        external
        virtual
        override
        nonReentrant
        onlyOwner
        returns (DataTypes.PaymentData memory paymentData)
    {}

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
    /**
     * @notice Get the current balance of the processor
     */
    function getBalance() external view returns (uint256) {
        return totalBalance;
    }

    /**
     * @notice Get the actual USDC balance in the contract (for verification)
     */
    function getActualBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
