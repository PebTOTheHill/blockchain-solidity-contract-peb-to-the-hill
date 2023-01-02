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

    plebToken.connect(addr1).mint(addr1.address, toWei(1000));
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
      await plebToken.connect(addr1).approve(contract.address, toWei(2000));

      await expect(
        contract.connect(addr1).stake(toWei(2000))
      ).to.be.revertedWith("Cannot stake more than the balance");
    });

    it("User should stake", async () => {
      await plebToken.connect(addr1).approve(contract.address, toWei(200));
      console.log(await plebToken.balanceOf(addr1.address));

      await contract.connect(addr1).stake(toWei(200));
    });
  });
});
