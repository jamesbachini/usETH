//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ILido is IERC20 {
  function submit(address _referral) external payable returns (uint256 StETH);
  function withdraw(uint256 _amount, bytes32 _pubkeyHash) external; // wont be available until post-merge
  function sharesOf(address _owner) external returns (uint balance);
}

interface IWEth is IERC20 {
  function withdraw(uint256 wad) external;
  function deposit() external payable;
}

interface IAave {
  function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
  function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external;
  function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256);
  function withdraw(address asset,uint256 amount,address to) external returns (uint256);
  function getUserAccountData(address user) external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
}

interface EACAggregatorProxy {
  function latestAnswer() external view returns (int256);
}

interface ICurve {
  function exchange(int128 i,int128 j,uint256 dx,uint256 min_dy) external;
}

contract usEth is ERC20, ReentrancyGuard {
  mapping(address => uint256) public staked;
  mapping(address => uint256) public poolShares;
  uint256 public totalStaked = 0;
  uint256 public rewardsPool = 1e18;
  address public lidoAddress;
  address public aaveAddress;
  address public chainlinkAddress;
  address public uniswapAddress;
  address public curveAddress;
  address public usdcAddress;
  address public wethAddress;
  address public astethAddress;
  address public ausdcAddress;
  address public usEthDaoAddress;

  constructor(address _lidoAddress, address _aaveAddress, address _chainlinkAddress, address _uniswapAddress, address _curveAddress, address _usdcAddress, address _wethAddress, address _astethAddress, address _ausdcAddress, address _usEthDaoAddress) ERC20("USD  Ether", "usETH") {
    lidoAddress = _lidoAddress;
    aaveAddress = _aaveAddress;
    chainlinkAddress = _chainlinkAddress;
    uniswapAddress = _uniswapAddress;
    curveAddress = _curveAddress;
    usdcAddress = _usdcAddress;
    wethAddress = _wethAddress;
    astethAddress = _astethAddress;
    ausdcAddress = _ausdcAddress;
    usEthDaoAddress = _usEthDaoAddress;
    _mint(usEthDaoAddress, 100 ether); // Send $100 to Dao to avoid error
  }

  function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns (uint256) {
    uint24 poolFee = 3000; // reduce to 500 for usdc-eth?
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
        tokenIn: _tokenIn,
        tokenOut: _tokenOut,
        fee: poolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    uint256 amountOut = ISwapRouter(uniswapAddress).exactInputSingle(params);
    return amountOut;
  }

  /*
  1. Convert ETH > stETH
  2. Deposit stETH > Aave
  3. Borrow wETH
  4. Sell wETH for USDC
  5. Deposit USDC > Aave
  6. Repeat so borrow ETH matches deposited stETH
  */
  function deposit() payable public nonReentrant {
    uint256 stEthCollateral = ILido(lidoAddress).submit{value: msg.value}(usEthDaoAddress);
    ILido(lidoAddress).approve(aaveAddress, stEthCollateral);
    IAave(aaveAddress).deposit(lidoAddress,stEthCollateral,address(this),0);
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    //uint256 usdEthValue = stEthCollateral * ethDollarPrice / 10e11;
    uint256 borrowAmount = stEthCollateral * 7 / 10; // 70% collateral to loan - 75% liquidation
    uint256 secondBorrow = stEthCollateral - borrowAmount; // leaves 30% remaining
    IAave(aaveAddress).borrow(wethAddress,borrowAmount,2,0,address(this));
    uint256 approveAllAtOnce = borrowAmount * 2;
    IWEth(wethAddress).approve(uniswapAddress,approveAllAtOnce);
    uint256 usdcBack = swap(wethAddress,usdcAddress,borrowAmount);
    IERC20(usdcAddress).approve(aaveAddress,usdcBack);
    IAave(aaveAddress).deposit(usdcAddress,usdcBack,address(this),0);
    IAave(aaveAddress).borrow(wethAddress,secondBorrow,2,0,address(this));
    uint256 usdcBackAgain = swap(wethAddress,usdcAddress,secondBorrow); // already approved
    IERC20(usdcAddress).approve(aaveAddress,usdcBackAgain);
    IAave(aaveAddress).deposit(usdcAddress,usdcBackAgain,address(this),0);
    uint256 amountToMint = msg.value * ethDollarPrice;
    uint256 usdcTotal = usdcBack + usdcBackAgain;
    uint usdcNormalised = usdcTotal * 10e11;
    if (usdcNormalised < amountToMint) amountToMint = usdcNormalised;
    _mint(msg.sender, amountToMint);
  }

  /*
    Deposit: 1ETH = $2000
    Collateral 1 stETH & 2000 USDC
    Borrowed 1 WETH

    Withdraw $1000
    Collateral 0.5 stETH & 1000USDC
    Borrowed 0.5ETH
  */
  function withdraw(uint256 _amount) public nonReentrant {
    uint256 supply = totalSupply();
    uint256 maxWithdrawPerTransaction = supply / 2;
    require(_amount < maxWithdrawPerTransaction, "Exceeds maximum withdrawal per transaction");
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    _burn(msg.sender, _amount);
    uint256 usdcOut = _amount / 10e11;
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 lidoOut = _amount / ethDollarPrice;

    // USDC side
    IAave(aaveAddress).withdraw(usdcAddress,usdcOut,address(this));
    IERC20(usdcAddress).approve(uniswapAddress,usdcOut);
    uint256 wethBack = swap(usdcAddress,wethAddress,usdcOut);
    IWEth(wethAddress).approve(aaveAddress,wethBack);
    IAave(aaveAddress).repay(wethAddress,wethBack,2,address(this));

    // stETH side
    IAave(aaveAddress).withdraw(lidoAddress,lidoOut,address(this));
    IERC20(lidoAddress).approve(uniswapAddress,lidoOut);
    uint256 minLidoBack = lidoOut * 9 / 10;
    ILido(lidoAddress).approve(curveAddress,lidoOut);
    ICurve(curveAddress).exchange(1,0,lidoOut,minLidoBack); // returns ETH
    if (address(this).balance < wethBack) wethBack = address(this).balance;
    (bool success, ) = msg.sender.call{value: wethBack}("");
    require(success, "ETH transfer on withdrawal failed");
  }

  /*
    As price of ETH fluctuates our collateral could become skewed.
    Ideally we want to keep a balanced amount of stETH and USDC
  */
  function rebalance() public nonReentrant {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 astethBalance = IERC20(astethAddress).balanceOf(address(this));
    uint256 ausdcBalance = IERC20(ausdcAddress).balanceOf(address(this));
    uint256 astethNormalised = astethBalance * ethDollarPrice;
    uint256 ausdcNormalised = ausdcBalance  * 10e11;

    if (astethNormalised * 9 > ausdcNormalised * 10) { // rebalance @ ~10% to avoid frequent MEV sandwich
      console.log('too much asteth');
      uint256 diffNormalised = astethNormalised - ausdcNormalised;
      uint diff = diffNormalised / ethDollarPrice / 2;
      IAave(aaveAddress).withdraw(lidoAddress,diff,address(this));
      uint256 minLidoBack = diff * 9 / 10;
      ILido(lidoAddress).approve(curveAddress,diff);
      ICurve(curveAddress).exchange(1,0,diff,minLidoBack);
      uint256 ethBalance = address(this).balance;
      IWEth(wethAddress).deposit{value:ethBalance}();
      uint256 halfWeth = ethBalance / 2;
      uint256 usdcBack = swap(wethAddress,usdcAddress,halfWeth);
      IERC20(usdcAddress).approve(aaveAddress,usdcBack);
      IAave(aaveAddress).deposit(usdcAddress,usdcBack,address(this),0);
      IWEth(wethAddress).approve(aaveAddress,halfWeth);
      IAave(aaveAddress).repay(wethAddress,halfWeth,2,address(this));
    }

    if (ausdcNormalised * 9 > astethNormalised * 10) {
      console.log('too much ausdc');
      uint256 diffNormalised = ausdcNormalised - astethNormalised;
      uint qtrDiff = diffNormalised / 10e11 / 4;
      IAave(aaveAddress).withdraw(usdcAddress,qtrDiff,address(this));
      IERC20(usdcAddress).approve(uniswapAddress,qtrDiff);
      uint256 wethBack = swap(usdcAddress,wethAddress,qtrDiff);
      IWEth(wethAddress).withdraw(wethBack);
      uint256 stEthCollateral = ILido(lidoAddress).submit{value: wethBack}(usEthDaoAddress);
      ILido(lidoAddress).approve(aaveAddress, stEthCollateral);
      IAave(aaveAddress).deposit(lidoAddress,stEthCollateral,address(this),0);
      IAave(aaveAddress).borrow(wethAddress,stEthCollateral,2,0,address(this));
      uint256 usdcBack = swap(wethAddress,usdcAddress,stEthCollateral); // already approved
      IERC20(usdcAddress).approve(aaveAddress,usdcBack);
      IAave(aaveAddress).deposit(usdcAddress,usdcBack,address(this),0);
    }
  }

  function depositUSDC(uint256 _amount) public nonReentrant {
    uint256 startBalance = IERC20(usdcAddress).balanceOf(address(this));
    IERC20(usdcAddress).transferFrom(msg.sender,address(this),_amount);
    uint256 endBalance = IERC20(usdcAddress).balanceOf(address(this));
    require (endBalance >= startBalance + _amount, "USDC not transferred, check balance and approval");
    IERC20(usdcAddress).approve(aaveAddress,_amount);
    IAave(aaveAddress).deposit(usdcAddress,_amount,address(this),0);
    rebalance();
    _mint(msg.sender, _amount);
  }

  function withdrawUSDC(uint256 _amount) public nonReentrant {
    uint256 supply = totalSupply();
    uint256 maxWithdrawPerTransaction = supply / 4;
    require(_amount < maxWithdrawPerTransaction, "Exceeds maximum withdrawal per transaction");
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    _burn(msg.sender, _amount);
    IAave(aaveAddress).withdraw(usdcAddress,_amount,address(this));
    rebalance();
    IERC20(usdcAddress).transfer(msg.sender, _amount);
  }

  /*
    $2 in pool / $10 staked = $0.2/share
    someone adds $2
    x / $12 = $0.2/share
    12 * 0.2 = $2.4 in pool
  */
  function stake(uint256 _amount) public nonReentrant {
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    _burn(msg.sender, _amount);
    totalStaked += _amount;
    staked[msg.sender] += _amount;
    uint256 pricePerShare = rewardsPool * 10000 / totalStaked; // overflow?
    uint256 sharesPurchased = _amount / pricePerShare / 10000;
    poolShares[msg.sender] += sharesPurchased;
    uint256 dilutionCompensation = totalStaked * pricePerShare / 10000;
    rewardsPool += dilutionCompensation;
  }

  function unstake(uint256 _amount) public nonReentrant {
    require(staked[msg.sender] >= _amount, "Not enough funds to unstake");
    staked[msg.sender] -= _amount;
    uint256 pricePerShare = rewardsPool * 10000 / totalStaked;
    uint256 sharesSold = _amount / pricePerShare / 10000;
    require(poolShares[msg.sender] >= sharesSold, "Not enough poolShares to unstake");
    poolShares[msg.sender] -= sharesSold;
    uint256 stakingRewards = sharesSold * pricePerShare / 10000;
    totalStaked -= _amount;
    rewardsPool -= stakingRewards;
    uint256 totalToPayOut = stakingRewards + _amount;
    _mint(msg.sender, totalToPayOut);
    uint256 used = IERC20(usEthDaoAddress).balanceOf(address(this));
    if (used >= stakingRewards) {
      IERC20(usEthDaoAddress).transfer(msg.sender,stakingRewards); // more or less?
    }
  }

  function rewardsOf(address _user) public view returns (uint256) {
    uint256 pricePerShare = rewardsPool * 10000 / totalStaked ;
    uint256 stakingRewards = poolShares[_user] * pricePerShare / 10000;
    return stakingRewards;
  }

  function calculateRewards() public nonReentrant {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    uint256 supply = totalSupply();
    uint256 usdSupply = totalStaked + supply;
    if (usdSupply > usdTVL - rewardsPool) {
      uint256 profit = usdSupply - usdTVL - rewardsPool;
      uint256 fee = profit / 10;
      uint256 remaining = profit - fee;
      rewardsPool += remaining;
      _mint(usEthDaoAddress, fee);
    }
  }

  fallback () external payable {}

}
