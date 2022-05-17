//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAave {
  mapping(address => address) public aToken;
  mapping(address => uint256) public tokenValue; // in Eth
  mapping(address => uint256) public collateral; // in Wei

  function setToken (address _realToken, address _aToken, uint256 _ethValue) external {
    aToken[_realToken] = _aToken;
    tokenValue[_realToken] = _ethValue;
  }

  function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external {
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    IERC20(aToken[asset]).transfer(msg.sender, amount);
    collateral[msg.sender] += (tokenValue[asset] * amount);
  }

  function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external {
    IERC20(asset).transfer(msg.sender, amount);
    collateral[msg.sender] -= (tokenValue[asset] * amount);
  }

  function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256){
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    collateral[msg.sender] += (tokenValue[asset] * amount);
  }

  function withdraw(address asset,uint256 amount,address to) external returns (uint256) {
    IERC20(asset).transfer(msg.sender, amount);
    //IERC20(aToken[asset]).transferFrom(msg.sender, address(this), amount);
    collateral[msg.sender] -= (tokenValue[asset] * amount);

  }
  
  function getUserAccountData(address user) external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) {
    return (collateral[msg.sender],0,0,0,0,0);
  }

}
