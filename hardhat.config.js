require('@matterlabs/hardhat-zksync-deploy');
require('@matterlabs/hardhat-zksync-solc');
require('@matterlabs/hardhat-zksync-verify');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('@nomicfoundation/hardhat-chai-matchers');
require('dotenv').config();
require('hardhat-dependency-compiler');
require('hardhat-deploy');
require('hardhat-gas-reporter');
require('hardhat-tracer');
require('solidity-coverage');

const { networks, etherscan } = require('./hardhat.networks');

module.exports = {
    etherscan,
    networks,
    solidity: {
        compilers: [
            {
                version: '0.8.19',
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
    tracer: {
        enableAllOpcodes: true,
    },
    dependencyCompiler: {
        paths: [
            '@1inch/solidity-utils/contracts/mocks/TokenMock.sol',
        ],
    },
    zksolc: {
        version: '1.3.10',
        compilerSource: 'binary',
        settings: {
            optimizer: {
                mode: 'z',
            },
        },
    },
};
