// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import "./mocks/interfaces/IZksyncWETH.sol";

contract Paymaster is IPaymaster {
    error InvalidSender();
    error FailedTransferFrom();
    error BootloaderTransferFailed();
    error UnsupportedFlow();
    error InvalidInputLength();
    error DebugError();

    address immutable public bootloader;
    address immutable public exchange;
    IZksyncWETH immutable public weth;

    constructor(address bootloader_, address exchange_, IZksyncWETH weth_) {
        bootloader = bootloader_;
        exchange = exchange_;
        weth = weth_;
    }

    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable returns (bytes4 magic, bytes memory context) {
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        require(msg.sender == bootloader, "InvalidSender");
        require(_transaction.paymasterInput.length >= 4, "InvalidInputLength");

        bytes4 paymasterInputSelector = bytes4(
            _transaction.paymasterInput[0:4]
        );
        if (paymasterInputSelector == IPaymasterFlow.approvalBased.selector) {
            (address token, uint256 amount, bytes memory data) = abi.decode(
                _transaction.paymasterInput[4:],
                (address, uint256, bytes)
            );

            address userAddress = address(uint160(_transaction.from));
            address thisAddress = address(this);

            uint256 providedAllowance = IERC20(token).allowance(userAddress, thisAddress);
            if (providedAllowance < amount) {
                magic = bytes4(0);
            }

            // Note, that while the minimal amount of ETH needed is tx.gasPrice * tx.gasLimit,
            // neither paymaster nor account are allowed to access this context variable.
            uint256 requiredETH = _transaction.gasLimit * _transaction.maxFeePerGas;
            try IERC20(token).transferFrom(userAddress, thisAddress, amount) {} catch (bytes memory revertReason) { // solhint-disable-line no-empty-blocks
                // If the revert reason is empty or represented by just a function selector,
                // we replace the error with a more user-friendly message
                require(revertReason.length > 4, "FailedTransferFrom");
                assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                    revert(add(0x20, revertReason), mload(revertReason))
                }
            }

            // we swap token to weth and then withdraw to eth, because UniERC20's uniTransfer() method has too small gas limit 5000
            // in production zksync-era-mainnet it is not true, and we can remove withdraw method and use data for swap token to eth
            IERC20(token).approve(exchange, amount);
            (bool success,) = exchange.call(data); // solhint-disable-line avoid-low-level-calls
            // revert(uintToString(IERC20(token).balanceOf(thisAddress)));
            if (!success) {
                assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

            // The bootloader never returns any data, so it can safely be ignored here.
            (success, ) = payable(bootloader).call{value: requiredETH}("");
            require(success, "BootloaderTransferFailed");
        } else {
            revert("UnsupportedFlow");
        }
    }

    function postTransaction(
        bytes calldata /*_context*/,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult /*_txResult*/,
        uint256 /*_maxRefundedGas*/
    ) external payable override {
        address userAddress = address(uint160(_transaction.from));
        userAddress.call{value: address(this).balance}("");
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}
