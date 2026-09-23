// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MultiRecipientPayment
/// @notice Reusable ETH batch-payment primitive for contributors, grants, rewards,
///         and team distributions.
/// @dev The contract intentionally keeps the primitive small and auditable.
contract MultiRecipientPayment {
    address public owner;

    error NotOwner();
    error EmptyRecipients();
    error LengthMismatch();
    error ZeroRecipient();
    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();
    error InvalidNewOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BatchPaymentExecuted(
        address indexed payer,
        uint256 totalAmount,
        uint256 recipientCount
    );
    event ExcessETHWithdrawn(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    receive() external payable {}

    /// @notice Sends the supplied ETH amounts to all recipients in one transaction.
    /// @dev msg.value must exactly equal the sum of all amounts.
    function distribute(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        uint256 length = recipients.length;
        if (length == 0) revert EmptyRecipients();
        if (length != amounts.length) revert LengthMismatch();

        uint256 total;

        for (uint256 i; i < length; ++i) {
            if (recipients[i] == address(0)) revert ZeroRecipient();
            if (amounts[i] == 0) revert ZeroAmount();
            total += amounts[i];
        }

        if (msg.value != total) revert InsufficientBalance();

        for (uint256 i; i < length; ++i) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            if (!success) revert TransferFailed();
        }

        emit BatchPaymentExecuted(msg.sender, total, length);
    }

    /// @notice Withdraws ETH that is not part of a payment.
    function withdrawExcess(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        if (recipient == address(0)) revert ZeroRecipient();
        if (amount > address(this).balance) revert InsufficientBalance();

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit ExcessETHWithdrawn(recipient, amount);
    }

    /// @notice Transfers contract administration to a new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidNewOwner();

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
