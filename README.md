# usETH
Sustainable high yielding stablecoin backed by a delta neutral staked Ethereum position

## Rinkeby Testnet Frontend

https://jamesbachini.github.io/usETH/

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
npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY

// open new console
npx hardhat test --network local
```
