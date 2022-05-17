//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface ILido is IERC20 {
  function submit(address _referral) external payable returns (uint256 StETH);
  function withdraw(uint256 _amount, bytes32 _pubkeyHash) external; // wont be available until post-merge
  function sharesOf(address _owner) external returns (uint balance);
}

interface IWEth is IERC20 {
  function withdraw(uint256 wad) external;
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

contract usEth is ERC20 {
  mapping(address => uint256) public staked;
  uint256 public totalStaked = 0;
  address public lidoAddress;
  address public aaveAddress;
  address public chainlinkAddress;
  address public uniswapAddress;
  address public curveAddress;
  address public usdcAddress;
  address public wethAddress;

  constructor(address _lidoAddress, address _aaveAddress, address _chainlinkAddress, address _uniswapAddress, address _curveAddress, address _usdcAddress, address _wethAddress) ERC20("USD  Ether", "usETH") {
    lidoAddress = _lidoAddress;
    aaveAddress = _aaveAddress;
    chainlinkAddress = _chainlinkAddress;
    uniswapAddress = _uniswapAddress;
    curveAddress = _curveAddress;
    usdcAddress = _usdcAddress;
    wethAddress = _wethAddress;
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
  function deposit() payable public {
    uint256 stEthCollateral = ILido(lidoAddress).submit{value: msg.value}(address(this));
    ILido(lidoAddress).approve(aaveAddress, stEthCollateral);
    IAave(aaveAddress).deposit(lidoAddress,stEthCollateral,address(this),0);
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 usdEthValue = stEthCollateral * ethDollarPrice / 10e11;
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
    // 2do add check to see if usdcBackAgain price is lower than usdEthValue to avoid MEV/arbitrage
    uint256 amountToMint = msg.value * ethDollarPrice;
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
  function withdraw(uint256 _amount) public {
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
    uint256 minLidoBack = lidoOut / 10 * 9;
    ILido(lidoAddress).approve(curveAddress,lidoOut);
    console.log(address(this).balance);
    ICurve(curveAddress).exchange(1,0,lidoOut,minLidoBack); // returns ETH
    if (address(this).balance < wethBack) wethBack = address(this).balance;
    (bool success, ) = msg.sender.call{value: wethBack}("");
    require(success, "ETH transfer on withdrawal failed");
    // checkRebalance();
  }

  function checkRebalance() public {
    //(uint256 totalCollateralETH,uint256 totalDebtETH,uint256 availableBorrowsETH,uint256 currentLiquidationThreshold,uint256 ltv,uint256 healthFactor) = IAave(aaveAddress).getUserAccountData(address user)
    // Need to add renbalancing once lido withdraw function becomes available
  }

  function stake(uint256 _amount) public {
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    _burn(msg.sender, _amount);
    totalStaked += _amount;
    staked[msg.sender] += _amount;
  }

  function unstake(uint256 _amount) public {
    require(staked[msg.sender] >= _amount, "Not enough usETH staked");
    staked[msg.sender] -= _amount;
    totalStaked -= _amount;
    _mint(msg.sender, _amount);
  }

  function distributeRewards() public {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    uint256 supply = totalSupply();
    uint256 usdSupply = totalStaked + supply;
    if (usdSupply > usdTVL) {
      uint256 profit = usdSupply - usdTVL;
      uint256 profitPerShare = profit / totalStaked;
      require(profitPerShare > 0, "No profits to be distributed");
      // need a way to send out with out exceeding transaction gas limits
    }
  }

  fallback () external payable {}

}
