const { expect } = require('chai');
const { ethers } = require('hardhat');

describe.only('poolMechanics', function () {
  let totalStaked = 0;
  let rewardsPool = 1;
  let staked = {};
  let poolShares = {};
  let balance = {};
  let stakerAddress = 'staker';

  const _transfer = (_from, _to, _amount) => {
    if (!balance[_from] >= _amount) throw "Not enough usETH balance";
    if (!balance[_to]) balance[_to] = 0;
    balance[_from] -= _amount;
    balance[_to] += _amount;
  }

  const balanceOf = (_who) => {
    return balance[_who] || 0;
  }

  const stake = (_from, _amount) => {
    if (!balance[_from] >= _amount) throw "Not enough usETH balance";
    _transfer(_from,stakerAddress,_amount);
    totalStaked += _amount;
    if (!staked[_from]) staked[_from] = 0;
    staked[_from] += _amount;
    let pricePerShare = rewardsPool * 1000000 / totalStaked; // overflow?
    let sharesPurchased = _amount / pricePerShare / 1000000;
    if (!poolShares[_from]) poolShares[_from] = 0;
    poolShares[_from] += sharesPurchased;
    let dilutionCompensation = totalStaked * pricePerShare / 1000000;
    rewardsPool += dilutionCompensation;
  }

  const unstake = (_from, _amount) => {
    if (!staked[_from] >= _amount) throw "Not enough funds to unstake";
    staked[_from] -= _amount;
    let pricePerShare = rewardsPool * 1000000 / totalStaked;
    let sharesSold = _amount / pricePerShare / 1000000;
    if (!poolShares[_from] >= sharesSold) throw "Not enough poolShares to unstake";
    poolShares[_from] -= sharesSold;
    let stakingRewards = sharesSold * pricePerShare / 1000000;
    totalStaked -= _amount;
    rewardsPool -= stakingRewards;
    let totalToPayOut = stakingRewards + _amount;
    let stakersBalance = balanceOf(stakerAddress);
    if (stakersBalance < totalToPayOut) throw "stakersBalance too low";
    _transfer(stakerAddress,_from,totalToPayOut);
  }

  before(async () => {
    // reset completely before each test
    totalStaked = 0;
    rewardsPool = 1;
    staked = {};
    poolShares = {};
    balance = {};
    balance['alice'] = 100;
    balance['bob'] = 100;
  });


  it('Try staking and unstaking', async function () {
    stake('alice',50);
    unstake('alice',50);
    expect(usedBalance2).to.be.eq(0);
  });

});
