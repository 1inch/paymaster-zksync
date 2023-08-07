# Paymaster ZkSync

[![Build Status](https://github.com/1inch/paymaster-zksync/workflows/CI/badge.svg)](https://github.com/1inch/paymaster-zksync/actions)
[![Coverage Status](https://codecov.io/gh/1inch/paymaster-zksync/branch/master/graph/badge.svg?token=JA2Z2CABZZ)](https://codecov.io/gh/1inch/paymaster-zksync)


This repository provides implementation of ZKSync Paymaster, which designed to allow transaction fees to be paid using custom tokens, by leveraging the 1inch Aggregation Protocol, and tests which show example to use it. 

## Setup
To run these tests, you need to follow these steps:

1. Set up your own zksync fork node. You can follow the instructions given in [era-test-node](https://github.com/matter-labs/era-test-node).
2. Run your own zksync fork node with port 3050, as it is hardcoded in the zksync provider library
   ```
   era_test_node --port 3050 fork mainnet
   ```
3. Clone the repository
   ```
   git clone https://github.com/1inch/paymaster-zksync.git
   ```
4. Install the required dependencies
   ```
   yarn install
   ```
5. Use one of the rich wallets with some ETH from zksync fork node logs, and set its private key as the `ZKSYNC_PRIVATE_KEY` environment variable. For example, in `.env` file of repo dir.

## Running the Tests
To run the test suite, you can use the following command:
```
yarn test:fork
```
Please note that these tests are designed to be run on the zksync, and it is not function correctly if run on the Ethereum mainnet or any else EthereumLike networks.

## Tests description
### Test Case Name: should swap and pay gas fees with paymaster
This test verifies the functionality of the ZKSync Paymaster contract when it is used to pay gas fees in tokens other than ETH. It simulates a real-world scenario where a user wants to pay gas fees using USDC tokens instead of ETH for transfering funds to different wallet.

The test follows these steps:
1. Initializes the test environment by setting up necessary contracts and tokens, and purchases some tokens for the test wallet.
2. Approves the Paymaster contract to spend a specified amount of USDC tokens from the user's wallet. This amount will be used to cover the transaction fees.
3. Constructs a token-to-ETH swap operation, which converts a portion of the USDC tokens into ETH. This ETH will be used to pay the gas fees for the transaction. It should be calculated in advance offchain.
4. Submits the swap operation along with the transaction, embedded as `customData` during the USDC transfer.
5. Tracks the balances of the involved wallets and contracts before and after the transaction. This includes the user's wallet, the Paymaster contract, and a random receiver account. As a result, a user who sends tokens to a random address does not spend ETH and sends USDC. No more than 10 percent of the transaction fee spents remains on the Paymaster contract.
