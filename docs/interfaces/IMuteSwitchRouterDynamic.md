# Solidity API

## IMuteSwitchRouterDynamic

### WETH

```solidity
function WETH() external view returns (address)
```

### factory

```solidity
function factory() external view returns (address)
```

### addLiquidity

```solidity
function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, uint256 feeType, bool stable) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

### addLiquidityETH

```solidity
function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, uint256 feeType, bool stable) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
```

### removeLiquidity

```solidity
function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool stable) external returns (uint256 amountA, uint256 amountB)
```

### removeLiquidityETH

```solidity
function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool stable) external returns (uint256 amountToken, uint256 amountETH)
```

### removeLiquidityETHSupportingFeeOnTransferTokens

```solidity
function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool stable) external returns (uint256 amountETH)
```

### swapExactTokensForTokens

```solidity
function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external returns (uint256[] amounts)
```

### swapExactETHForTokens

```solidity
function swapExactETHForTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external payable returns (uint256[] amounts)
```

### swapExactTokensForETH

```solidity
function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external returns (uint256[] amounts)
```

### swapExactETHForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external payable
```

### swapExactTokensForETHSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external
```

### swapExactTokensForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline, bool[] stable) external
```

### quote

```solidity
function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB)
```

### getAmountOut

```solidity
function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256 amountOut, bool stable, uint256 fee)
```

### getAmountsOutExpanded

```solidity
function getAmountsOutExpanded(uint256 amountIn, address[] path) external view returns (uint256[] amounts, bool[] stable, uint256[] fees)
```

### getAmountsOut

```solidity
function getAmountsOut(uint256 amountIn, address[] path, bool[] stable) external view returns (uint256[] amounts, bool[] _stable, uint256[] fees)
```

### getPairInfo

```solidity
function getPairInfo(address[] path, bool stable) external view returns (address tokenA, address tokenB, address pair, uint256 reserveA, uint256 reserveB, uint256 fee)
```

### pairFor

```solidity
function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair)
```

