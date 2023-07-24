// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Pair Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract MuteSwitchFeeVault {

    address internal immutable _pair; // The pair it is bonded to
    address internal immutable _token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable _token1; // Token1 of pair, saved localy and statically for gas optimization

    constructor(address token0_, address token1_) {
        _pair = msg.sender;
        _token0 = token0_;
        _token1 = token1_;
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0); // solhint-disable-line reason-string
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value)); // solhint-disable-line avoid-low-level-calls
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // solhint-disable-line reason-string
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint amount0, uint amount1) external {
        require(msg.sender == _pair); // solhint-disable-line reason-string
        if (amount0 > 0) _safeTransfer(_token0, recipient, amount0);
        if (amount1 > 0) _safeTransfer(_token1, recipient, amount1);
    }

}
