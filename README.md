# usETH
sustainable stablecoin backed by a high yielding delta neutral staked ethereum position

## Frontend

https://jamesbachini.github.io/usETH/

Frontend is currently deployed on the Rinkeby Testnet. To get Rinkeby ETH visit the faucet at https://rinkebyfaucet.com

## Main Contracts

#### $usETH Stablecoin
https://github.com/jamesbachini/usETH/blob/main/contracts/usEth.sol

This is the contract that sets up the position and handles rewards. It is also ERC20 compatible so the contract also acts as the stablecoin token.

#### $USED Governance Token
https://github.com/jamesbachini/usETH/blob/main/contracts/usEthDao.sol

This is also an ERC20 compatible token with 1B supply. Responsible for collecting and distributing fees to USED stakers.

## Latest Rinkeby Deployments

> usEth deployed to: 0x5f4CDed8aeA26a6C2668751fe997EdB985b8b742

https://rinkeby.etherscan.io/address/0x5f4CDed8aeA26a6C2668751fe997EdB985b8b742#code

> usEthDao deployed to: 0x6da5F4684Fea48F02c73A5DE92d7C313222a5F29

https://rinkeby.etherscan.io/address/0x6da5F4684Fea48F02c73A5DE92d7C313222a5F29#code


#### Mocks Contracts

```javascript
curveAddress = '0xcfa613E081C6C31083D847A267d894929A7eb206';
aaveAddress = '0x345EFa1bd1A3A848a4E08Ca600D7c8199a452d12';
astethAddress = '0xB5C46a947521c014E0aBA7b65E75EF2981b45C19';
ausdcAddress = '0x5588989B78B7b18F92cc65cCB4852ecbD73a7d9E';
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



npx hardhat verify --network rinkeby 0x6da5F4684Fea48F02c73A5DE92d7C313222a5F29

npx hardhat verify --network rinkeby 0x5f4CDed8aeA26a6C2668751fe997EdB985b8b742 "0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD" "0x345EFa1bd1A3A848a4E08Ca600D7c8199a452d12" "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e" "0xE592427A0AEce92De3Edee1F18E0157C05861564" "0xcfa613E081C6C31083D847A267d894929A7eb206" "0xeb8f08a975Ab53E34D8a0330E0D34de942C95926" "0xc778417E063141139Fce010982780140Aa0cD5Ab" "0xB5C46a947521c014E0aBA7b65E75EF2981b45C19" "0x5588989B78B7b18F92cc65cCB4852ecbD73a7d9E" "0x6da5F4684Fea48F02c73A5DE92d7C313222a5F29"
```
#### Constructor Args on usETH

lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,curveAddress,usdcAddress,wethAddress,astethAddress,ausdcAddress,usEthDao.address