const { trim0x, constants } = require('@1inch/solidity-utils');

function setn (num, bit, value) {
    if (value) {
        return BigInt(num) | (1n << BigInt(bit));
    } else {
        return BigInt(num) & (~(1n << BigInt(bit)));
    }
}

function buildFlags (flags = {}) {
    return setn(setn(0n, 0, !!flags.isPartialFill), 2, flags.usePermit2).toString();
}

function buildOffsets (calls) {
    if (calls.length > 10) throw new Error('Offsets array is too big');

    // https://stackoverflow.com/a/55261098/440168
    const cumulativeSum = (sum => value => { sum += value; return sum; })(0);
    return calls
        .map(call => trim0x(call).length / 2)
        .map(cumulativeSum)
        .reduce(
            (acc, a, i) => acc | (BigInt(a) << BigInt(24 * i)),
            0n,
        ).toString(16).padStart(60, '0');
}

function buildSwapDescription (srcToken, dstToken, srcReceiver, amount, minReturnAmount, flags) {
    return {
        srcToken,
        dstToken,
        srcReceiver,
        dstReceiver: constants.ZERO_ADDRESS,
        amount,
        minReturnAmount,
        flags,
    };
}

function buildBytesForExecutor (calls) {
    return '0x' +
        buildOffsets(calls) +
        calls.map(trim0x).join('');
}

const CallDescriptionConstants = {
    _SKIP_CALL_ON_ZERO_AMOUNT_FLAG: 0x8000,
    _HAS_TARGET_FLAG: 0x4000n,
    _HAS_VALUE_FLAG: 0x2000n,
    _PERFORM_APPROVE_FLAG: 0x1000n,
    _PERFORM_TRANSFER_FLAG: 0x0800n,
    _HAS_SPENDER_FLAG: 0x0400n,
    _HAS_RETURN_LIMIT_AMOUNT_FLAG: 0x0200n,

    _OFFSET_SIZE_MASK: 0x0180n, // 2 bits
    _OFFSET_SIZE_SHIFT: 7n,
    _PATCH_CALL_VALUE_FLAG: 0x0040n,

    _MANDATORY_FLAG: 0x0020n,
    _RETURN_INVERSED_FLAG: 0x0010n,
    _RETURN_WORD_INDEX_MASK: 0x000en, // 3 bits
    _RETURN_WORD_INDEX_SHIFT: 1n,
    _RETURN_INGORED_FLAG: 0x0001n,
};

