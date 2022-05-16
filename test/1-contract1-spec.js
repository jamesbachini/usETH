const { expect } = require('chai');
const { ethers } = require('hardhat');
const lidoAbi = require('./../abis/lido.json');
const aaveAbi = require('./../abis/aave.json');
const usdcAbi = require('./../abis/usdc.json');
const wethAbi = require('./../abis/weth.json');

// Mainnet
const lidoAddress = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84';
const aaveAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
const chainlinkAddress = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
const uniswapAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
const usdcAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';

describe('usETH', function () {
  let usETH, lido, aave, weth;

  before(async () => {
    [owner,user1] = await ethers.getSigners();
    const sponsor = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider);
    await sponsor.sendTransaction({ to: owner.address, value: ethers.utils.parseEther('2') });
    const ownerBalance = await ethers.provider.getBalance(owner.address);
    console.log(`    Owner: ${owner.address} Balance: ${ethers.utils.formatEther(ownerBalance)} ETH`);
    await hre.run('compile');
    const usETHContract = await ethers.getContractFactory('usETH');
    usETH = await usETHContract.deploy(lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,usdcAddress,wethAddress);
    await usETH.deployed();
    console.log(`    usETH deployed to: ${usETH.address}`);
    lido = new ethers.Contract(lidoAddress, lidoAbi, ethers.provider);
    aave = new ethers.Contract(aaveAddress, aaveAbi, ethers.provider);
    usdc = new ethers.Contract(usdcAddress, usdcAbi, ethers.provider);
    weth = new ethers.Contract(wethAddress, wethAbi, ethers.provider);
  });

  it('LIDO contract is working', async function () {
    const tx1 = await lido.balanceOf(usETH.address);
    expect(tx1).to.be.eq(0);
    const tx2 = await lido.totalSupply();
    expect(tx2).to.be.gt(0);
  });

  it('Deposit ETH', async function () {
    const tx1 = await usETH.deposit({value: ethers.utils.parseEther('0.01')});
  });

  it('Check stETH balance on usETH contract', async function () {
    const tx1 = await lido.balanceOf(usETH.address);
    expect(tx1).to.be.gt(0);
  });

  it('Check usETH balance for owner', async function () {
    const usEthBalance = await usETH.balanceOf(owner.address);
    expect(usEthBalance).to.be.gt(0);
  });

  it('Check USDC balance for usETH contract', async function () {
      //const accountData = await aave.getUserAccountData(owner.address);
      //console.log(accountData);
      const usdcBalance = await usdc.balanceOf(usETH.address);
      expect(usdcBalance).to.be.eq(0);
  });


});
