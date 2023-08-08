# IMuteSwitchRouterDynamic







## Functions
### WETH
```solidity
function WETH(
) external returns (address)
```




### factory
```solidity
function factory(
) external returns (address)
```




### addLiquidity
```solidity
function addLiquidity(
  address tokenA,
  address tokenB,
  uint256 amountADesired,
  uint256 amountBDesired,
  uint256 amountAMin,
  uint256 amountBMin,
  address to,
  uint256 deadline,
  uint256 feeType,
  bool stable
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`tokenA` | address | 
|`tokenB` | address | 
|`amountADesired` | uint256 | 
|`amountBDesired` | uint256 | 
|`amountAMin` | uint256 | 
|`amountBMin` | uint256 | 
|`to` | address | 
|`deadline` | uint256 | 
|`feeType` | uint256 | 
|`stable` | bool | 


### addLiquidityETH
```solidity
function addLiquidityETH(
  address token,
  uint256 amountTokenDesired,
  uint256 amountTokenMin,
  uint256 amountETHMin,
  address to,
  uint256 deadline,
  uint256 feeType,
  bool stable
) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`token` | address | 
|`amountTokenDesired` | uint256 | 
|`amountTokenMin` | uint256 | 
|`amountETHMin` | uint256 | 
|`to` | address | 
|`deadline` | uint256 | 
|`feeType` | uint256 | 
|`stable` | bool | 


### removeLiquidity
```solidity
function removeLiquidity(
  address tokenA,
  address tokenB,
  uint256 liquidity,
  uint256 amountAMin,
  uint256 amountBMin,
  address to,
  uint256 deadline,
  bool stable
) external returns (uint256 amountA, uint256 amountB)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`tokenA` | address | 
|`tokenB` | address | 
|`liquidity` | uint256 | 
|`amountAMin` | uint256 | 
|`amountBMin` | uint256 | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool | 


### removeLiquidityETH
```solidity
function removeLiquidityETH(
  address token,
  uint256 liquidity,
  uint256 amountTokenMin,
  uint256 amountETHMin,
  address to,
  uint256 deadline,
  bool stable
) external returns (uint256 amountToken, uint256 amountETH)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`token` | address | 
|`liquidity` | uint256 | 
|`amountTokenMin` | uint256 | 
|`amountETHMin` | uint256 | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool | 


### removeLiquidityETHSupportingFeeOnTransferTokens
```solidity
function removeLiquidityETHSupportingFeeOnTransferTokens(
  address token,
  uint256 liquidity,
  uint256 amountTokenMin,
  uint256 amountETHMin,
  address to,
  uint256 deadline,
  bool stable
) external returns (uint256 amountETH)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`token` | address | 
|`liquidity` | uint256 | 
|`amountTokenMin` | uint256 | 
|`amountETHMin` | uint256 | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool | 


### swapExactTokensForTokens
```solidity
function swapExactTokensForTokens(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external returns (uint256[] amounts)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### swapExactETHForTokens
```solidity
function swapExactETHForTokens(
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external returns (uint256[] amounts)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### swapExactTokensForETH
```solidity
function swapExactTokensForETH(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external returns (uint256[] amounts)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### swapExactETHForTokensSupportingFeeOnTransferTokens
```solidity
function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### swapExactTokensForETHSupportingFeeOnTransferTokens
```solidity
function swapExactTokensForETHSupportingFeeOnTransferTokens(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### swapExactTokensForTokensSupportingFeeOnTransferTokens
```solidity
function swapExactTokensForTokensSupportingFeeOnTransferTokens(
  uint256 amountIn,
  uint256 amountOutMin,
  address[] path,
  address to,
  uint256 deadline,
  bool[] stable
) external
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`amountOutMin` | uint256 | 
|`path` | address[] | 
|`to` | address | 
|`deadline` | uint256 | 
|`stable` | bool[] | 


### quote
```solidity
function quote(
  uint256 amountA,
  uint256 reserveA,
  uint256 reserveB
) external returns (uint256 amountB)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountA` | uint256 | 
|`reserveA` | uint256 | 
|`reserveB` | uint256 | 


### getAmountOut
```solidity
function getAmountOut(
  uint256 amountIn,
  address tokenIn,
  address tokenOut
) external returns (uint256 amountOut, bool stable, uint256 fee)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`tokenIn` | address | 
|`tokenOut` | address | 


### getAmountsOutExpanded
```solidity
function getAmountsOutExpanded(
  uint256 amountIn,
  address[] path
) external returns (uint256[] amounts, bool[] stable, uint256[] fees)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`path` | address[] | 


### getAmountsOut
```solidity
function getAmountsOut(
  uint256 amountIn,
  address[] path,
  bool[] stable
) external returns (uint256[] amounts, bool[] _stable, uint256[] fees)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`amountIn` | uint256 | 
|`path` | address[] | 
|`stable` | bool[] | 


### getPairInfo
```solidity
function getPairInfo(
  address[] path,
  bool stable
) external returns (address tokenA, address tokenB, address pair, uint256 reserveA, uint256 reserveB, uint256 fee)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`path` | address[] | 
|`stable` | bool | 


### pairFor
```solidity
function pairFor(
  address tokenA,
  address tokenB,
  bool stable
) external returns (address pair)
```


#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`tokenA` | address | 
|`tokenB` | address | 
|`stable` | bool | 