function buildCalldataDescription ({
    skipCallOnZeroAmount = false,
    target = '0x',
    value = 0n,
    approve = {
        token: constants.ZERO_ADDRESS,
        spender: constants.ZERO_ADDRESS,
    },
    transfer = {
        token: constants.ZERO_ADDRESS,
        spender: constants.ZERO_ADDRESS,
    },

    offset = 0, // 0 means no patching, -1 means adding suffix, X>0 means byte offset
    patchValue = false,

    mandatory = true,
    returnInversed = false,
    returnWordIndex = 0,

    returnLimitAmount = 0n,

    data = '',
    ignoreReturn = false,
}) {
    let flags = 0n;
    let hexBytes = '';
    const trimmedData = trim0x(data);

    if (ignoreReturn) {
        flags = flags + CallDescriptionConstants._RETURN_INGORED_FLAG;
    }

    if (skipCallOnZeroAmount) {
        flags = flags + CallDescriptionConstants._SKIP_CALL_ON_ZERO_AMOUNT_FLAG;
    }

    const trimmedTarget = trim0x(target);
    if (trimmedTarget.length) {
        flags = flags + CallDescriptionConstants._HAS_TARGET_FLAG;
        hexBytes += trimmedTarget.padStart(40, '0');
    }

    const bnValue = BigInt(value);
    if (bnValue !== 0n) {
        flags = flags + CallDescriptionConstants._HAS_VALUE_FLAG;
        hexBytes += bnValue.toString(16).padStart(32, '0'); // 16 bytes is enough
    }

    // Put approve or transfer with optional token and spender addresses
    if ((approve.token && approve.token !== constants.ZERO_ADDRESS) ||
        (transfer.token && transfer.token !== constants.ZERO_ADDRESS)) {
        if ((approve.token && approve.token !== constants.ZERO_ADDRESS) &&
            (transfer.token && transfer.token !== constants.ZERO_ADDRESS)) {
            throw new Error('Invalid arguments');
        }

        // Put token address
        if (approve.token && approve.token !== constants.ZERO_ADDRESS) {
            flags = flags + CallDescriptionConstants._PERFORM_APPROVE_FLAG;
            hexBytes += BigInt(approve.token).toString(16).padStart(40, '0');
        } else if (transfer.token && transfer.token !== constants.ZERO_ADDRESS) {
            flags = flags + CallDescriptionConstants._PERFORM_TRANSFER_FLAG;
            hexBytes += BigInt(transfer.token).toString(16).padStart(40, '0');
        }

        // Put spender address if needed
        if (approve.spender && approve.spender !== constants.ZERO_ADDRESS) {
            flags = flags + CallDescriptionConstants._HAS_SPENDER_FLAG;
            hexBytes += BigInt(approve.spender).toString(16).padStart(40, '0');
        } else if (transfer.spender && transfer.spender !== constants.ZERO_ADDRESS) {
            flags = flags + CallDescriptionConstants._HAS_SPENDER_FLAG;
            hexBytes += BigInt(transfer.spender).toString(16).padStart(40, '0');
        }
    }

    if (returnLimitAmount !== 0n) {
        flags = flags + CallDescriptionConstants._HAS_RETURN_LIMIT_AMOUNT_FLAG;
        hexBytes += returnLimitAmount.toString(16).padStart(64, '0');
    }

    // Encode offset: 0 - no patching, -1 - suffix, X - 2 or 3 bytes offset
    if ((offset === trimmedData.length / 2 && trimmedData.length !== 0) || offset === -1) {
        flags = flags + (1n << CallDescriptionConstants._OFFSET_SIZE_SHIFT);
    } else
    if (offset >= 65536) {
        flags = flags + (3n << CallDescriptionConstants._OFFSET_SIZE_SHIFT);
        hexBytes += BigInt(offset).toString(16).padStart(6, '0'); // 3 bytes
    } else if (offset > 0) {
        flags = flags + (2n << CallDescriptionConstants._OFFSET_SIZE_SHIFT);
        hexBytes += BigInt(offset).toString(16).padStart(4, '0'); // 2 bytes
    }

    if (patchValue) {
        flags = flags + CallDescriptionConstants._PATCH_CALL_VALUE_FLAG;
    }

    if (mandatory) {
        flags = flags + CallDescriptionConstants._MANDATORY_FLAG;
    }

    if (returnInversed) {
        flags = flags + CallDescriptionConstants._RETURN_INVERSED_FLAG;
    }

    if (returnWordIndex) {
        if (returnWordIndex > 7) throw new Error('returnWordIndex out of bounds');
        flags = flags + (BigInt(returnWordIndex) << CallDescriptionConstants._RETURN_WORD_INDEX_SHIFT);
    }

    return '0x' + flags.toString(16).padStart(4, '0') + hexBytes + trimmedData;
}

function generateUniswapV2PatchableCalldata (executor, pair, srcToken, dstToken, minReturn, destination, doTransfer = true, broken = false) {
    const hasDestination = BigInt(destination) !== 0n && destination.toLowerCase() !== executor.address.toLowerCase();
    const hasMinReturn = BigInt(minReturn) !== 0n;
    const postData =
        (
            // (1n << 3n) | // balanceOf
            ((hasMinReturn ? 1n : 0n) << 4n) |
            ((hasDestination ? 1n : 0n) << 5n) |
            ((broken ? 1n : 0n) << 6n) |
            ((srcToken.toLowerCase() < dstToken.toLowerCase() ? 1n : 0n) << 7n)
        ).toString(16).padStart(2, '0') +
        BigInt(3).toString(16).padStart(8, '0') +
        BigInt(pair).toString(16).padStart(40, '0') +
        (hasDestination ? BigInt(destination).toString(16).padStart(40, '0') : '') +
        (hasMinReturn ? BigInt(minReturn).toString(16).padStart(64, '0') : '');
        // BigInt(srcToken).toString(16).padStart(40, '0'); // For balanceOf

    return buildCalldataDescription({
        offset: -1,
        transfer: doTransfer
            ? {
                token: srcToken,
                spender: pair,
            }
            : undefined,
        data: executor.interface.encodeFunctionData('swapUniV2') + postData,
    });
}

module.exports = {
    buildFlags,
    buildSwapDescription,
    buildBytesForExecutor,
    generateUniswapV2PatchableCalldata,
};
