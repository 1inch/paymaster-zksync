<div align="center">
    <img src=".github/1inch_github_w.svg#gh-light-mode-only">
    <img src=".github/1inch_github_b.svg#gh-dark-mode-only">
</div>

# Paymaster ZkSync

[![Build Status](https://github.com/1inch/paymaster-zksync/workflows/CI/badge.svg)](https://github.com/1inch/paymaster-zksync/actions)

Paymaster - this is a contract designed to pay transaction fees using any tokens through the 1inch. This allows users to pay fees not only in ETH, but also in other tokens, making an automatic exchange for the required amount of ETH in 1inch. This provides more flexible and convenient payment mechanisms for users.

## Contract Overview

- **Purpose**: The contract serves to allow users to execute token transfers or token exchanges while paying for gas fees with tokens instead of ETH.
- **Main Components**:
  - `Paymaster`: Manages the fee payment for gas in tokens.
  - `Bootloader`: Default management contract for Paymaster functionality in zksync.
  - `AggregationRouter`: Responsible for exchange user tokens for gas fee to ETH.

## Setup & Deployment

This repository is designed for demonstration and test purposes and is optimized for use within a ZkSync mainnet fork. However, its applications are not limited to this context.

1. Before you begin, you must be connected to the correct zksync fork node. Detailed instructions can be found at [ZKSync Era Test Node](https://github.com/matter-labs/era-test-node). You need set env variable `process.env.ZKSYNC_WEB3_API_URL` with node url.
   ```
   # Example of ZKSYNC_WEB3_API_URL in .env file
   ZKSYNC_WEB3_API_URL=http://localhost:8011
   ```
2. **Rich Wallet:** To run the test, you'll need an address with a good amount of ETH. These addresses can be found in the logs of the era-test-node. Use it in `process.env.ZKSYNC_PRIVATE_KEY`.
   ```
   # Example of ZKSYNC_PRIVATE_KEY in .env file
   ZKSYNC_PRIVATE_KEY=7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110
   ```

## Testing

**Test Execution:** 
```
yarn && yarn test:fork
```
   
**Main Operations:**
- The test will initialize contracts like `Paymaster`, `AggregationRouter` and various token contracts.
- Tokens will be bought via MuteSwitch exchange.
- A token-to-ETH swap will be simulated to cover the fee payment in the paymaster.
- A main operation of token transfer between two wallets will be conducted.
- At the end, balances of different wallets and tokens are printed and verified.

## Using Paymaster for Your Purposes

You can utilize this Paymaster for any of your needs, not just for transferring tokens from one address to another. Relying on the test, you can build your own calldata for the 1inch AggregationRouter to exchange any tokens for ETH as a transaction fee. The required number of tokens for the exchange should be calculated offchain in advance. Any surplus will be returned to the address in ETH currency.
