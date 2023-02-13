const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

  const TokenContract = await ethers.getContractFactory("PlebToken", addr1);
  const tokenContract = await TokenContract.deploy();
  await tokenContract.deployed();

  console.log(" Pleb Token Contract deployed at:", tokenContract.address);

  const StakingContract = await ethers.getContractFactory("PlebStaking", addr1);
  const stakingContract = await StakingContract.deploy(tokenContract.address);
  await stakingContract.deployed();

  console.log(" Pleb Staking Contract deployed at:", stakingContract.address);

  const PlebReferral = await ethers.getContractFactory("PlebReferral", addr1);
  const plebReferral = await PlebReferral.deploy(tokenContract.address);
  await plebReferral.deployed();

  console.log("Referal contract deployed at : ", plebReferral.address);

  const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  const contract = await Contract.deploy(
    tokenContract.address,
    stakingContract.address,
    plebReferral.address
  );
  await contract.deployed();

  console.log(" Pleb Contract deployed at:", await contract.address);

  const tx1 = await contract.connect(addr1).setRoundDuration(5);
  await tx1.wait();
  const tx2 = await contract.connect(addr1).setExtraDuration(1);
  await tx2.wait();
  const tx3 = await contract.connect(addr1).setThresoldTime(2);
  await tx3.wait();

  await addr1.sendTransaction({
    to: contract.address,
    value: ethers.utils.parseEther("1.0"),
  });

  console.log("-----------COMPLETED------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//   Pleb Token Contract deployed at: 0x90E82B2EA6e7C900b397fa10e8901c4C805D8E13
//   Pleb Staking Contract deployed at: 0x0669F6EAa24C7822c0bf7bF0CEF1Ed5E8a855649
//  Referal contract deployed at :  0xA1FffA03Ae8041B53B0a2D128C2D54897470C7bB
//   Pleb Contract deployed at: 0x7c5e77d8928B6C2108a06c1a794C8f744cF64907

// Token Contract : https://scan.v2b.testnet.pulsechain.com/address/0x90E82B2EA6e7C900b397fa10e8901c4C805D8E13#code
