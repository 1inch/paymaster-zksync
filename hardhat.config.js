require('@matterlabs/hardhat-zksync-deploy');
require('@matterlabs/hardhat-zksync-solc');
require('@matterlabs/hardhat-zksync-verify');
require('@nomiclabs/hardhat-ethers');
require('@nomicfoundation/hardhat-chai-matchers');
require('dotenv').config();
require('hardhat-dependency-compiler');
require('hardhat-deploy');
require('hardhat-tracer');
require('solidity-coverage');

const { networks, etherscan } = require('./hardhat.networks');

module.exports = {
    etherscan,
    networks,
    solidity: {
        compilers: [
            {
                version: '0.8.20',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000,
                    },
                    viaIR: true,
                },
            },
        ],
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    mocha: {
        timeout: 360000,
    },
    tracer: {
        enableAllOpcodes: true,
    },
    dependencyCompiler: {
        paths: [
            '@1inch/solidity-utils/contracts/interfaces/IWETH.sol',
        ],
    },
    zksolc: {
        version: '1.3.13',
        compilerSource: 'binary',
        settings: {
            optimizer: {
                mode: 'z',
            },
        },
    },
};
