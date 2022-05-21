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

This is also an ERC20 compatible token with 1B supply. Responsible for collecting and distributing fees to USED stakers.

## Latest Rinkeby Deployments

> usEth deployed to: 0x6EC08c970e989859fa8661646b722222283556E6

https://rinkeby.etherscan.io/address/0x6EC08c970e989859fa8661646b722222283556E6#code

> usEthDao deployed to: 0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919

https://rinkeby.etherscan.io/address/0xbeCbC2bA2afB8c69D00DaA9d860366bb539F0919#code


#### Mocks Contracts

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