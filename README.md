[README.md](https://github.com/user-attachments/files/32580834/README.md)
# Reusable Multi-Recipient ETH Payment Contract

A small, reusable Solidity smart-contract primitive for distributing ETH to multiple recipients in a single transaction.

## Purpose

This contract can be reused for:

- contributor payouts
- grants and rewards
- team distributions
- community incentives
- batch payment workflows

The implementation intentionally avoids frontend logic and focuses on a clear, auditable on-chain primitive.

## Features

- Batch ETH distribution
- Exact `msg.value` validation
- Recipient and amount validation
- Owner access control
- Safe withdrawal of excess ETH
- Ownership transfer
- Events for payment execution and withdrawals
- Custom errors for efficient validation

## Core logic

`distribute()` receives recipient addresses and matching payment amounts. It first validates the arrays and calculates the total. The transaction is accepted only when `msg.value` exactly equals the calculated total. Each recipient is then paid using a low-level call, and the transaction reverts if a transfer fails.

This keeps payment accounting explicit and prevents accidental underpayment or overpayment.

## Testing

The included Foundry test suite covers:

1. successful multi-recipient payment
2. mismatched array lengths
3. zero recipient address
4. incorrect ETH value
5. owner-only withdrawal
6. ownership transfer

## Important note

This repository is an educational/reusable contract contribution. It should be reviewed and independently audited before being used with meaningful funds in production.

## License

MIT
