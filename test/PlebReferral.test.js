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

  it("Should not generate the referral code without 1 tpls", async () => {
    await expect(
      contract.connect(addr1).generateReferralCode()
    ).to.be.revertedWith(
      "You need to pay at least 1 TPLS to generate a referral code."
    );
  });

  it("Should generate referral code for 1 tPLS", async () => {
    expect(await contract.getReferralCode(addr1.address)).to.be.equal("0x");

    await contract.connect(addr1).generateReferralCode({
      value: toWei(1),
    });
    console.log(await contract.getReferralCode(addr1.address));
  });

  describe("set Referral", () => {
    let referralCode;
    beforeEach(async () => {
      await contract.connect(addr1).generateReferralCode({ value: toWei(1) });
      referralCode = await contract.getReferralCode(addr1.address);
    });

    it("Only owner can set referral", async () => {
      await expect(
        contract
          .connect(addr2)
          .setReferrer(addr1.address, addr2.address, referralCode)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should not set referral if referral code is not valid", async () => {
      referralCode =
        "0x307800000000000000000000000000000000000000000000000000000003c2dc2439";
      await expect(
        contract
          .connect(addr1)
          .setReferrer(addr1.address, addr2.address, referralCode)
      ).to.be.revertedWith("Referral code does not match");
    });

    it("Refree and referrer address should not be same", async () => {
      await expect(
        contract
          .connect(addr1)
          .setReferrer(addr1.address, addr1.address, referralCode)
      ).to.be.revertedWith("Referre and referrer address cannot be same");
    });

    it("Refree should not have more than one referrer", async () => {
      await contract
        .connect(addr1)
        .setReferrer(addr1.address, addr2.address, referralCode);
      await expect(
        contract
          .connect(addr1)
          .setReferrer(addr1.address, addr2.address, referralCode)
      ).to.be.revertedWith("Referee already has a referrer");
    });

    it("Should set referral", async () => {
      await contract
        .connect(addr1)
        .setReferrer(addr1.address, addr2.address, referralCode);
      expect(await contract.getReferrer(addr2.address)).to.be.equal(
        addr1.address
      );
    });
  });

  describe("transfer pleb", () => {
    let referralCode;
    beforeEach(async () => {
      await contract.connect(addr1).generateReferralCode({ value: toWei(1) });
      referralCode = await contract.getReferralCode(addr1.address);
      await contract
        .connect(addr1)
        .setReferrer(addr1.address, addr2.address, referralCode);

      await addr1.sendTransaction({
        to: plebToHill.address,
        value: ethers.utils.parseEther("1.0"),
      });
      await plebToHill.connect(addr1).createRound();

      await contract.connect(addr1).setPlebContract(plebToHill.address);
    });

    it("Should transfer 5 % of the playing amount to both refree and referrer", async () => {
      const balance_1_before = await tokenContract.balanceOf(addr1.address);

      const balance_2_before = await tokenContract.balanceOf(addr2.address);

      await plebToHill.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      const balance_1_after = await tokenContract.balanceOf(addr1.address);

      const balance_2_after = await tokenContract.balanceOf(addr2.address);

      expect(balance_1_after.sub(balance_1_before)).to.be.equal(toWei(0.05));
      expect(balance_2_after.sub(balance_2_before)).to.be.equal(toWei(0.05));
    });
  });
});
