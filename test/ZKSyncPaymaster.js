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
    generateWethWithdrawPatchableCalldata,
    generateEthBalanceOfPatchableCalldata,
    generateEthTransferPatchableCalldata,
    generateSolidlyPatchableCalldata,
} = require('./helpers/calldata.js');

const e6 = (value) => ether(value) / BigInt('1000000000000');
const BOOTLOADER_FORMAL_ADDR = '0x0000000000000000000000000000000000008001';

describe('ZKSync paymaster integration @zksync', function () {
    // For these tests you should start your own zksync fork node:
    // https://github.com/matter-labs/era-test-node
    // Use one of rich wallets with some ETH on it in process.env.ZKSYNC_PRIVATE_KEY. You can find them in era-test-node logs.
    // You shoould set env variable `process.env.ZKSYNC_WEB3_API_URL` with node url.
    before(async function () {
        if ((await Provider.getDefaultProvider().getNetwork()).chainId !== 260) {
            console.log('Skipping tests, unexpected network');
            this.skip();
        }
    });

    async function initContracts () {
        const provider = Provider.getDefaultProvider();
        const wallet = new Wallet(process.env.ZKSYNC_PRIVATE_KEY, provider, ethers.provider);
        const deployer = new Deployer(hre, wallet);

        const IWETH = await deployer.loadArtifact('IWETH');
        const IERC20 = await deployer.loadArtifact('@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20');
        const IMuteSwitchPairDynamic = await deployer.loadArtifact('IMuteSwitchPairDynamic');
        const IMuteSwitchRouterDynamic = await deployer.loadArtifact('IMuteSwitchRouterDynamic');
        const AggregationRouter = JSON.parse(fs.readFileSync(path.join(__dirname, '../artifacts-external/AggregationRouter.json'), 'utf8'));
        const Executor = JSON.parse(fs.readFileSync(path.join(__dirname, '../artifacts-external/Executor.json'), 'utf8'));
        const Paymaster = await deployer.loadArtifact('Paymaster');

        const tokens = {
            ETH: {
                address: constants.ZERO_ADDRESS,
                balanceOf: wallet.provider.getBalance,
                decimals: () => 18,
            },
            WETH: new ethers.Contract('0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91', IWETH.abi, provider),
            USDC: new ethers.Contract('0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4', IERC20.abi, provider),
        };

        const contracts = {
            exchange: new ethers.Contract('0x6e2B76966cbD9cF4cC2Fa0D76d24d5241E0ABC2F', AggregationRouter.abi, provider),
            solidlyRouter: new ethers.Contract('0x8B791913eB07C32779a16750e3868aA8495F5964', IMuteSwitchRouterDynamic.abi, provider),
            solidlyWethUsdc: new ethers.Contract('0xDFAaB828f5F515E104BaaBa4d8D554DA9096f0e4', IMuteSwitchPairDynamic.abi, provider), // 0x2C0737AAf530714067396131Ee9BE9cee4cf09A0
        };
        const executor = await deployer.deploy(
            Executor, [constants.ZERO_ADDRESS, constants.ZERO_ADDRESS, contracts.exchange.address],
            { gasLimit: '2000000000' },
        );
        const paymaster = await deployer.deploy(
            Paymaster, [BOOTLOADER_FORMAL_ADDR, contracts.exchange.address],
            { gasLimit: '2000000000' },
        );
        contracts.executor = executor;
        contracts.paymaster = paymaster;

        // Buy some tokens via MuteSwitch
        await contracts.solidlyRouter.connect(wallet).swapExactETHForTokens(
            e6('1000'),
            [tokens.WETH.address, tokens.USDC.address],
            wallet.address,
            '0xFFFFFFFFFFFFFFFF',
            [false],
            { value: ether('1').toString() },
        );

        return { wallet, tokens, contracts };
    };

    it('should swap and pay gas fees with paymaster', async function () {
        const { wallet, tokens, contracts } = await initContracts();

        // build swap token to ETH calldata for fee payment in paymaster
        const tokenAmountForFee = e6('400');
        await (await tokens.USDC.connect(wallet).approve(contracts.paymaster.address, tokenAmountForFee)).wait();

        const swapTokenToEth = await contracts.exchange.populateTransaction.swap(
            contracts.executor.address,
            buildSwapDescription(
                tokens.USDC.address,
                tokens.ETH.address,
                contracts.solidlyWethUsdc.address,
                tokenAmountForFee.toString(),
                '1',
                buildFlags(),
            ),
            '0x',
            buildBytesForExecutor([
                generateSolidlyPatchableCalldata({
                    executor: contracts.executor,
                    pair: contracts.solidlyWethUsdc.address,
                    srcToken: tokens.USDC.address,
                    dstToken: tokens.WETH.address,
                    minReturn: '0',
                    destination: contracts.executor.address,
                    fee: (await contracts.solidlyWethUsdc.pairFee()) * 100,
                    isStable: (await contracts.solidlyWethUsdc.stable()),
                    decimals0Exp: 6,
                    decimals1Exp: 18,
                    doTransfer: false,
                }),
                generateWethWithdrawPatchableCalldata(tokens.WETH),
                generateEthBalanceOfPatchableCalldata(contracts.executor, contracts.executor.address),
                generateEthTransferPatchableCalldata(contracts.exchange.address),
            ]),
        );

        const paymasterParams = utils.getPaymasterParams(contracts.paymaster.address, {
            type: 'ApprovalBased',
            token: tokens.USDC.address,
            minimalAllowance: tokenAmountForFee,
            innerInput: swapTokenToEth.data,
        });

        // build main operation
        const randomReceiver = ethers.Wallet.createRandom();
        const inputAmount = e6('100');
        const alreadyApproved = await tokens.USDC.allowance(wallet.address, contracts.paymaster.address);
        await (await tokens.USDC.connect(wallet).approve(contracts.paymaster.address, alreadyApproved.add(inputAmount))).wait();

        const transfer = () => tokens.USDC.connect(wallet).transfer(
            randomReceiver.address,
            inputAmount,
            {
                customData: {
                    paymasterParams,
                    gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT,
                },
            },
        );

        // execute main operation and check result
        const receivedFeeETH = await contracts.solidlyWethUsdc.getAmountOut(tokenAmountForFee, tokens.USDC.address);
        const walletEthBalanceBefore = await wallet.provider.getBalance(wallet.address);
        const walletUsdcBalanceBefore = await tokens.USDC.balanceOf(wallet.address);
        const paymasterEthBalanceBefore = await wallet.provider.getBalance(contracts.paymaster.address);
        const paymasterUsdcBalanceBefore = await tokens.USDC.balanceOf(contracts.paymaster.address);
        const randomReceiverUSDCBalanceBefore = await tokens.USDC.balanceOf(randomReceiver.address);

        const [received] = await trackReceivedTokenAndTx(wallet.provider, tokens.USDC, wallet.address, transfer);

        const walletEthBalanceAfter = await wallet.provider.getBalance(wallet.address);
        const walletUsdcBalanceAfter = await tokens.USDC.balanceOf(wallet.address);
        const paymasterEthBalanceAfter = await wallet.provider.getBalance(contracts.paymaster.address);
        const paymasterUsdcBalanceAfter = await tokens.USDC.balanceOf(contracts.paymaster.address);
        const randomReceiverUSDCBalanceAfter = await tokens.USDC.balanceOf(randomReceiver.address);

        console.table({
            'Wallet USDC balance': { Before: walletUsdcBalanceBefore.toString(), After: walletUsdcBalanceAfter.toString() },
            'Wallet ETH balance': { Before: walletEthBalanceBefore.toString(), After: walletEthBalanceAfter.toString() },
            'Paymaster ETH balance': { Before: paymasterEthBalanceBefore.toString(), After: paymasterEthBalanceAfter.toString() },
            'Paymaster USDC balance': { Before: paymasterUsdcBalanceBefore.toString(), After: paymasterUsdcBalanceAfter.toString() },
            'Random receiver USDC balance': { Before: randomReceiverUSDCBalanceBefore.toString(), After: randomReceiverUSDCBalanceAfter.toString() },
        });
        console.log(`Spent ${-BigInt(received)} USDC: ${inputAmount.toString()} USDC for transfer and ${tokenAmountForFee.toString()} USDC for fee`);

        expect(walletUsdcBalanceAfter.add(tokenAmountForFee).add(inputAmount)).to.be.eq(walletUsdcBalanceBefore);
        expect(walletEthBalanceAfter).to.be.gt(walletEthBalanceBefore);
        expect(paymasterEthBalanceAfter.mul(10)).to.be.lt(receivedFeeETH);
        expect(paymasterUsdcBalanceAfter).to.be.eq(paymasterUsdcBalanceBefore);
        expect(randomReceiverUSDCBalanceAfter).to.be.eq(randomReceiverUSDCBalanceBefore.add(inputAmount));
    });
});
