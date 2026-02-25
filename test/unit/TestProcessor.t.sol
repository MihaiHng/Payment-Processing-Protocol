// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

// import {BaseTest} from "../BaseTest.t.sol";
// import {Errors} from "../../src/libraries/helpers/Errors.sol";

// contract ProcessorTest is BaseTest {
//     /*//////////////////////////////////////////////////////////////
//                               EVENTS
//     //////////////////////////////////////////////////////////////*/

//     event ProcessorFunded(
//         address indexed funder,
//         uint256 amount,
//         uint256 newBalance
//     );
//     event ProcessorWithdraw(
//         address indexed to,
//         uint256 amount,
//         uint256 newBalance
//     );

//     /*//////////////////////////////////////////////////////////////
//                           INITIALIZATION TESTS
//     //////////////////////////////////////////////////////////////*/

//     function test_Initialize_SetsStablecoin() public view {
//         assertEq(processor().getStablecoin(), address(usdc));
//     }

//     function test_Initialize_StartsWithZeroBalance() public view {
//         assertProcessorBalance(0);
//     }

//     function test_Initialize_AddressesProviderIsSet() public view {
//         assertEq(
//             address(processor().ADDRESSES_PROVIDER()),
//             address(addressesProvider)
//         );
//     }

//     /*//////////////////////////////////////////////////////////////
//                         FUND PROCESSOR TESTS
//     //////////////////////////////////////////////////////////////*/

//     function test_FundProcessor_IncreasesBalance() public asOwner {
//         usdc.approve(processorProxy, FUND_AMOUNT);

//         processor().fundProcessor(FUND_AMOUNT);

//         assertProcessorBalance(FUND_AMOUNT);
//         assertProcessorActualBalance(FUND_AMOUNT);
//     }

//     function test_FundProcessor_TransfersUSDC() public asOwner {
//         uint256 ownerBalanceBefore = usdc.balanceOf(owner);

//         usdc.approve(processorProxy, FUND_AMOUNT);
//         processor().fundProcessor(FUND_AMOUNT);

//         assertEq(usdc.balanceOf(owner), ownerBalanceBefore - FUND_AMOUNT);
//         assertEq(usdc.balanceOf(processorProxy), FUND_AMOUNT);
//     }

//     function test_FundProcessor_MultipleFunds() public asOwner {
//         usdc.approve(processorProxy, FUND_AMOUNT * 3);

//         processor().fundProcessor(FUND_AMOUNT);
//         processor().fundProcessor(FUND_AMOUNT);
//         processor().fundProcessor(FUND_AMOUNT);

//         assertProcessorBalance(FUND_AMOUNT * 3);
//     }

//     function test_FundProcessor_RevertsIfNotOwner() public asUnauthorized {
//         usdc.mint(unauthorized, FUND_AMOUNT);
//         usdc.approve(processorProxy, FUND_AMOUNT);

//         vm.expectRevert();
//         processor().fundProcessor(FUND_AMOUNT);
//     }

//     function test_FundProcessor_RevertsIfZeroAmount() public asOwner {
//         vm.expectRevert(Errors.PPP_InvalidAmount.selector);
//         processor().fundProcessor(0);
//     }

//     function test_FundProcessor_RevertsIfInsufficientAllowance()
//         public
//         asOwner
//     {
//         // No approval given
//         vm.expectRevert();
//         processor().fundProcessor(FUND_AMOUNT);
//     }

//     function test_FundProcessor_RevertsIfInsufficientBalance() public {
//         address poorUser = makeAddr("poorUser");

//         // Transfer ownership to poorUser for this test
//         vm.prank(owner);
//         // Note: You'd need transferOwnership function
//         // processor().transferOwnership(poorUser);

//         // For now, just test with owner who has no USDC
//         vm.startPrank(owner);
//         usdc.transfer(user1, usdc.balanceOf(owner)); // Send all USDC away
//         usdc.approve(processorProxy, FUND_AMOUNT);

