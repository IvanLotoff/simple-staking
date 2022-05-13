import { expect } from "chai";
import { ethers } from "hardhat";
// https://ethereum.stackexchange.com/questions/110118/how-to-change-the-scope-of-a-variable-in-a-hardhat-test-written-in-typescript
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Staking } from "../typechain";


describe("Staking", function () {
  let contractOwner, client: SignerWithAddress
  let staking: Staking
  beforeEach("Staking",async function () {
      [contractOwner, client] =  await ethers.getSigners(); 

      const Staking = await ethers.getContractFactory("Staking", contractOwner);
      staking = await Staking.deploy();
      await staking.deployed();

      await staking.mint(client.address, 500);
      expect(await staking.balanceOf(client.address)).to.eq(500);
    });

  it("cannot stake more money that a client holds",async function() {
    await expect(staking.connect(client).createStake(1000)).to.be.revertedWith("low balance");
  })

  it("user stake amount",async function() {
    await staking.connect(client).createStake(100);
    expect(await staking.connect(client).showUserStakeAmount()).to.be.eq(100);
  })

  it("cannot create second stake",async function() {
    await staking.connect(client).createStake(100);
    await expect(staking.connect(client).createStake(100)).to.be.revertedWith("Already staked");
  })

  it("total supply dropped when staked",async function() {
    const initialSupply = await staking.totalSupply();
    await staking.connect(client).createStake(100);
    const newSupply = await staking.totalSupply();
    expect(initialSupply.sub(newSupply)).to.be.eq(100);
  })

  it("200 days remain",async function() {
    await staking.connect(client).createStake(100);
    expect(await staking.connect(client).showUserDaysRemaining()).to.be.eq(200);
  })

  it("cannot claim until stake period is over",async function() {
    await staking.connect(client).createStake(100);
    await expect(staking.connect(client).claimReward()).to.be.revertedWith("stake period is not over");
  })

  it("successful stake",async function() {
    await staking.connect(client).createStake(100);
    await ethers.provider.send("evm_increaseTime", [86400 * 201 + 1]); 
    await ethers.provider.send("evm_mine", []);
    expect(await staking.connect(client).showUserDaysRemaining()).to.be.eq(0);
    await staking.connect(client).claimReward();
    expect(await staking.balanceOf(client.address)).to.eq(700);
  })
})
