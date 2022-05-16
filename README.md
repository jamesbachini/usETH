# USBT
Sustainable stablecoin backed by staked Ethereum basis trade

I know it’s not a great time to be launching a stablecoin but this might be a way to do it sustainably while still offering high yield, so hear me out…

## How A Delta Neutral Basis Trade Works

Basis trades have been part of the bread and butter of traditional finance for as long as commodities have traded on futures exchanges. It involves buying an asset and then short selling a futures contract for the same asset. This means that if the asset price goes up or down it doesn’t matter because the position is delta neutral and pegged to the USD.

The trader collects a funding premium because longs will pay shorts in most markets a funding premium for holding the position.


This has been very profitable in crypto markets as well with big players like Alameda heavily involved in basis trading

## Enter LIDO’s stETH Staked Ethereum

Ethereum is migrating from a proof of work algorithm to a proof of stake algorithm which means that holders of ETH can earn a return on their staked assets. LIDO finance has taken this a step further and created an stETH token which represents a position in staked Ethereum in the form of an ERC20 token.

This becomes more interesting because Aave accept stETH as collateral on their borrowing and lending platform meaning that we can purchase stETH, use this as collateral to borrow USDC, which can then in turn be used to take a short position on a DeFi futures exchange such as DyDx or Perpetual protocol. A delta neutral basis trade.

However there is a significant benefit to doing this which is going to be a game changer for DeFi. An stETH basis trade earns on both the long side and the short side.

The stETH long will earn 3-10% APR in staking rewards and the short will earn 5-10% APR (more in bull markets, less in bear markets) in funding premium. This means that the position even after borrowing costs will earn somewhere between 5-20% APR.

## Can It Be Done In A Smart Contract?

In theory we could create a fully decentralised stablecoin backed by a basis trade running completely on Ethereum smart contracts.

The first smart contract would handle setting up the position which would grow over time because of staking rewards and funding premium. When a user deposits ETH into the vault they’ll be given a btETH to represent their position.

For many users this will be attractive in itself because it will provide an attractive return on a position pegged to the USD fully automated and permissionless in a Solidity smart contract.

btETH wouldn’t be pegged to the US dollar  however because it would represent an equal share of a growing pool due to the accrual of staking rewards and funding premium.

The second contract provides a mechanism to mint a stable coin by staking btETH tokens. A user will deposit btETH and in return they’ll be able to mint USBT which will always be valued at $1.

The user will still accrue returns on their staked btETH but they will be able to use USBT much like any other algorithmic stablecoin.

A governance token will be used to incentivise growth and bribe initial liquidity providers to create a pool on Uniswap for USDC-USBT.

Protocol will charge a 0.x% fee to carry out transactions which will be redistributed to governance token holders and/or treasury.


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
