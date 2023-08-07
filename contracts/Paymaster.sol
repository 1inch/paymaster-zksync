// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";

/**
 * @title Paymaster
 * @dev This contract is an implementation of the IPaymaster interface that enables paying transaction fees with any tokens using 1inch.
 */
contract Paymaster is IPaymaster {
    error InvalidSender();
    error FailedTransferFrom();
    error BootloaderTransferFailed();
    error UnsupportedFlow();
    error InvalidInputLength();

    /**
     * @notice The address of the bootloader contract.
     */
    address immutable public bootloader;

    /**
     * @notice The address of the 1inch AggregationRouter contract.
     */
    address immutable public exchange;

    /**
     * @param bootloader_ The address of the bootloader contract.
     * @param exchange_ The address of the 1inch AggregationRouter contract.
     */
    constructor(address bootloader_, address exchange_) {
        bootloader = bootloader_;
        exchange = exchange_;
    }

    /**
     * @notice Validates, swaps tokens for ETH to pay gas fees using 1inch and pays for the transaction.
     * @dev It checks the validity of the transaction, decodes the paymasterInput to extract token details and make a token swap on 1inch.
     * @param _transaction The transaction object including the token details and 1inch exchange data.
     * @return magic Returns PAYMASTER_VALIDATION_SUCCESS_MAGIC if successful.
     */
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

            uint256 requiredETH = _transaction.gasLimit * _transaction.maxFeePerGas;
            try IERC20(token).transferFrom(userAddress, thisAddress, amount) {} catch (bytes memory revertReason) { // solhint-disable-line no-empty-blocks
                // If the revert reason is empty or represented by just a function selector, we replace the error with a more user-friendly message
                require(revertReason.length > 4, "FailedTransferFrom");
                assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                    revert(add(0x20, revertReason), mload(revertReason))
                }
            }

            IERC20(token).approve(exchange, amount);
            (bool success,) = exchange.call(data); // solhint-disable-line avoid-low-level-calls
            if (!success) {
                assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

            // The bootloader never returns any data, so it can safely be ignored here.
            (success,) = payable(bootloader).call{value: requiredETH}("");
            require(success, "BootloaderTransferFailed");
        } else {
            revert("UnsupportedFlow");
        }
    }

    /**
     * @notice Transfers the remaining ETH balance of the Paymaster back to the user after a transaction has been executed.
     * @param _transaction The transaction object.
     */
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

    /**
     * @notice Allows the contract to accept incoming Ether.
     */
    receive() external payable {} // solhint-disable-line no-empty-blocks
}
