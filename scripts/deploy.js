const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

  // const TokenContract = await ethers.getContractFactory("PlebToken", addr1);
  // const tokenContract = await TokenContract.deploy();
  // await tokenContract.deployed();

  // console.log(" Pleb Token Contract deployed at:", tokenContract.address);

  // const StakingContract = await ethers.getContractFactory("PlebStaking", addr1);
  // const stakingContract = await StakingContract.deploy(tokenContract.address);
  // await stakingContract.deployed();

  // console.log(" Pleb Staking Contract deployed at:", stakingContract.address);

  // const PlebReferral = await ethers.getContractFactory("PlebReferral", addr1);
  // const plebReferral = await PlebReferral.deploy(tokenContract.address);
  // await plebReferral.deployed();

  // console.log("Referal contract deployed at : ", plebReferral.address);

  const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  const contract = await Contract.deploy(
    "0xD6B32794C57521a172D9c3075f81A2B39dce8eec",
    "0xD45dB0a2D4E9223AD344E2C322aC96b0d3260042",
    "0xd952727aadEfF6EeB186Bc66F58246484a07f36D"
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

// https://scan.v2b.testnet.pulsechain.com/address/0xD6B32794C57521a172D9c3075f81A2B39dce8eec#code  - Token

// https://scan.v2b.testnet.pulsechain.com/address/0xD45dB0a2D4E9223AD344E2C322aC96b0d3260042#code   -  Staking

// https://scan.v2b.testnet.pulsechain.com/address/0xd952727aadEfF6EeB186Bc66F58246484a07f36D#code    - Referal
