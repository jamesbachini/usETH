const { expect } = require('chai');
const { ethers } = require('hardhat');
const lidoAbi = require('./../abis/lido.json');
const aaveAbi = require('./../abis/aave.json');
const usdcAbi = require('./../abis/usdc.json');
const wethAbi = require('./../abis/weth.json');
    
// Mainnet
let lidoAddress = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84';
let aaveAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
let chainlinkAddress = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
let uniswapAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
let curveAddress = '0xdc24316b9ae028f1497c275eb9192a3ea0f67022';
let usdcAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
let wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
let astethAddress = '0x1982b2F5814301d4e9a8b0201555376e62F82428'; 
let ausdcAddress = '0xBcca60bB61934080951369a648Fb03DF4F96263C';

describe('usEth', function () {
  let usEth, usEthDao, lido, aave, weth;

  before(async () => {
    [owner,user1] = await ethers.getSigners();
    const networkData = await ethers.provider.getNetwork();
    if (networkData.chainId === 31337) { // Move some funds on local testnet
      const sponsor = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider);
      await sponsor.sendTransaction({ to: owner.address, value: ethers.utils.parseEther('2') });
    }
    const ownerBalance = await ethers.provider.getBalance(owner.address);
    //console.log(`    Owner: ${owner.address} Balance: ${ethers.utils.formatEther(ownerBalance)} ETH`);
    await hre.run('compile');
    
    /*
    // Add Rinkeby addresses
    lidoAddress = '0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD';
    chainlinkAddress = '0x8A753747A1Fa494EC906cE90E9f37563A8AF630e';
    usdcAddress = '0xeb8f08a975Ab53E34D8a0330E0D34de942C95926';
    wethAddress = '0xc778417E063141139Fce010982780140Aa0cD5Ab';
    // Rinkeby Mocks
    curveAddress = '0xb47C718ed981EFaB31EEa6d88ABd0A7f3DE89B7C';
    aaveAddress = '0x5d3F636136A2ae5f8ACac1A3983D2022683F4905';
    astethAddress = '0xED688fE19Cb62F92fdDAb7Fd9ba06101529F4803';
    ausdcAddress = '0x345EFa1bd1A3A848a4E08Ca600D7c8199a452d12';
    // Local Mocks
    curveAddress = '0x8703Ce0a7994829879E2755767Ce746B349b1E78';
    aaveAddress = '0x73703A2DBB8Cdd31774Fe52D402b969f7F11375e';
    astethAddress = '0x4EB4d5faDB60988283b9c437e127132A58C60fcd';
    ausdcAddress = '0x977cD9b9fd845F1a1dEAf4B2086217576755A99b';
    */

    // Deploy usEthDao.sol
    const usEthDaoContract = await ethers.getContractFactory('usEthDao');
    usEthDao = await usEthDaoContract.deploy();
    //console.log(`    usEthDao deployed to: ${usEthDao.address}`);

    // Deploy usEth.sol
    const usEthContract = await ethers.getContractFactory('usEth');
    usEth = await usEthContract.deploy(lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,curveAddress,usdcAddress,wethAddress,astethAddress,ausdcAddress,usEthDao.address);
    await usEth.deployed();
    //console.log(`    usEth deployed to: ${usEth.address}`);

    // Move some funds around
    usEthDao.setAddress(usEth.address);
    const usedBalance = await usEthDao.balanceOf(owner.address);
    const stakers = usedBalance.div(10).mul(4);
    await usEthDao.transfer(usEth.address, stakers);

    // Set up instances
    lido = new ethers.Contract(lidoAddress, lidoAbi, ethers.provider);
    aave = new ethers.Contract(aaveAddress, aaveAbi, ethers.provider);
    usdc = new ethers.Contract(usdcAddress, usdcAbi, ethers.provider);
    weth = new ethers.Contract(wethAddress, wethAbi, ethers.provider);

  });

  it('LIDO contract is working', async function () {
    const tx1 = await lido.balanceOf(usEth.address);
    expect(tx1).to.be.eq(0);
    const tx2 = await lido.totalSupply();
    expect(tx2).to.be.gt(0);
  });

  it('Curve contract is working', async function () {
    const crvETH = await ethers.provider.getBalance(curveAddress);
    expect(crvETH).to.be.gt(ethers.utils.parseEther('1'));
  });

  it('Deposit ETH', async function () {
    const ethAmount = ethers.utils.parseEther('0.01');
    const usEthBalance1 = await usEth.balanceOf(owner.address);
    const tx = await usEth.deposit({value: ethAmount});
    const usEthAmount = tx.value;
    const usEthBalance2 = await usEth.balanceOf(owner.address);
    expect(usEthBalance2).to.be.gt(usEthBalance1);
    expect(usEthAmount).to.be.gt(0);
  });

  it('Check zeroish balances for usEth contract', async function () {
      const usdcBalance = await usdc.balanceOf(usEth.address);
      expect(usdcBalance).to.be.lt(10);
      const lidoBalance = await lido.balanceOf(usEth.address);
      expect(lidoBalance).to.be.lt(10);
      const ethBalance = await ethers.provider.getBalance(usEth.address);
      expect(ethBalance).to.be.lt(10);
  });

  it('Stake usEth', async function () {
    const usdAmount = ethers.utils.parseEther('2');
    const usEthBalance1 = await usEth.balanceOf(owner.address);
    await usEth.stake(usdAmount);
    const usEthBalance2 = await usEth.balanceOf(owner.address);
    expect(usEthBalance1.sub(usdAmount)).to.be.eq(usEthBalance2);
    const stakedBalance = await usEth.staked(owner.address);
    expect(stakedBalance).to.be.eq(usdAmount);
  });

  it('Test calculateRewards on usEth', async function () {
    await usEth.calculateRewards();
  });

  it('Test rebalance on usEth', async function () {
    await usEth.rebalance();
    const lidoBalance = await lido.balanceOf(usEth.address);
     expect(lidoBalance).to.be.lt(10);
  });
  
  it('Unstake usEth', async function () {
    const usdAmount = ethers.utils.parseEther('1');
    const usEthBalance1 = await usEth.balanceOf(owner.address);
    await usEth.unstake(usdAmount);
    const usEthBalance2 = await usEth.balanceOf(owner.address);
    expect(usEthBalance2).to.be.gt(usEthBalance1);
  });

  it('Withdraw usEth', async function () {
    const usdAmount = ethers.utils.parseEther('10');
    const usEthBalance1 = await usEth.balanceOf(owner.address);
    await usEth.withdraw(usdAmount);
    const usEthBalance2 = await usEth.balanceOf(owner.address);
    expect(usEthBalance2).to.be.lt(usEthBalance1);
  });

  it('Check TVL, totalSupply & totalShares', async function () {
    const tvl = await usEth.tvl();
    const totalSupply = await usEth.totalSupply();
    const totalShares = await usEth.totalShares();
    //console.log(`    tvl: ${tvl} totalSupply: ${totalSupply} totalShares: ${totalShares}`);
    expect(tvl).to.be.gt(0);
    expect(totalSupply).to.be.gt(0);
    expect(totalShares).to.be.gt(0);
  });

  it('Make a donation, simulate staking fees', async function () {
    const ethAmount = ethers.utils.parseEther('0.2');
    const tx = await usEth.deposit({value: ethAmount});
    const usEthAmount = tx.value;
    await usEth.publicBurn(usEthAmount);
    await usEth.rebalance();
    await usEth.calculateRewards();
    expect(usEthAmount).to.be.gt(0);
  });

  it('Check TVL, totalSupply & totalShares again', async function () {
    const tvl = await usEth.tvl();
    const totalSupply = await usEth.totalSupply();
    const totalShares = await usEth.totalShares();
    //console.log(`    tvl: ${tvl} totalSupply: ${totalSupply} totalShares: ${totalShares}`);
    expect(tvl).to.be.gt(0);
    expect(totalSupply).to.be.gt(0);
    expect(totalShares).to.be.gt(0);
  });

  it('Check owner rewards', async function () {
    const rewards = await usEth.stakingBalanceOf(owner.address);
    //console.log(`    rewards: ${rewards}`);
    expect(rewards).to.be.gt(0);
  }); 

  it('Check again for zeroish balances for usEth contract', async function () {
      const usdcBalance = await usdc.balanceOf(usEth.address);
      expect(usdcBalance).to.be.lt(10);
      const lidoBalance = await lido.balanceOf(usEth.address);
      expect(lidoBalance).to.be.lt(10);
      const ethBalance = await ethers.provider.getBalance(usEth.address);
      expect(ethBalance).to.be.lt(10);
  });
});
