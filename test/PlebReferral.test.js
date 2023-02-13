const { expect } = require("chai");
const { ethers } = require("hardhat");

const toWei = (num) => ethers.utils.parseEther(num.toString());
let contract, tokenContract, staking, plebToHill;
describe("PlebReferral Contract", () => {
  beforeEach(async () => {
    [addr1, addr2, addr3] = await ethers.getSigners();

    const token = await ethers.getContractFactory("PlebToken");

    tokenContract = await token.deploy();

    const Contract = await ethers.getContractFactory("PlebReferral");
    contract = await Contract.deploy(tokenContract.address);

    const Staking = await ethers.getContractFactory("PlebStaking");
    staking = await Staking.deploy(tokenContract.address);

    const Pleb = await ethers.getContractFactory("PlebToHill");
    plebToHill = await Pleb.deploy(
      tokenContract.address,
      staking.address,
      contract.address
    );

    await tokenContract.connect(addr1).transfer(contract.address, toWei(2));

    await plebToHill.connect(addr1).setRoundDuration(10);
    await plebToHill.connect(addr1).setExtraDuration(1);
    await plebToHill.connect(addr1).setThresoldTime(2);
  });

  describe("Transfer referral", () => {
    beforeEach(async () => {
      await addr1.sendTransaction({
        to: plebToHill.address,
        value: ethers.utils.parseEther("1.0"),
      });

      await plebToHill.connect(addr1).createRound();

      await contract.setReferrer(addr2.address, addr3.address);
    });

    it("Should transfer correct amount to referrer and refere", async () => {
      await contract.connect(addr1).setPlebContract(plebToHill.address);

      console.log("before addr2", await tokenContract.balanceOf(addr2.address));
      console.log("before addr3", await tokenContract.balanceOf(addr3.address));

      await plebToHill.connect(addr2).addParticipant(1, {
        value: toWei(1),
      });

      await plebToHill.connect(addr3).addParticipant(1, {
        value: toWei(2),
      });

      console.log("after addr2", await tokenContract.balanceOf(addr2.address));
      console.log("after addr3", await tokenContract.balanceOf(addr3.address));
    });

    it("Only pleb contract can call the transfer refer amount", async () => {
      await expect(
        plebToHill.connect(addr2).addParticipant(1, {
          value: toWei(1),
        })
      ).to.be.revertedWith("Only Pleb Contract can call this method");
    });
  });
});
