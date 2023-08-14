const hre = require('hardhat');
const { getChainId } = hre;
const { deployAndGetContract } = require('@1inch/solidity-utils');

module.exports = async ({ deployments, getNamedAccounts }) => {
    const networkName = hre.network.name;
    console.log(`running ${networkName} deploy script`);
    const chainId = await getChainId();
    console.log('network id ', chainId);
    if (chainId !== hre.config.networks[networkName].chainId.toString()) {
        console.log(`network chain id: ${hre.config.networks[networkName].chainId}, your chain id ${chainId}`);
        console.log('skipping wrong chain id deployment');
        return;
    }

    const { deployer } = await getNamedAccounts();

    await deployAndGetContract({
        contractName: 'Paymaster',
        constructorArgs: ['0x0000000000000000000000000000000000008001', '0x6e2B76966cbD9cF4cC2Fa0D76d24d5241E0ABC2F'],
        deployments,
        deployer,
    });
};

module.exports.skip = async () => true;