//         vm.expectRevert();
//         processor().fundProcessor(FUND_AMOUNT);
//         vm.stopPrank();
//     }

//     /*//////////////////////////////////////////////////////////////
//                       WITHDRAW PROCESSOR TESTS
//     //////////////////////////////////////////////////////////////*/

//     function test_WithdrawFromProcessor_DecreasesBalance() public {
//         // First fund the processor
//         _fundProcessor(FUND_AMOUNT);

//         // Then withdraw
//         vm.prank(owner);
//         processor().withdrawFromProcessor(FUND_AMOUNT / 2);

//         assertProcessorBalance(FUND_AMOUNT / 2);
//     }

//     function test_WithdrawFromProcessor_TransfersUSDC() public {
//         _fundProcessor(FUND_AMOUNT);

//         uint256 ownerBalanceBefore = usdc.balanceOf(owner);

//         vm.prank(owner);
//         processor().withdrawFromProcessor(FUND_AMOUNT);

//         assertEq(usdc.balanceOf(owner), ownerBalanceBefore + FUND_AMOUNT);
//         assertEq(usdc.balanceOf(processorProxy), 0);
//     }

//     function test_WithdrawFromProcessor_RevertsIfNotOwner() public {
//         _fundProcessor(FUND_AMOUNT);

//         vm.prank(unauthorized);
//         vm.expectRevert();
//         processor().withdrawFromProcessor(FUND_AMOUNT);
//     }

//     function test_WithdrawFromProcessor_RevertsIfInsufficientBalance() public {
//         _fundProcessor(FUND_AMOUNT);

//         vm.prank(owner);
//         vm.expectRevert(); // Should revert with PPP_InsufficientBalance or similar
//         processor().withdrawFromProcessor(FUND_AMOUNT * 2);
//     }

//     /*//////////////////////////////////////////////////////////////
//                     WITHDRAW ALL PROCESSOR TESTS
//     //////////////////////////////////////////////////////////////*/

//     function test_WithdrawAllFromProcessor_WithdrawsEntireBalance() public {
//         _fundProcessor(FUND_AMOUNT);

//         vm.prank(owner);
//         processor().withdrawAllFromProcessor();

//         assertProcessorBalance(0);
//         assertProcessorActualBalance(0);
//     }

//     function test_WithdrawAllFromProcessor_TransfersAllUSDC() public {
//         _fundProcessor(FUND_AMOUNT);

//         uint256 ownerBalanceBefore = usdc.balanceOf(owner);

//         vm.prank(owner);
//         processor().withdrawAllFromProcessor();

//         assertEq(usdc.balanceOf(owner), ownerBalanceBefore + FUND_AMOUNT);
//     }

//     function test_WithdrawAllFromProcessor_RevertsIfNotOwner() public {
//         _fundProcessor(FUND_AMOUNT);

//         vm.prank(unauthorized);
//         vm.expectRevert();
//         processor().withdrawAllFromProcessor();
//     }

//     function test_WithdrawAllFromProcessor_RevertsIfZeroBalance()
//         public
//         asOwner
//     {
//         vm.expectRevert(); // Should revert with PPP_ZeroBalance or similar
//         processor().withdrawAllFromProcessor();
//     }

//     /*//////////////////////////////////////////////////////////////
//                           VIEW FUNCTION TESTS
//     //////////////////////////////////////////////////////////////*/

//     function test_GetBalance_ReturnsTrackedBalance() public {
//         _fundProcessor(FUND_AMOUNT);
//         assertEq(processor().getBalance(), FUND_AMOUNT);
//     }

//     function test_GetActualBalance_ReturnsRealUSDCBalance() public {
//         _fundProcessor(FUND_AMOUNT);
//         assertEq(
//             processor().getActualBalance(),
//             usdc.balanceOf(processorProxy)
//         );
//     }

//     function test_GetStablecoin_ReturnsUSDCAddress() public view {
//         assertEq(processor().getStablecoin(), address(usdc));
//     }
// }
