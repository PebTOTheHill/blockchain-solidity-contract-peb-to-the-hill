const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PlebToHill", () => {
  let _contract;
  beforeEach(async () => {
    [addr1, addr2, ...addrs] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("PlebToHill", addr1);
    _contract = await contract.deploy();
    await _contract.deployed();
  });

  it("Should not create a round when contract balance is less than 1 tPLS", async () => {
    await expect(_contract.connect(addr1).createRound()).to.be.revertedWith(
      "Minimum contract balance should be 1 tPLS"
    );
  });

  it("Should create a round when contract balance is greater then 1 tPLS", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });
    await _contract.connect(addr1).createRound();
    expect((await _contract.getRoundData(0)).isLive).to.be.true;
  });

  it("Non-owner cannot create a round", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });

    await expect(_contract.connect(addr2).createRound()).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });

  describe("Create round and add participants", () => {
    beforeEach(async () => {
      await addr1.sendTransaction({
        to: _contract.address,
        value: ethers.utils.parseEther("1.0"),
      });
      await _contract.connect(addr1).createRound();
    });

    it("Should not create a round when previous round already live", async () => {
      await expect(_contract.connect(addr1).createRound()).to.be.revertedWith(
        "Previous round is not finished yet"
      );
    });

    it("Should create round when previous round duration is over and end round is called", async () => {
      await network.provider.send("evm_increaseTime", [500]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(0);
      await _contract.connect(addr1).createRound();
      expect((await _contract.getRoundData(0)).isLive).to.be.false;
      expect((await _contract.getRoundData(1)).isLive).to.be.true;
    });

    it("Should not  add a particpant to a  non-live round ", async () => {
      await expect(
        _contract.addParticipant(5, {
          value: ethers.utils.parseEther("1.0"),
        })
      ).to.be.revertedWith("Round is not live");
    });

    it("Should add a participant to the live round", async () => {
      await _contract.connect(addr2).addParticipant(0, {
        value: ethers.utils.parseEther("1.0"),
      });

      expect((await _contract.getAllParticipantOfRound(0)).length).to.be.equal(
        1
      );
      expect(
        (await _contract.getAllParticipantOfRound(0))[0].participantId
      ).to.be.equal(0);
      expect(
        (await _contract.getAllParticipantOfRound(0))[0].walletAddress
      ).to.be.equal(addr2.address);

      expect(
        (await _contract.getAllParticipantOfRound(0))[0].roundId
      ).to.be.equal(0);
    });
  });
});
