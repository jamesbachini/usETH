//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCurve {

  address public tokenIn;

  constructor (address _tokenIn) {
    tokenIn = _tokenIn;
  }

  function exchange(int128 i,int128 j,uint256 dx,uint256 min_dy) external {
      require(address(this).balance > dx, "MockCurve is out of funds :(");
      IERC20(tokenIn).transferFrom(msg.sender,address(this),dx);
      (bool success, ) = msg.sender.call{value: dx}("");
      require(success, "MockCurve ETH transfer failed");
  }

  fallback () external payable {}

}
