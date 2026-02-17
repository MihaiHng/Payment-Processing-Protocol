// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Test, console, console2} from "forge-std/Test.sol";

contract ProcessorForkTest is Test {
    ProcessorAddressesProvider addressesProvider;
    address processorProxy;

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant USDC_WHALE = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;

    function setUp() public {
        // Fork mainnet - real USDC exists!
        vm.createSelectFork({blockNumber: 18_377_723, urlOrAlias: "mainnet"});

        // Deploy your protocol
        addressesProvider = new ProcessorAddressesProvider(address(this));
        addressesProvider.setStablecoin(address(USDC));

        ProcessorInstance impl = new ProcessorInstance(
            IProcessorAddressesProvider(address(addressesProvider))
        );
        addressesProvider.setProcessorImpl(address(impl));

        processorProxy = addressesProvider.getProcessor();
    }

    function test_FundWithRealUSDC() public {
        uint256 amount = 10_000e6; // 10k USDC

        // Get USDC from whale
        vm.startPrank(USDC_WHALE);
        USDC.transfer(address(this), amount);
        vm.stopPrank();

        // Fund processor with real USDC
        USDC.approve(processorProxy, amount);
        IProcessor(processorProxy).fundProcessor(amount);

        assertEq(IProcessor(processorProxy).getBalance(), amount);
    }
}
