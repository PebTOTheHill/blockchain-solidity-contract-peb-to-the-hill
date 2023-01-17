const { expect } = require("chai");
const { ethers } = require("hardhat");
const toWei = (num) => ethers.utils.parseEther(num.toString());

describe("PlebToHill", () => {
  let _contract, plebToken, plebStake;
  beforeEach(async () => {
    [addr1, addr2, addr3] = await ethers.getSigners();

    const PlebToken = await ethers.getContractFactory("PlebToken");
    plebToken = await PlebToken.deploy();

    const PlebStake = await ethers.getContractFactory("PlebStaking");
    plebStake = await PlebStake.deploy(plebToken.address);

    const contract = await ethers.getContractFactory("PlebToHill", addr1);
    _contract = await contract.deploy(plebToken.address, plebStake.address);
    await _contract.deployed();

    await _contract.connect(addr1).setRoundDuration(10);
    await _contract.connect(addr1).setExtraDuration(1);
    await _contract.connect(addr1).setThresoldTime(2);

    await _contract.connect(addr1).setPothWallet(addr3.address);
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
    expect((await _contract.getRoundData(1)).isLive).to.be.true;
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
      await network.provider.send("evm_increaseTime", [1000]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(1);
      await _contract.connect(addr1).createRound();
      expect((await _contract.getRoundData(1)).isLive).to.be.false;
      expect((await _contract.getRoundData(2)).isLive).to.be.true;
    });

    it("Should not  add a particpant to a  non-live round ", async () => {
      await expect(
        _contract.addParticipant(5, {
          value: ethers.utils.parseEther("1.0"),
        })
      ).to.be.revertedWith("Round is not live");
    });

    it("Should add a participant to the live round", async () => {
      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      expect((await _contract.getAllParticipantOfRound(1)).length).to.be.equal(
        1
      );
      expect(
        (await _contract.getAllParticipantOfRound(1))[0].participantId
      ).to.be.equal(1);
      expect(
        (await _contract.getAllParticipantOfRound(1))[0].walletAddress
      ).to.be.equal(addr2.address);

      expect(
        (await _contract.getAllParticipantOfRound(1))[0].roundId
      ).to.be.equal(1);
    });

    it("New participant should pay correct amount to join", async () => {
      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      await expect(
        _contract.connect(addr2).addParticipant(1, {
          value: ethers.utils.parseEther("3.0"),
        })
      ).to.be.revertedWith("Incorrect invested amount");
    });

    it("Should pay to previous participant when a new one join ", async () => {
      const previousBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr2.address)
      );

      const previousPothBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr3.address)
      );

      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      await _contract.connect(addr1).addParticipant(1, {
        value: ethers.utils.parseEther("2.0"),
      });

      const latestBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr2.address)
      );

      const latestPothBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr3.address)
      );
      expect(parseInt(latestBalance)).to.be.greaterThan(
        parseInt(previousBalance)
      );
      console.log("poth wallet prev =>", previousPothBalance);
      console.log("poth wallet latest =>", latestPothBalance);
    });

    it("Should pay twice amount to the only participant of a round after round end", async () => {
      const previousBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr2.address)
      );

      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      await network.provider.send("evm_increaseTime", [1000]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(1);

      const latestBalance = ethers.utils.formatEther(
        await ethers.provider.getBalance(addr2.address)
      );
      expect(parseInt(latestBalance)).to.be.greaterThan(
        parseInt(previousBalance)
      );
    });
  });

  it("Should get the correct current live round", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });
    await _contract.connect(addr1).createRound();

    const data = await _contract.getCurrentLiveRound();
    expect(data.roundId).to.be.equal(1);

    await network.provider.send("evm_increaseTime", [1000]);
    await network.provider.send("evm_mine");
    await _contract.connect(addr1).endRound(1);

    await _contract.connect(addr1).createRound();

    const data2 = await _contract.getCurrentLiveRound();
    expect(data2.roundId).to.be.equal(2);

    await network.provider.send("evm_increaseTime", [1000]);
    await network.provider.send("evm_mine");
    await _contract.connect(addr1).endRound(2);

    await _contract.connect(addr1).createRound();

    const data3 = await _contract.getCurrentLiveRound();
    expect(data3.roundId).to.be.equal(3);
  });

  it("Should get the correct loser data once the round ends", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });
    await _contract.connect(addr1).createRound();
    await _contract.connect(addr2).addParticipant(1, {
      value: ethers.utils.parseEther("1.0"),
    });

    await _contract.connect(addr3).addParticipant(1, {
      value: ethers.utils.parseEther("2.0"),
    });

    await _contract.connect(addr1).addParticipant(1, {
      value: ethers.utils.parseEther("4.0"),
    });

    await network.provider.send("evm_increaseTime", [1000]);
    await network.provider.send("evm_mine");
    await _contract.connect(addr1).endRound(1);

    const data = await _contract.getLoserData(1);
    expect(data.id).to.be.equal(3);
    expect(data.wallet).to.be.equal(addr1.address);
    expect(data.amount_lose).to.be.equal(ethers.utils.parseEther("4.0"));
  });

  it("Should get Pleb token once the round ends", async () => {
    await plebToken.connect(addr1).approve(_contract.address, toWei(5));

    await _contract.connect(addr1).transferPleb(toWei(5));

    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });
    await _contract.connect(addr1).createRound();
    await _contract.connect(addr2).addParticipant(1, {
      value: ethers.utils.parseEther("1.0"),
    });

    await _contract.connect(addr3).addParticipant(1, {
      value: ethers.utils.parseEther("2.0"),
    });

    await _contract.connect(addr2).addParticipant(1, {
      value: ethers.utils.parseEther("4.0"),
    });

    await network.provider.send("evm_increaseTime", [1000]);
    await network.provider.send("evm_mine");
    await _contract.connect(addr1).endRound(1);

    const data = await _contract.getLoserData(1);
    // expect(await plebToken.balanceOf(data.wallet)).to.be.equal(
    //   data.amount_lose
    // );

    console.log(
      "xxxxxxxxxxxxxxxxxxxxxx",
      await plebToken.balanceOf(data.wallet)
    );
  });

  describe("Should return zero values when there is no loser or no participant", () => {
    beforeEach(async () => {
      await addr1.sendTransaction({
        to: _contract.address,
        value: ethers.utils.parseEther("1.0"),
      });
      await _contract.connect(addr1).createRound();
    });

    it("When only one participant joins", async () => {
      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });
      await network.provider.send("evm_increaseTime", [1000]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(1);

      const data = await _contract.getLoserData(1);
      expect(data.id).to.be.equal(0);
      expect(data.wallet).to.be.equal(ethers.constants.AddressZero);
      expect(data.amount_lose).to.be.equal(ethers.utils.parseEther("0"));
    });

    it("When no participant  joins", async () => {
      await network.provider.send("evm_increaseTime", [1000]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(1);

      const data = await _contract.getLoserData(1);
      expect(data.id).to.be.equal(0);
      expect(data.wallet).to.be.equal(ethers.constants.AddressZero);
      expect(data.amount_lose).to.be.equal(ethers.utils.parseEther("0"));
    });
  });

  it("Should get the correct value to invest for a participant", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });
    await _contract.connect(addr1).createRound();
    expect(await _contract.getValueForNextParticipant(1)).to.be.equal(
      ethers.utils.parseEther("1.0")
    );

    await _contract.connect(addr2).addParticipant(1, {
      value: ethers.utils.parseEther("1.0"),
    });

    expect(await _contract.getValueForNextParticipant(1)).to.be.equal(
      ethers.utils.parseEther("2.0")
    );
    await _contract.connect(addr3).addParticipant(1, {
      value: ethers.utils.parseEther("2.0"),
    });
    expect(await _contract.getValueForNextParticipant(1)).to.be.equal(
      ethers.utils.parseEther("4.0")
    );
  });

  it("Should get the correct array of data", async () => {
    await addr1.sendTransaction({
      to: _contract.address,
      value: ethers.utils.parseEther("1.0"),
    });

    for (let i = 1; i <= 4; i++) {
      await _contract.connect(addr1).createRound();

      await network.provider.send("evm_increaseTime", [1000]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr1).endRound(i);
    }

    const data = await _contract.getAllRounds(1, 3);

    console.log(data);
  });

  it("Should return zero values when there is no round created", async () => {
    const { roundId, startTime, endTime, isLive } =
      await _contract.getCurrentLiveRound();
    expect(roundId).to.be.equal(0);
    expect(startTime).to.be.equal(0);
    expect(endTime).to.be.equal(0);
    expect(isLive).to.be.equal(false);
  });

  it("Should return zero for a non-live round", async () => {
    expect(await _contract.getValueForNextParticipant(2)).to.be.equal(0);
  });

  describe("Timer reset", () => {
    beforeEach(async () => {
      await addr1.sendTransaction({
        to: _contract.address,
        value: ethers.utils.parseEther("1.0"),
      });
      await _contract.connect(addr1).createRound();
    });
    it("Should add extra time if a user joins with ", async () => {
      const initialTime = (await _contract.getRoundData(1)).endTime;

      console.log(await _contract.getRemainingTime(1));

      await network.provider.send("evm_increaseTime", [500]);
      await network.provider.send("evm_mine");
      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });
      console.log(await _contract.getRemainingTime(1));
      const finalTime = (await _contract.getRoundData(1)).endTime;
      console.log("initial", initialTime);
      console.log("final", finalTime);
    });
  });

  describe("Restrict pleb", () => {
    beforeEach(async () => {
      await addr1.sendTransaction({
        to: _contract.address,
        value: ethers.utils.parseEther("1.0"),
      });
      await _contract.connect(addr1).createRound();
    });
    it("Should restrict the current pleb to join the round twice", async () => {
      await _contract.connect(addr2).addParticipant(1, {
        value: ethers.utils.parseEther("1.0"),
      });

      await expect(
        _contract.connect(addr2).addParticipant(1, {
          value: ethers.utils.parseEther("2.0"),
        })
      ).to.be.revertedWith(
        "You cannot deposit again until there is a new pleb"
      );
    });
  });
});
