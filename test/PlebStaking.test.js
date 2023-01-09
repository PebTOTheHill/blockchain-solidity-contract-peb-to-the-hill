const { expect } = require("chai");
const { ethers } = require("hardhat");

const toWei = (num) => ethers.utils.parseEther(num.toString());
const fromWei = (num) => ethers.utils.formatEther(num);

describe("PlebStaking", () => {
  let contract, plebToken;
  beforeEach(async () => {
    [addr1, addr2] = await ethers.getSigners();

    const PlebToken = await ethers.getContractFactory("PlebToken");
    plebToken = await PlebToken.deploy();

    const Contract = await ethers.getContractFactory("PlebStaking");
    contract = await Contract.deploy(plebToken.address);
  });

  describe("Staking/Unstaking", () => {
    it("User should not stake without approvals", async () => {
      await expect(contract.connect(addr1).stake(toWei(10))).to.be.revertedWith(
        "No allowance. Please grant pleb allowance"
      );
    });

    it("User should not stake zero token amount", async () => {
      await expect(contract.connect(addr1).stake(toWei(0))).to.be.revertedWith(
        "Amount should be greater than 0"
      );
    });

    it("User should not stake more than the balance", async () => {
      await plebToken.connect(addr2).approve(contract.address, toWei(12));

      await expect(contract.connect(addr2).stake(toWei(12))).to.be.revertedWith(
        "Cannot stake more than the balance"
      );
    });

    it("User should stake", async () => {
      await plebToken.connect(addr1).approve(contract.address, toWei(200));

      await contract.connect(addr1).stake(toWei(200));
    });
  });

  describe("Reward distribution", () => {
    beforeEach(async () => {
      await plebToken.connect(addr1).approve(contract.address, toWei(500));
      await contract.connect(addr1).stake(toWei(500));
    });

    it("Should distribute reward only till staking period", async () => {
      await contract.accumulateReward({
        value: ethers.utils.parseEther("2.0"),
      });

      await contract.distributeReward();

      const rewardBefore = await contract.calculateRewards(1);

      await network.provider.send("evm_increaseTime", [950400]);
      await network.provider.send("evm_mine");

      await contract.accumulateReward({
        value: ethers.utils.parseEther("1.0"),
      });

      await plebToken.connect(addr1).approve(contract.address, toWei(200));
      await contract.connect(addr1).stake(toWei(200));
      await contract.distributeReward();

      const rewardAfter = await contract.calculateRewards(1);
      expect(rewardBefore).to.be.equals(rewardAfter);
    });
  });
});
