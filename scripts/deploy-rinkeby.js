const hre = require("hardhat");
const lidoAbi = require('./../abis/lido.json');
const aaveAbi = require('./../abis/aave.json');
const usdcAbi = require('./../abis/usdc.json');
const wethAbi = require('./../abis/weth.json');
const mockAaveAbi = require('./../abis/mockaave.json');
const mockERC20Abi = require('./../abis/mockerc20.json');

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

async function main() {
  [owner,user1] = await ethers.getSigners();
  // Rinkeby addresses
  lidoAddress = '0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD';
  chainlinkAddress = '0x8A753747A1Fa494EC906cE90E9f37563A8AF630e';
  usdcAddress = '0xeb8f08a975Ab53E34D8a0330E0D34de942C95926';
  wethAddress = '0xc778417E063141139Fce010982780140Aa0cD5Ab';

  const ownerBalance = await ethers.provider.getBalance(owner.address);
  console.log(`    Owner: ${owner.address} Balance: ${ethers.utils.formatEther(ownerBalance)} ETH`);
  await hre.run('compile');

  // Deploy Mock Curve
  const mockCurveContract = await ethers.getContractFactory('MockCurve');
  mockCurve = await mockCurveContract.deploy();
  await mockCurve.deployed();
  curveAddress = mockCurve.address;
  console.log(`curveAddress = '${mockCurve.address}';`);
  const curveETH = ownerBalance.div(5);
  await owner.sendTransaction({
    to: mockCurve.address,
    value: curveETH,
  });

  // Deploy Mock Aave
  const mockAaveContract = await ethers.getContractFactory('MockAave');
  mockAave = await mockAaveContract.deploy();
  await mockAave.deployed();
  aaveAddress = mockAave.address;
  console.log(`aaveAddress = '${mockAave.address}';`);

  // Create Instances
  lido = new ethers.Contract(lidoAddress, lidoAbi, owner);
  aave = new ethers.Contract(aaveAddress, mockAaveAbi, owner);
  usdc = new ethers.Contract(usdcAddress, usdcAbi, owner);
  weth = new ethers.Contract(wethAddress, wethAbi, owner);
  const aaveWETH = ownerBalance.div(4);
  await weth.deposit({value:aaveWETH});
  await weth.transfer(mockAave.address,aaveWETH);

  // Deploy Mock astETH
  const erc20Contract = await ethers.getContractFactory('MockERC20');
  asteth = await erc20Contract.deploy();
  console.log(`astethAddress = '${asteth.address}';`);
  astethAddress = asteth.address;
  await aave.setToken(lidoAddress,asteth.address,ethers.utils.parseEther('1'));
  astethi = new ethers.Contract(astethAddress, mockERC20Abi, owner);
  await astethi.transfer(aaveAddress,ethers.utils.parseEther('1000000000'));

  // Deploy Mock aUSDC
  ausdc = await erc20Contract.deploy();
  console.log(`ausdcAddress = '${ausdc.address}';`);
  ausdcAddress = ausdc.address;
  await aave.setToken(usdcAddress,ausdc.address,ethers.utils.parseEther('0.0005')); // 1 ETH = $2000
  ausdci = new ethers.Contract(ausdcAddress, mockERC20Abi, owner);
  await ausdci.transfer(aaveAddress,ethers.utils.parseEther('1000000000'));
  
    // Deploy usEthDao.sol
    const usEthDaoContract = await ethers.getContractFactory('usEthDao');
    usEthDao = await usEthDaoContract.deploy();
    console.log(`    usEthDao deployed to: ${usEthDao.address}`);

    // Deploy usEth.sol
    const usEthContract = await ethers.getContractFactory('usEth');
    usEth = await usEthContract.deploy(lidoAddress,aaveAddress,chainlinkAddress,uniswapAddress,curveAddress,usdcAddress,wethAddress,astethAddress,ausdcAddress,usEthDao.address);
    await usEth.deployed();
    console.log(`    usEth deployed to: ${usEth.address}`);

    // Move some funds around
    await usEthDao.setAddress(usEth.address);
    const usedBalance = await usEthDao.balanceOf(owner.address);
    const stakers = usedBalance.div(10).mul(4);
    await usEthDao.transfer(usEth.address, stakers);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
