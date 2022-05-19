//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

//import "hardhat/console.sol";
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
  uint256 public totalShares;
  address private lidoAddress;
  address private aaveAddress;
  address private chainlinkAddress;
  address private uniswapAddress;
  address private curveAddress;
  address private usdcAddress;
  address private wethAddress;
  address private astethAddress;
  address private ausdcAddress;
  address public usEthDaoAddress;
  address private stakerAddress = 0x0000000000000000000000000000000000005aFE;

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
    _mint(stakerAddress, 1 ether);
    totalShares = 1 ether;
    poolShares[stakerAddress] = 1 ether;
    staked[stakerAddress] = 1 ether;
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
  function deposit() payable public nonReentrant returns (uint256) {
    ILido(lidoAddress).submit{value: msg.value}(usEthDaoAddress);
    uint256 lidoBalance = ILido(lidoAddress).balanceOf(address(this));
    ILido(lidoAddress).approve(aaveAddress, lidoBalance-1); // leave 1 wei to save gas
    IAave(aaveAddress).deposit(lidoAddress,lidoBalance-1,address(this),0);
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 borrowAmount = msg.value * 6 / 10; // 70% collateral to loan - 75% liquidation
    uint256 secondBorrow = msg.value - borrowAmount; // leaves 30% remaining
    IAave(aaveAddress).borrow(wethAddress,borrowAmount,2,0,address(this));
    uint256 approveAllAtOnce = borrowAmount * 2;
    IWEth(wethAddress).approve(uniswapAddress,approveAllAtOnce);
    uint256 usdcBack = swap(wethAddress,usdcAddress,borrowAmount);
    IERC20(usdcAddress).approve(aaveAddress,approveAllAtOnce);
    IAave(aaveAddress).deposit(usdcAddress,usdcBack-1,address(this),0);
    IAave(aaveAddress).borrow(wethAddress,secondBorrow,2,0,address(this));
    uint256 usdcBackAgain = swap(wethAddress,usdcAddress,secondBorrow); // already approved
    uint256 usdcBalance = ILido(usdcAddress).balanceOf(address(this));
    IAave(aaveAddress).deposit(usdcAddress,usdcBalance-1,address(this),0);
    uint256 amountToMint = msg.value * ethDollarPrice;
    uint256 usdcTotal = usdcBack + usdcBackAgain;
    uint usdcNormalised = usdcTotal * 10e11;
    if (usdcNormalised < amountToMint) amountToMint = usdcNormalised;
    _mint(msg.sender, amountToMint);
    return amountToMint;
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
      uint256 diffNormalised = astethNormalised - ausdcNormalised;
      uint diff = diffNormalised / ethDollarPrice / 2;
      IAave(aaveAddress).withdraw(lidoAddress,diff,address(this));
      uint256 lidoBalance = IERC20(lidoAddress).balanceOf(address(this));
      uint256 minLidoBack = lidoBalance * 9 / 10;
      ILido(lidoAddress).approve(curveAddress,lidoBalance);
      ICurve(curveAddress).exchange(1,0,lidoBalance,minLidoBack);
      uint256 ethBalance = address(this).balance;
      IWEth(wethAddress).deposit{value:ethBalance}();
      uint256 halfWeth = ethBalance / 2;
      swap(wethAddress,usdcAddress,halfWeth);
      uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));
      IERC20(usdcAddress).approve(aaveAddress,usdcBalance);
      IAave(aaveAddress).deposit(usdcAddress,usdcBalance,address(this),0);
      IWEth(wethAddress).approve(aaveAddress,halfWeth);
      IAave(aaveAddress).repay(wethAddress,halfWeth,2,address(this));
    }

    if (ausdcNormalised * 9 > astethNormalised * 10) {
      uint256 diffNormalised = ausdcNormalised - astethNormalised;
      uint qtrDiff = diffNormalised / 10e11 / 4;
      IAave(aaveAddress).withdraw(usdcAddress,qtrDiff,address(this));
      IERC20(usdcAddress).approve(uniswapAddress,qtrDiff);
      swap(usdcAddress,wethAddress,qtrDiff);
      uint256 wethBalance = IERC20(wethAddress).balanceOf(address(this));
      IWEth(wethAddress).withdraw(wethBalance);
      ILido(lidoAddress).submit{value: wethBalance}(usEthDaoAddress);
      uint256 stEthBalance = ILido(lidoAddress).balanceOf(address(this));
      ILido(lidoAddress).approve(aaveAddress, stEthBalance);
      IAave(aaveAddress).deposit(lidoAddress,stEthBalance,address(this),0);
      IAave(aaveAddress).borrow(wethAddress,stEthBalance,2,0,address(this));
      swap(wethAddress,usdcAddress,stEthBalance); // already approved
      uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));
      IERC20(usdcAddress).approve(aaveAddress,usdcBalance);
      IAave(aaveAddress).deposit(usdcAddress,usdcBalance,address(this),0);
    }
  }

  function stake(uint256 _amount) public nonReentrant {
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares; // 1 ether used to avoid integer underflow
    require(pricePerShare > 0, "pricePerShare too low");
    uint256 sharesToPurchase = _amount * 1 ether / pricePerShare;
    totalShares += sharesToPurchase;
    _transfer(msg.sender,stakerAddress,_amount);
    poolShares[msg.sender] += sharesToPurchase;
    staked[msg.sender] += _amount;
  }

  function unstake(uint256 _amount) public nonReentrant {
    require(_amount > 0, "Amount to unstake must be greater than zero");
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares;
    require(pricePerShare > 0, "pricePerShare too low");
    uint256 sharesToSell = _amount * 1 ether / pricePerShare;
    require(poolShares[msg.sender] >= sharesToSell, "Not enough poolShares to unstake");
    uint256 stakingBalance = stakingBalanceOf(msg.sender);
    if (stakingBalance > staked[msg.sender]) {
      uint256 capitalGains = stakingBalance - staked[msg.sender];
      uint256 percentageWithdrawal = 1 ether * _amount / staked[msg.sender];
      uint256 adjustedGains = capitalGains / percentageWithdrawal / 1 ether;
      distributeRewards(adjustedGains); // ditribute governance token on usd gains
    }
    totalShares -= sharesToSell;
    poolShares[msg.sender] -= sharesToSell;
    staked[msg.sender] -= _amount;
    _transfer(stakerAddress,msg.sender,_amount);
  }


  function distributeRewards(uint256 _commission) internal {
    uint256 govTokenSupply = IERC20(usEthDaoAddress).balanceOf(address(this));
    if (govTokenSupply < 1 ether) return;
    if (msg.sender == usEthDaoAddress) return;
    uint256 diminishingSupplyFactor =  govTokenSupply * 100 / 400000000 ether; // assumes 400m used allocation for stakers
    uint256 govTokenDistro = _commission * diminishingSupplyFactor ;
    if (govTokenDistro > 0) IERC20(usEthDaoAddress).transfer(msg.sender,govTokenDistro);
  }

 function stakingBalanceOf(address _user) public view returns (uint256) {
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares;
    uint256 stakingBalance = poolShares[_user] *  pricePerShare / 1 ether;
    return stakingBalance;
  }

  function calculateRewards() public nonReentrant {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    uint256 supply = totalSupply();
    if (usdTVL > supply) {
      uint256 profit = usdTVL - supply;
      uint256 fee = profit / 10;
      uint256 remaining = profit - fee;
       _mint(usEthDaoAddress, fee);
      _mint(stakerAddress, remaining);
    }
  }

  function tvl() public view returns (uint256) {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    return usdTVL;
  }

  function publicBurn(uint256 _amount) public {
    _burn(msg.sender, _amount);
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
  }


  fallback() external payable {}
  receive() external payable {}
}
