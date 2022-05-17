// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract usEthDao is ERC20, Ownable, ReentrancyGuard {

    address public usEthAddress;
    uint256 private supply = 1000000000 ether; // 1b
    mapping(address => uint256) public staked;
    mapping(address => uint256) public poolShares;
    uint256 public totalStaked = 0;

    constructor() ERC20("usETH DAO", "USED") {
      _mint(msg.sender, supply);
    }

  function setAddress(address _usEth) external onlyOwner {
    require (usEthAddress == address(0x0), "Can only set once");
    usEthAddress = _usEth;
  }

  function withdrawReferrals(address _token, uint256 _amount) external onlyOwner {
    require(_token != usEthAddress, "Please do not rug pull");
    IERC20(_token).transfer(msg.sender, _amount);
  }

  function stake(uint256 _amount) public nonReentrant {
    require(balanceOf(msg.sender) >= _amount, "Not enough USED balance");
    _burn(msg.sender, _amount);
    totalStaked += _amount;
    staked[msg.sender] += _amount;
    uint256 rewardsPool = IERC20(usEthAddress).balanceOf(address(this));
    if (rewardsPool <= 0) rewardsPool = 1 ether;
    uint256 pricePerShare = rewardsPool * 1000000 / totalStaked;
    uint256 sharesPurchased = _amount / pricePerShare / 1000000;
    poolShares[msg.sender] += sharesPurchased;
    uint256 dilutionCompensation = totalStaked * pricePerShare / 1000000;
    rewardsPool += dilutionCompensation;
  }

  function unstake(uint256 _amount) public nonReentrant {
    require(staked[msg.sender] >= _amount, "Not enough funds to unstake");
    staked[msg.sender] -= _amount;
    uint256 rewardsPool = IERC20(usEthAddress).balanceOf(address(this));
    require(rewardsPool * 1000000 >= totalStaked, "Not enough rewards in pool to claim");
    uint256 pricePerShare = rewardsPool * 1000000 / totalStaked;
    uint256 sharesSold = _amount / pricePerShare / 1000000;
    require(poolShares[msg.sender] >= sharesSold, "Not enough poolShares to unstake");
    poolShares[msg.sender] -= sharesSold;
    uint256 stakingRewards = sharesSold * pricePerShare / 1000000;
    totalStaked -= _amount;
    rewardsPool -= stakingRewards;
    _mint(msg.sender, _amount);
    IERC20(usEthAddress).transfer(msg.sender, stakingRewards);
  }
 
  function rewardsOf(address _user) public view returns (uint256) {
    uint256 rewardsPool = IERC20(usEthAddress).balanceOf(address(this));
    uint256 pricePerShare = rewardsPool * 1000000 / totalStaked ;
    uint256 stakingRewards = poolShares[_user] * pricePerShare / 1000000;
    return stakingRewards;
  }


}
