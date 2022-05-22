# usETH
sustainable stablecoin backed by a high yielding delta neutral staked ethereum position

## Demo

https://jamesbachini.github.io/usETH/

Frontend is currently deployed on the Rinkeby Testnet.
To get Rinkeby ETH visit the faucet at https://rinkebyfaucet.com

## Main Contracts

#### $usETH Stablecoin
https://github.com/jamesbachini/usETH/blob/main/contracts/usEth.sol

This is the contract that sets up the position and handles rewards. It is also ERC20 compatible so the contract also acts as the stablecoin token.

#### $USED Governance Token
https://github.com/jamesbachini/usETH/blob/main/contracts/usEthDao.sol

This is also an ERC20 compatible token with 1B supply. Responsible for collecting and distributing fees to the DAO.

## Latest Rinkeby Deployments

> usEth deployed to: 0x6EC08c970e989859fa8661646b722222283556E6

https://rinkeby.etherscan.io/address/0x6EC08c970e989859fa8661646b722222283556E6#code

> usEthDao deployed to: 0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919

https://rinkeby.etherscan.io/address/0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919#code

# More Information on usETH

- Fully collateralized
- Estimated 10%+ APR
- Sustainable PoS revenues
- Permissionless
- Built on Ethereum

## how a delta neutral trade works

A revenue generating asset is purchased and used as collateral to borrow the same amount of the same asset to short it. The borrowed asset is sold for USD meaning that if the asset price goes up or down it doesn’t matter because the amount owned is the same as the amount borrowed.

Delta neutral trades have no directional exposure. The holder collects the revenues without being affected by underlying price movements. 

## enter lido's stETH staked ethereum

Ethereum is migrating from a proof of work algorithm to a proof of stake algorithm which means that holders of ETH can earn a return on their staked assets. LIDO finance has taken this a step further and created an stETH token which represents a position in staked Ethereum in the form of an ERC20 token.

This becomes more interesting because Aave accepts stETH as collateral on their borrowing and lending platform meaning that we can purchase stETH, use this as collateral to borrow ETH, swap ETH for USDC so we owe as much ETH as we own. Creating a delta neutral position.

However there is a significant benefit to doing this which is going to be a game changer for DeFi. The stETH that we are using for collateral still earns staking rewards while it is being used to short the same volume of Eth.

After the merge mining rewards will be redirected to stakers. stETH is expected to earn around 10% APR in staking rewards while borrowing costs are less than 1% on our overcollateralized position.

The USDC that we gain from selling the borrowed ETH is also deposited to Aave as additional collateral.

## can it be done in a smart contract?

usETH is an ERC20 token with some additional functionality.

- The deposit function allows a user to send ETH and mint usETH in return
- The withdraw function allows a user to redeem usETH in exchange for their ETH
- The stake function allows a user to commit usETH to the staking pool to earn rewards
- The unstake function releases the usETH and collects the rewards

With any stablecoin the total supply is not staked at any one time. However with usETH the underlying collateral is always staked meaning that if 50% of users stake their usETH the rewards will be 2x the ETH staking rewards before incentives.

For many users this will be attractive in itself because it will provide a sustainable return on a position pegged to the USD, fully automated and permissionless in a Solidity smart contract.

## how does it make money?

A usEth DAO governance token ($USED) will be deployed and fairly distributed to liquidity providers and partners in the space.

Incoming staking rewards will be subject to a small percentage fee which will be directed over time to the holders of the USED token creating value for the protocol and its future governance.

Incentives will be put in place for liquidity providers to incentivise growth and establish a pool on Uniswap for USDC-usETH.

The USED token itself has an interesting mechanism for accruing value. usETH fees building up in the DAO treasury can only be accessed by burning USED tokens for a proportional share. Incoming fees will build token value alongside the deflationary burn mechanism.

Both the usETH token and USED token are completely permissionless.

#### Mocks Contracts

These are published on Rinkeby. Aave does have a Rinkeby deployment but it doesn't accept stETH as collateral like the mainnet contract.

```javascript
curveAddress = '0x8832E339A432F390c63800792c766143a2B15AaC';
aaveAddress = '0xBB625f683DEf1dfEB204FBEb35703007ca16163e';
astethAddress = '0xeA2f791885880d37f33AA1b6df327FC8c461b3B1';
ausdcAddress = '0x14bb1E229725be421e397443dF7b74ffc433C52c';
```

## Ethers.js Commands
```javascript
const usEth = new ethers.Contract('0x5f4CDed8aeA26a6C2668751fe997EdB985b8b742', './abis/useth.json', ethers.provider);
const usEthBalance = await usEth.balanceOf(owner.address); // usETH is an ERC20 token, check balance
await usEth.deposit({value: ethers.utils.parseEther('0.01')}); // just send ETH with transaction, no arguments
await usEth.stake(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals
await usEth.unstake(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals
await usEth.withdraw(ethers.utils.parseEther('1')); // 1 usd, not 1 eth. Still has 18 decimals
```

## Build

```shell
npm install
npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY

// open new console
npx hardhat test --network local
```

## Deploy

```shell
npx hardhat run --network rinkeby scripts/deploy-rinkeby.js

npx hardhat verify --network rinkeby 0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919

npx hardhat verify --network rinkeby 0x6EC08c970e989859fa8661646b722222283556E6 "0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD" "0xBB625f683DEf1dfEB204FBEb35703007ca16163e" "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e" "0xE592427A0AEce92De3Edee1F18E0157C05861564" "0x8832E339A432F390c63800792c766143a2B15AaC" "0xeb8f08a975Ab53E34D8a0330E0D34de942C95926" "0xc778417E063141139Fce010982780140Aa0cD5Ab" "0xeA2f791885880d37f33AA1b6df327FC8c461b3B1" "0x14bb1E229725be421e397443dF7b74ffc433C52c" "0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919"
```
#### Constructor Args on usETH

lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,curveAddress,usdcAddress,wethAddress,astethAddress,ausdcAddress,usEthDao.address