//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract FakeAave {
  function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external {
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
  }

  function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external {
    IERC20(asset).transfer(msg.sender, amount);
  }

  function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256){
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
  }

  function withdraw(address asset,uint256 amount,address to) external returns (uint256) {
    IERC20(asset).transfer(msg.sender, amount);
  }
  
  function getUserAccountData(address user) external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) {
    return (1000000000000000000,0,0,0,0,0);
  }

}
