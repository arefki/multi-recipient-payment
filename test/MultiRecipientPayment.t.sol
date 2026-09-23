// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MultiRecipientPayment} from "../src/MultiRecipientPayment.sol";

contract MultiRecipientPaymentTest is Test {
    MultiRecipientPayment payment;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        payment = new MultiRecipientPayment();
        vm.deal(address(this), 100 ether);
    }

    function testDistributesETH() public {
        address payable[] memory recipients = new address payable[](2);
        uint256[] memory amounts = new uint256[](2);

        recipients[0] = payable(alice);
        recipients[1] = payable(bob);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        uint256 aliceBefore = alice.balance;
        uint256 bobBefore = bob.balance;

        payment.distribute{value: 3 ether}(recipients, amounts);

        assertEq(alice.balance, aliceBefore + 1 ether);
        assertEq(bob.balance, bobBefore + 2 ether);
    }

    function testRejectsLengthMismatch() public {
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory amounts = new uint256[](2);

        recipients[0] = payable(alice);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.expectRevert(MultiRecipientPayment.LengthMismatch.selector);
        payment.distribute{value: 2 ether}(recipients, amounts);
    }

    function testRejectsZeroRecipient() public {
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory amounts = new uint256[](1);

        recipients[0] = payable(address(0));
        amounts[0] = 1 ether;

        vm.expectRevert(MultiRecipientPayment.ZeroRecipient.selector);
        payment.distribute{value: 1 ether}(recipients, amounts);
    }

    function testRejectsIncorrectMsgValue() public {
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory amounts = new uint256[](1);

        recipients[0] = payable(alice);
        amounts[0] = 2 ether;

        vm.expectRevert(MultiRecipientPayment.InsufficientBalance.selector);
        payment.distribute{value: 1 ether}(recipients, amounts);
    }

    function testOnlyOwnerCanWithdrawExcess() public {
        vm.deal(address(payment), 5 ether);

        vm.prank(alice);
        vm.expectRevert(MultiRecipientPayment.NotOwner.selector);
        payment.withdrawExcess(payable(alice), 1 ether);

        uint256 beforeBalance = address(this).balance;
        payment.withdrawExcess(payable(address(this)), 1 ether);

        assertEq(address(this).balance, beforeBalance + 1 ether);
    }

    function testOwnershipTransfer() public {
        payment.transferOwnership(alice);
        assertEq(payment.owner(), alice);

        vm.prank(alice);
        payment.withdrawExcess(payable(alice), 0);
    }
}
