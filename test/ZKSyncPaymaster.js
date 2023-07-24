const fs = require('fs');
const hre = require('hardhat');
const path = require('path');
const { ether, constants, trackReceivedTokenAndTx, expect } = require('@1inch/solidity-utils');
const { utils, Wallet, Provider } = require('zksync-web3');
const { Deployer } = require('@matterlabs/hardhat-zksync-deploy');
const { ethers } = require('hardhat');
const {
    buildFlags,
    buildBytesForExecutor,
    buildSwapDescription,
    generateUniswapV2PatchableCalldata,
} = require('./helpers/calldata.js');

const BOOTLOADER_FORMAL_ADDR = '0x0000000000000000000000000000000000008001';

describe('ZKSync paymaster integration @zksync', function () {
    // For these tests you should start your own local zksync node:
    //      $ git clone https://github.com/matter-labs/local-setup.git
    //      $ cd local-setup
    //      $ ./start.sh
    // Use one of these rich wallets with some ETH on it in process.env.ZKSYNC_PRIVATE_KEY:
    //      https://github.com/matter-labs/local-setup/blob/main/rich-wallets.json
    // For example:
    // {
    //     "address": "0x36615Cf349d7F6344891B1e7CA7C72883F5dc049",
    //     "privateKey": "0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110"
    // },
    before(async function () {
        if ((await ethers.provider.getNetwork()).chainId !== 270) {
            console.log('Skipping tests, not on Arbitrum network');
            this.skip();
        }
    });

    async function initContracts () {
        const provider = Provider.getDefaultProvider();
        const wallet = new Wallet(process.env.ZKSYNC_PRIVATE_KEY, provider, ethers.provider);
        const deployer = new Deployer(hre, wallet);

        const WethMock = await deployer.loadArtifact('ZksynkWETH');
        const TokenMock = await deployer.loadArtifact('TokenMock');

        const WETH = await deployer.deploy(WethMock);
        const DAI = await deployer.deploy(TokenMock, ['DAI', 'DAI']);
        const USDC = await deployer.deploy(TokenMock, ['USDC', 'USDC']);
        await (await WETH.deposit({ value: ether('2000') })).wait();
        await (await DAI.mint(wallet.address, ether('2000'))).wait();
        await (await USDC.mint(wallet.address, ether('2000'))).wait();
        const tokens = {
            DAI,
            WETH,
            USDC,
            ETH: {
                address: constants.ZERO_ADDRESS,
                balanceOf: wallet.provider.getBalance,
                decimals: () => 18,
            },
        };

        const AggregationRouter = JSON.parse(fs.readFileSync(path.join(__dirname, '../artifacts-external/AggregationRouterV6.json'), 'utf8'));
        const exchange = await deployer.deploy(AggregationRouter, [tokens.WETH.address], { gasLimit: '2000000000' });
        const Executor = JSON.parse(fs.readFileSync(path.join(__dirname, '../artifacts-external/Executor.json'), 'utf8'));
        const executor = await deployer.deploy(Executor, [constants.ZERO_ADDRESS, constants.ZERO_ADDRESS, exchange.address], { gasLimit: '2000000000' });
        await (await DAI.approve(exchange.address, ether('500'))).wait();
        await (await DAI.approve(executor.address, ether('500'))).wait();
        await (await USDC.approve(exchange.address, ether('500'))).wait();
        await (await USDC.approve(executor.address, ether('500'))).wait();

        const UniV2Factory = await deployer.loadArtifact('MuteSwitchFactoryDynamic');
        const uniV2Factory = await deployer.deploy(UniV2Factory);
        const UniV2Router = await deployer.loadArtifact('MuteSwitchRouterDynamic');
        const uniV2Router = await deployer.deploy(UniV2Router, [uniV2Factory.address, tokens.WETH.address]);
        await (await tokens.DAI.approve(uniV2Router.address, ether('500'))).wait();
        await (await tokens.USDC.approve(uniV2Router.address, ether('500'))).wait();
        await (await tokens.WETH.approve(uniV2Router.address, ether('500'))).wait();
        const Paymaster = await deployer.loadArtifact('Paymaster');
        const paymaster = await deployer.deploy(Paymaster, [BOOTLOADER_FORMAL_ADDR, exchange.address, tokens.WETH.address], { gasLimit: '2000000000' });
        await (
            await uniV2Router.addLiquidity(
                tokens.DAI.address,
                tokens.USDC.address,
                ether('100'),
                ether('100'),
                ether('100'),
                ether('100'),
                wallet.address,
                '20000000000',
                0,
                true,
                { gasLimit: '2000000000' },
            )
        ).wait();
        await (
            await uniV2Router.addLiquidity(
                tokens.USDC.address,
                tokens.WETH.address,
                ether('100'),
                ether('100'),
                ether('100'),
                ether('100'),
                wallet.address,
                '20000000000',
                0,
                true,
                { gasLimit: '2000000000' },
            )
        ).wait();
        const uniV2DaiUsdc = await uniV2Factory.getPair(tokens.DAI.address, tokens.USDC.address, true);
        const uniV2WethUsdc = await uniV2Factory.getPair(tokens.WETH.address, tokens.USDC.address, true);

        return { wallet, tokens, executor, exchange, paymaster, uniV2DaiUsdc, uniV2WethUsdc };
    };

    it('should swap and pay gas fees with paymaster', async function () {
        const { wallet, tokens, executor, exchange, paymaster, uniV2DaiUsdc, uniV2WethUsdc } = await initContracts();

        const inputAmount = ether('5');
        const minReturnAmount = ether('4').toString();
        await (await tokens.USDC.approve(exchange.address, inputAmount)).wait();

        const tokenAmountForFee = ether('5');
        await (await tokens.USDC.approve(paymaster.address, tokenAmountForFee)).wait();

        const swapTokenToEthData = await exchange.populateTransaction.swap(
            executor.address,
            buildSwapDescription(
                tokens.USDC.address,
                tokens.WETH.address, // change it to `tokens.ETH.address` for swap to ETH
                executor.address,
                tokenAmountForFee.toString(),
                '1',
                buildFlags(),
            ),
            '0x',
            buildBytesForExecutor([
                generateUniswapV2PatchableCalldata(
                    executor,
                    uniV2WethUsdc,
                    tokens.USDC.address,
                    tokens.WETH.address,
                    '0',
                    exchange.address, // change it to `executor.address` for swap to ETH
                ),
                // uncomment this for swap to ETH
                // generateWethWithdrawPatchableCalldata(tokens.WETH),
                // generateEthBalanceOfPatchableCalldata(executor, executor.address),
                // generateEthTransferPatchableCalldata(exchange.address),
            ]),
        );

        // Encoding the "ApprovalBased" paymaster flow's input
        const paymasterParams = utils.getPaymasterParams(paymaster.address, {
            type: 'ApprovalBased',
            token: tokens.USDC.address,
            minimalAllowance: tokenAmountForFee,
            innerInput: swapTokenToEthData.data,
        });

        const swap = () => exchange.swap(
            executor.address,
            buildSwapDescription(
                tokens.USDC.address,
                tokens.DAI.address,
                executor.address,
                inputAmount.toString(),
                minReturnAmount.toString(),
                buildFlags(),
            ),
            '0x',
            buildBytesForExecutor([
                generateUniswapV2PatchableCalldata(
                    executor,
                    uniV2DaiUsdc,
                    tokens.USDC.address,
                    tokens.DAI.address,
                    '0',
                    exchange.address,
                ),
            ]),
            {
                gasLimit: '2000000000',
                customData: {
                    paymasterParams,
                    gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
                },
            },
        );

        const walletEthBalanceBefore = await wallet.provider.getBalance(wallet.address);
        const walletUsdcBalanceBefore = await tokens.USDC.balanceOf(wallet.address);
        const walletDaiBalanceBefore = await tokens.DAI.balanceOf(wallet.address);
        const walletWethBalanceBefore = await tokens.WETH.balanceOf(wallet.address);
        const paymasterEthBalanceBefore = await wallet.provider.getBalance(paymaster.address);
        const paymasterUsdcBalanceBefore = await tokens.USDC.balanceOf(paymaster.address);
        const paymasterWethBalanceBefore = await tokens.WETH.balanceOf(paymaster.address);

        const [received] = await trackReceivedTokenAndTx(wallet.provider, tokens.USDC, wallet.address, swap);

        const walletEthBalanceAfter = await wallet.provider.getBalance(wallet.address);
        const walletUsdcBalanceAfter = await tokens.USDC.balanceOf(wallet.address);
        const walletDaiBalanceAfter = await tokens.DAI.balanceOf(wallet.address);
        const walletWethBalanceAfter = await tokens.WETH.balanceOf(wallet.address);
        const paymasterEthBalanceAfter = await wallet.provider.getBalance(paymaster.address);
        const paymasterUsdcBalanceAfter = await tokens.USDC.balanceOf(paymaster.address);
        const paymasterWethBalanceAfter = await tokens.WETH.balanceOf(paymaster.address);

        console.log(`Swap ${-BigInt(received) - BigInt(tokenAmountForFee.toString())} USDC from wallet, inputAmount: ${inputAmount.toString()}, minReturnAmount: ${minReturnAmount.toString()}`);
        console.log(`And transfer ${tokenAmountForFee.toString()} USDC to Paymaster for fee`);
        console.table({
            'Wallet USDC balance': { Before: walletUsdcBalanceBefore.toString(), After: walletUsdcBalanceAfter.toString() },
            'Wallet DAI balance': { Before: walletDaiBalanceBefore.toString(), After: walletDaiBalanceAfter.toString() },
            'Wallet ETH balance': { Before: walletEthBalanceBefore.toString(), After: walletEthBalanceAfter.toString() },
            'Wallet WETH balance': { Before: walletWethBalanceBefore.toString(), After: walletWethBalanceAfter.toString() },
            'Paymaster ETH balance': { Before: paymasterEthBalanceBefore.toString(), After: paymasterEthBalanceAfter.toString() },
            'Paymaster USDC balance': { Before: paymasterUsdcBalanceBefore.toString(), After: paymasterUsdcBalanceAfter.toString() },
            'Paymaster WETH balance': { Before: paymasterWethBalanceBefore.toString(), After: paymasterWethBalanceAfter.toString() },
        });

        expect(walletUsdcBalanceAfter.add(tokenAmountForFee).add(inputAmount)).to.be.gt(walletUsdcBalanceBefore);
        expect(walletDaiBalanceAfter).to.be.gt(walletDaiBalanceBefore);
        expect(walletEthBalanceAfter).to.be.gt(walletEthBalanceBefore);
        expect(walletEthBalanceAfter).to.be.lt(walletEthBalanceBefore.add(tokenAmountForFee));

        expect(paymasterEthBalanceAfter).to.be.gte(paymasterEthBalanceBefore);
        expect(paymasterUsdcBalanceAfter).to.be.eq(paymasterUsdcBalanceBefore);
        expect(paymasterWethBalanceAfter).to.be.eq(paymasterWethBalanceBefore);
    });
});
