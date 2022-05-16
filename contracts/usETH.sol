//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
	address lidoAddress;
	address aaveAddress;
	address chainlinkAddress;
	address usdcAddress;
	address wethAddress;

	constructor(address _lidoAddress, address _aaveAddress, address _chainlinkAddress, address _usdcAddress, address _wethAddress) ERC20("USD  Ether", "usETH") {
		lidoAddress = _lidoAddress;
		aaveAddress = _aaveAddress;
		chainlinkAddress = _chainlinkAddress;
		usdcAddress = _usdcAddress;
		wethAddress = _wethAddress;
	}

	function deposit() payable public {
		uint256 stEthCollateral = ILido(lidoAddress).submit{value: msg.value}(address(this));
		ILido(lidoAddress).approve(aaveAddress, stEthCollateral);
		IAave(aaveAddress).deposit(lidoAddress,stEthCollateral,address(this),0);
		int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
		uint256 ethPrice = uint256(ethPriceInt) / 10e7;
		uint256 usdAmount = stEthCollateral * ethPrice / 10e11 / 2; // 50% collateral to loan - 75% liquidation
		IAave(aaveAddress).borrow(usdcAddress,usdAmount,2,0,address(this));
		// Set up short position
		_mint(msg.sender, msg.value); // 1 ETH = 1 usETH
	}

	function withdraw() public {

	}
	
}
