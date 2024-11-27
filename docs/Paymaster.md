# Solidity API

## Paymaster

_This contract is an implementation of the IPaymaster interface that enables paying transaction fees with any tokens using 1inch._

### InvalidSender

```solidity
error InvalidSender()
```

### FailedTransferFrom

```solidity
error FailedTransferFrom()
```

### BootloaderTransferFailed

```solidity
error BootloaderTransferFailed()
```

### UnsupportedFlow

```solidity
error UnsupportedFlow()
```

### InvalidInputLength

```solidity
error InvalidInputLength()
```

### bootloader

```solidity
address bootloader
```

The address of the bootloader contract.

### exchange

```solidity
address exchange
```

The address of the 1inch AggregationRouter contract.

### constructor

```solidity
constructor(address bootloader_, address exchange_) public
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| bootloader_ | address | The address of the bootloader contract. |
| exchange_ | address | The address of the 1inch AggregationRouter contract. |

### validateAndPayForPaymasterTransaction

```solidity
function validateAndPayForPaymasterTransaction(bytes32, bytes32, struct Transaction _transaction) external payable returns (bytes4 magic, bytes context)
```

Validates, swaps tokens for ETH to pay gas fees using 1inch and pays for the transaction.

_It checks the validity of the transaction, decodes the paymasterInput to extract token details and make a token swap on 1inch._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | bytes32 |  |
|  | bytes32 |  |
| _transaction | struct Transaction | The transaction object including the token details and 1inch exchange data. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| magic | bytes4 | Returns PAYMASTER_VALIDATION_SUCCESS_MAGIC if successful. |
| context | bytes |  |

### postTransaction

```solidity
function postTransaction(bytes, struct Transaction _transaction, bytes32, bytes32, enum ExecutionResult, uint256) external payable
```

Transfers the remaining ETH balance of the Paymaster back to the user after a transaction has been executed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | bytes |  |
| _transaction | struct Transaction | The transaction object. |
|  | bytes32 |  |
|  | bytes32 |  |
|  | enum ExecutionResult |  |
|  | uint256 |  |

### receive

```solidity
receive() external payable
```

Allows the contract to accept incoming Ether.

