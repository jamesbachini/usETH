# usETH
Sustainable high yielding stablecoin backed by a delta neutral staked Ethereum position

I know it’s not a great time to be launching a stablecoin but this might be a way to do it sustainably while still offering high yield, so hear me out…

## How A Delta Neutral Trade Works

Delta neutral trades have no directional exposure. They have been part of the bread and butter of traditional finance for as long as commodities have traded on futures exchanges. It involves buying an asset and then borrowing the same amount of the same asset to short it. The borrowed asset is sold for USD meaning that if the asset price goes up or down it doesn’t matter because the amount owned is the same as the amount borrowed.

This is often set up through a basis trade where longs will pay shorts in most markets a funding premium for holding the position. This has been very profitable in crypto markets as well with big players like Alameda heavily involved in basis trading

## Enter LIDO’s stETH Staked Ethereum

Ethereum is migrating from a proof of work algorithm to a proof of stake algorithm which means that holders of ETH can earn a return on their staked assets. LIDO finance has taken this a step further and created an stETH token which represents a position in staked Ethereum in the form of an ERC20 token.

This becomes more interesting because Aave accepts stETH as collateral on their borrowing and lending platform meaning that we can purchase stETH, use this as collateral to borrow ETH swap this for USDC so we owe as much ETH as we own. Creating a delta neutral position.

However there is a significant benefit to doing this which is going to be a game changer for DeFi. The stETH that we are using for collateral still earns staking rewards while it is being used to short the same volume of Eth.

The stETH long will earn around 10% APR (post merge) in staking rewards while borrowing costs are less than 1% on our overcollateralized position.

## Can It Be Done In A Smart Contract?

usETH is an ERC20 token with some additional functionality.

- The deposit function allows a user to send ETH and mint usETH in return
- The withdraw function allows a user to redeem usETH in exchange for their ETH
- The stake function allows a user to commit usETH to the staking pool to earn rewards
- The unstake function releases the usETH and collects the rewards

With any stablecoin the total supply is not staked at any one time. However with usETH the underlying collateral is always staked meaning that if 50% of users stake their usETH the rewards will be 2x the ETH staking rewards before incentives.

For many users this will be attractive in itself because it will provide a sustainable return on a position pegged to the USD fully automated and permissionless in a Solidity smart contract.

A usEth DAO governance token ($USED) will incentivise growth and create bribes to bootstrap a liquidity pool on Uniswap for USDC-usETH.

Incoming staking rewards will be subject to a 2% fee which will be directed to the holders of the USED token creating value for the protocol and its future governance.

All figures are preliminary and subject to change.

## Rinkeby Deployments

usEth deployed to: 0x7B089d4807CbdaA345851094cb5EfF8F5fb5670f
^^^ This is the main contract

usEthDao deployed to: 0xBa9f64687A6190dF03FF5C476Fb8Dd34A1dAFa4a
FakeAave: 0xf0a8B14F0A9Ae12c994872028d3B520D303A8F68
Owner: 0x1111c595c66A7997485E4f587eA812716b8d165F

## Ethers.js Commands
const usEth = new ethers.Contract('0x7B089d4807CbdaA345851094cb5EfF8F5fb5670f', './abis/useth.json', ethers.provider);
const usEthBalance = await usEth.balanceOf(owner.address); // usETH is an ERC20 token, check balance
await usEth.deposit({value: ethers.utils.parseEther('0.01')}); // just send ETH with transaction, no arguments
await usEth.stake(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals
await usEth.unstake(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals
await usEth.withdraw(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals

## Build

```shell
npm install
npx hardhat test


npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
