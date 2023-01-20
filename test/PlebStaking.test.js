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

  describe("Staking", () => {
    it("User should not stake without approvals", async () => {
      await expect(contract.connect(addr1).stake(toWei(10))).to.be.revertedWith(
        "ERC20: insufficient allowance"
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
      expect((await contract.stakers(1)).activeStaked).to.be.true;
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

  describe("emergency end stake", () => {
    beforeEach(async () => {
      await plebToken.connect(addr1).approve(contract.address, toWei(500));
      await contract.connect(addr1).stake(toWei(500));

      await contract.accumulateReward({
        value: ethers.utils.parseEther("2.0"),
      });

      await contract.distributeReward();
    });

    it("Should give reward and half pleb tokens", async () => {
      const pleb_balance_1 = await plebToken.balanceOf(addr1.address);

      const balance_1 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance before => ", pleb_balance_1);
      console.log("balance before =>", balance_1);

      await contract.emergencyEndStake(1);

      const pleb_balance_2 = await plebToken.balanceOf(addr1.address);

      const balance_2 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance after => ", pleb_balance_2);
      console.log("balance after =>", balance_2);
    });
  });

  describe("Unstake", () => {
    beforeEach(async () => {
      await plebToken.connect(addr1).approve(contract.address, toWei(500));
      await contract.connect(addr1).stake(toWei(500));

      await contract.accumulateReward({
        value: ethers.utils.parseEther("1.0"),
      });

      await contract.distributeReward();
    });

    it("User cannot unstake before staking period is over", async () => {
      await expect(contract.unstake(1)).to.be.revertedWith(
        "Staking period is not over"
      );
    });

    it("After unstake user will get PLEB tokens and reward ", async () => {
      await network.provider.send("evm_increaseTime", [950400]);
      await network.provider.send("evm_mine");

      const pleb_balance_1 = await plebToken.balanceOf(addr1.address);

      const balance_1 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance before => ", pleb_balance_1);
      console.log("balance before =>", balance_1);

      await contract.unstake(1);

      const pleb_balance_2 = await plebToken.balanceOf(addr1.address);

      const balance_2 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance after => ", pleb_balance_2);
      console.log("balance after =>", balance_2);
    });

    it("User will lose pleb tokens and only get reward if they unstake after 30 days pass the stake period", async () => {
      await network.provider.send("evm_increaseTime", [4320000]);
      await network.provider.send("evm_mine");

      const pleb_balance_1 = await plebToken.balanceOf(addr1.address);

      const balance_1 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance before => ", pleb_balance_1);
      console.log("balance before =>", balance_1);

      await contract.unstake(1);

      const pleb_balance_2 = await plebToken.balanceOf(addr1.address);

      const balance_2 = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr1.address)
      );

      console.log("pleb token balance after => ", pleb_balance_2);
      console.log("balance after =>", balance_2);
    });
  });
});
