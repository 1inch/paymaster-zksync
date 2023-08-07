# IMuteSwitchPairDynamic







## Functions
### name
```solidity
function name(
) external returns (string)
```




### symbol
```solidity
function symbol(
) external returns (string)
```




### decimals
```solidity
function decimals(
) external returns (uint8)
```




### totalSupply
```solidity
function totalSupply(
) external returns (uint256)
```




### stable
```solidity
function stable(
) external returns (bool)
```




### balanceOf
```solidity
function balanceOf(
  address owner
) external returns (uint256)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | 


### allowance
```solidity
function allowance(
  address owner,
  address spender
) external returns (uint256)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | 
|`spender` | address | 


### approve
```solidity
function approve(
  address spender,
  uint256 value
) external returns (bool)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`spender` | address | 
|`value` | uint256 | 


### transfer
```solidity
function transfer(
  address to,
  uint256 value
) external returns (bool)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | address | 
|`value` | uint256 | 


### transferFrom
```solidity
function transferFrom(
  address from,
  address to,
  uint256 value
) external returns (bool)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`from` | address | 
|`to` | address | 
|`value` | uint256 | 


### DOMAIN_SEPARATOR
```solidity
function DOMAIN_SEPARATOR(
) external returns (bytes32)
```




### PERMIT_TYPEHASH
```solidity
function PERMIT_TYPEHASH(
) external returns (bytes32)
```




### nonces
```solidity
function nonces(
  address owner
) external returns (uint256)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | 


### permit
```solidity
function permit(
  address owner,
  address spender,
  uint256 value,
  uint256 deadline,
  bytes sig
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | 
|`spender` | address | 
|`value` | uint256 | 
|`deadline` | uint256 | 
|`sig` | bytes | 


### MINIMUM_LIQUIDITY
```solidity
function MINIMUM_LIQUIDITY(
) external returns (uint256)
```




### factory
```solidity
function factory(
) external returns (address)
```




### token0
```solidity
function token0(
) external returns (address)
```




### token1
```solidity
function token1(
) external returns (address)
```




### getReserves
```solidity
function getReserves(
) external returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
```




### price0CumulativeLast
```solidity
function price0CumulativeLast(
) external returns (uint256)
```




### price1CumulativeLast
```solidity
function price1CumulativeLast(
) external returns (uint256)
```




### kLast
```solidity
function kLast(
) external returns (uint256)
```




### pairFee
```solidity
function pairFee(
) external returns (uint256)
```




### mint
```solidity
function mint(
  address to
) external returns (uint256 liquidity)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | address | 


### burn
```solidity
function burn(
  address to
) external returns (uint256 amount0, uint256 amount1)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | address | 


### swap
```solidity
function swap(
  uint256 amount0Out,
  uint256 amount1Out,
  address to,
  bytes data
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amount0Out` | uint256 | 
|`amount1Out` | uint256 | 
|`to` | address | 
|`data` | bytes | 


### skim
```solidity
function skim(
  address to
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | address | 


### sync
```solidity
function sync(
) external
```




### claimFees
```solidity
function claimFees(
) external returns (uint256 claimed0, uint256 claimed1)
```




### claimFeesView
```solidity
function claimFeesView(
  address recipient
) external returns (uint256 claimed0, uint256 claimed1)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`recipient` | address | 


### initialize
```solidity
function initialize(
  address ,
  address ,
  uint256 ,
  bool 
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`` | address | 
|`` | address | 
|`` | uint256 | 
|`` | bool | 


### getAmountOut
```solidity
function getAmountOut(
  uint256 ,
  address 
) external returns (uint256)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`` | uint256 | 
|`` | address | 


## Events
### Approval
```solidity
event Approval(
  address owner,
  address spender,
  uint256 value
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`owner` | address | 
|`spender` | address | 
|`value` | uint256 | 

### Transfer
```solidity
event Transfer(
  address from,
  address to,
  uint256 value
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`from` | address | 
|`to` | address | 
|`value` | uint256 | 

### Mint
```solidity
event Mint(
  address sender,
  uint256 amount0,
  uint256 amount1
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`sender` | address | 
|`amount0` | uint256 | 
|`amount1` | uint256 | 

### Burn
```solidity
event Burn(
  address sender,
  uint256 amount0,
  uint256 amount1,
  address to
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`sender` | address | 
|`amount0` | uint256 | 
|`amount1` | uint256 | 
|`to` | address | 

### Swap
```solidity
event Swap(
  address sender,
  uint256 amount0In,
  uint256 amount1In,
  uint256 amount0Out,
  uint256 amount1Out,
  address to
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`sender` | address | 
|`amount0In` | uint256 | 
|`amount1In` | uint256 | 
|`amount0Out` | uint256 | 
|`amount1Out` | uint256 | 
|`to` | address | 

### Sync
```solidity
event Sync(
  uint112 reserve0,
  uint112 reserve1
)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`reserve0` | uint112 | 
|`reserve1` | uint112 | 

