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

> usEthDao deployed to: 0xa359039EA942c7E6CdA54c618F64D1bd5155D331
https://rinkeby.etherscan.io/address/0xEBB9255e86dA226Cf819C68D958Abbb431bEF684#code

> usEth deployed to: 0xEBB9255e86dA226Cf819C68D958Abbb431bEF684
https://rinkeby.etherscan.io/address/0xa359039EA942c7E6CdA54c618F64D1bd5155D331#code

Mocks:
curveAddress = '0x2692CB081Ae680110d5b8E549563e74e617b4606';
aaveAddress = '0x0612c3e3143430A7C406C66070C288c47eEC8d91';
astethAddress = '0xEe9AD934d7b745c5b708338750B7DF5ee3C0a213';
ausdcAddress = '0x94fbaf6272Ba22d22A35cD4dF080CdB13c446BEC';

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
npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY

// open new console
npx hardhat test --network local


npx hardhat verify --network rinkeby 0xa359039EA942c7E6CdA54c618F64D1bd5155D331

npx hardhat verify --network rinkeby 0xEBB9255e86dA226Cf819C68D958Abbb431bEF684 "0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD" "0x0612c3e3143430A7C406C66070C288c47eEC8d91" "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e" "0xE592427A0AEce92De3Edee1F18E0157C05861564" "0x2692CB081Ae680110d5b8E549563e74e617b4606" "0xeb8f08a975Ab53E34D8a0330E0D34de942C95926" "0xc778417E063141139Fce010982780140Aa0cD5Ab" "0xEe9AD934d7b745c5b708338750B7DF5ee3C0a213" "0x94fbaf6272Ba22d22A35cD4dF080CdB13c446BEC" "0xa359039EA942c7E6CdA54c618F64D1bd5155D331"
lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,curveAddress,usdcAddress,wethAddress,astethAddress,ausdcAddress,usEthDao.address
```
