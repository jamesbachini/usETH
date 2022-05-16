//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface ILido {
	function submit(address _referral) external payable returns (uint256 StETH);
	function withdraw(uint256 _amount, bytes32 _pubkeyHash) external; // wont be available until post-merge
	function balanceOf(address _owner) external returns (uint balance);
	function sharesOf(address _owner) external returns (uint balance);
	function totalSupply() external returns (uint balance);
	function transfer(address _to, uint _value) external returns (bool success);
	function approve(address _spender, uint _value) external returns (bool success);
	function depositBufferedEther() external;
}

interface IAave {
	function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
	function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external;
	function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256);
	function withdraw(address asset,uint256 amount,address to) external returns (uint256);
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
}

interface EACAggregatorProxy {
  function latestAnswer() external view returns (int256);
}

contract usETH is ERC20 {
	address public lidoAddress;
	address public aaveAddress;
	address public chainlinkAddress;
	address public uniswapAddress;
	address public usdcAddress;
	address public wethAddress;

	constructor(address _lidoAddress, address _aaveAddress, address _chainlinkAddress, address _uniswapAddress, address _usdcAddress, address _wethAddress) ERC20("USD  Ether", "usETH") {
		lidoAddress = _lidoAddress;
		aaveAddress = _aaveAddress;
		chainlinkAddress = _chainlinkAddress;
		uniswapAddress = _uniswapAddress;
		usdcAddress = _usdcAddress;
		wethAddress = _wethAddress;
	}

	function swap(uint256 _amountIn) internal returns (uint256) {
		uint24 poolFee = 500;
		ISwapRouter.ExactInputSingleParams memory params =
			ISwapRouter.ExactInputSingleParams({
				tokenIn: wethAddress,
				tokenOut: usdcAddress,
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
		IERC20(wethAddress).approve(uniswapAddress,approveAllAtOnce);
		uint256 usdcBack = swap(borrowAmount);
		IERC20(usdcAddress).approve(aaveAddress,usdcBack);
		IAave(aaveAddress).deposit(usdcAddress,usdcBack,address(this),0);
		IAave(aaveAddress).borrow(wethAddress,secondBorrow,2,0,address(this));
		uint256 usdcBackAgain = swap(secondBorrow); // already approved
		IERC20(usdcAddress).approve(aaveAddress,usdcBackAgain);
		IAave(aaveAddress).deposit(usdcAddress,usdcBackAgain,address(this),0);
		// 2do add check to see if usdcBackAgain price is lower than usdEthValue to avoid MEV/arbitrage
		uint256 amountToMint = usdEthValue * 1e18;
		_mint(msg.sender, amountToMint);
	}

	function withdraw() public {

	}
	
}
