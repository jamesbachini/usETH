const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('poolMechanics', function () {
  let totalShares = 0;
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
    let pricePerShare = balance[stakerAddress]  * 100 / totalShares;
    sharesToPurchase = _amount * 100 / pricePerShare;
    if (!poolShares[_from]) poolShares[_from] = 0;
    totalShares += sharesToPurchase;
    _transfer(_from,stakerAddress,_amount);
    poolShares[_from] += sharesToPurchase;
  }

  const unstake = (_from, _amount) => {
    let pricePerShare = balance[stakerAddress] * 100 / totalShares;
    let sharesToSell = _amount  * 100 / pricePerShare;
    if (!poolShares[_from] >= sharesToSell) throw "Not enough poolShares to unstake";
    totalShares -= sharesToSell;
    poolShares[_from] -= sharesToSell;
    if (balance[stakerAddress] < _amount) throw "stakersBalance too low";
    _transfer(stakerAddress,_from,_amount);
  }

  const stakingBalanceOf = (_user) => {
    let pricePerShare = balance[stakerAddress] * 100 / totalShares;
    let stakingBalance = poolShares[_user]  * pricePerShare / 100;
    return stakingBalance;
  }

  const reset = () => {
    totalShares = 1;
    balance = {};
    poolShares = {};
    balance['alice'] = 100;
    balance['bob'] = 100;
    balance['carlos'] = 100;
    balance[stakerAddress] = 1;
    poolShares[stakerAddress] = 1;
  }

  before(async () => {
    reset();
  });

  it('Try staking and unstaking', async function () {
    stake('alice',50);
    unstake('alice',50);
    expect(balanceOf('alice')).to.be.eq(100);
  });

  it('Add in some rewards', async function () {
    stake('alice',50);
    balance[stakerAddress] += 10;
    expect(stakingBalanceOf('alice')).to.be.gt(59.8);
    unstake('alice',stakingBalanceOf('alice'));
    expect(balanceOf('alice')).to.be.gt(109.8);
    expect(poolShares['alice']).to.be.lt(1);
  });

  it('Bob wants to get involved', async function () {
    reset();
    stake('alice',50);
    balance[stakerAddress] += 10;
    stake('bob',50);
    balance[stakerAddress] += 10;
    const debt = stakingBalanceOf('alice') + stakingBalanceOf('bob');
    expect(debt).to.be.gt(119);
    expect(debt).to.be.lt(121);
    expect(stakingBalanceOf('alice')).to.be.gt(65);
    expect(stakingBalanceOf('bob')).to.be.gt(54.5); // slight slippage effect
    unstake('alice',stakingBalanceOf('alice'));
    unstake('bob',stakingBalanceOf('bob'));
    expect(balanceOf('alice')).to.be.gt(115);
    expect(balanceOf('bob')).to.be.gt(104.5);
  });

  it('Try a bigger pool with initial liquidity provision', async function () {
    reset();
    stake('alice',500000);
    balance[stakerAddress] += 10;
    stake('bob',50);
    balance[stakerAddress] += 10;
    const debt = stakingBalanceOf('alice') + stakingBalanceOf('bob');
    expect(debt).to.be.gt(500069);
    expect(stakingBalanceOf('alice')).to.be.gt(500019);
    expect(stakingBalanceOf('bob')).to.be.gt(50); // slight slippage effect
    unstake('alice',stakingBalanceOf('alice'));
    unstake('bob',stakingBalanceOf('bob'));
  });

  it('Final balances', async function () {
    //console.log(balance,poolShares);
  });
});
