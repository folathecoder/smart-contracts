const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Token Contract', function () {
  let token, owner, user1, user2, user3;

  beforeEach(async function () {
    const Token = await ethers.getContractFactory('Token');
    [owner, user1, user2, user3] = await ethers.getSigners();
    token = await Token.deploy();

    // Mint 100k tokens to deployer account
    await token.mint(owner.address, 100000);

    // Mint 5k tokens to other accounts
    await token.mint(user1.address, 5000);
    await token.mint(user2.address, 5000);
    await token.mint(user3.address, 5000);
  });

  it('Deploy your contract from the deployer account', async function () {
    expect(await token.getOwner()).to.equal(owner.address);
  });

  it('Mint 100K tokens to yourself (Deployer)', async function () {
    expect(await token.balanceOf(owner.address)).to.equal(100000);
  });

  it('Mint 5K tokens to each one of the users', async function () {
    expect(await token.balanceOf(user1.address)).to.equal(5000);
    expect(await token.balanceOf(user2.address)).to.equal(5000);
    expect(await token.balanceOf(user3.address)).to.equal(5000);
  });

  it('Verify with a test that every user has the right amount of tokens', async function () {
    expect(await token.balanceOf(owner.address)).to.equal(100000);
    expect(await token.balanceOf(user1.address)).to.equal(5000);
    expect(await token.balanceOf(user2.address)).to.equal(5000);
    expect(await token.balanceOf(user3.address)).to.equal(5000);
  });

  it('Transfer 100 tokens from User2 to User3', async function () {
    const amount = 100;
    await token.connect(user2).transfer(user3.address, amount);

    expect(await token.balanceOf(user2.address)).to.equal(5000 - amount);
    expect(await token.balanceOf(user3.address)).to.equal(5000 + amount);
  });

  describe('Transfer Approval & Allowance', function () {
    let approvalEvent, amount;

    beforeEach(async function () {
      amount = 1000;

      const transaction = await token
        .connect(user3)
        .approve(user1.address, amount);

      const receipt = await transaction.wait();

      approvalEvent = receipt.events.find(
        (event) => event.event === 'Approval'
      );
    });

    it('From User3: approve User1 to spend 1K tokens', async function () {
      expect(approvalEvent.args.value).to.equal(amount);
    });

    it('Test that User1 has the right allowance that was given by User3', async function () {
      expect(approvalEvent.args.spender).to.equal(user1.address);
    });

    describe('Transfer & Balance', function () {
      let transferEvent;

      beforeEach(async function () {
        const transaction = await token
          .connect(user1)
          .transferFrom(user3.address, user1.address, amount);

        const receipt = await transaction.wait();

        transferEvent = receipt.events.find(
          (event) => event.event === 'Transfer'
        );
      });

      it('From User1: using transferFrom(), transfer 1K tokens from User3 to User1', async function () {
        expect(transferEvent.args.from).to.equal(user3.address);
        expect(transferEvent.args.to).to.equal(user1.address);
        expect(transferEvent.args.value).to.equal(amount);
      });

      it('Verify with a test that every user has the right amount of tokens', async function () {
        expect(await token.balanceOf(user1.address)).to.equal(6000);
        expect(await token.balanceOf(user2.address)).to.equal(5000);
        expect(await token.balanceOf(user3.address)).to.equal(4000);
      });
    });
  });
});
