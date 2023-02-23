const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

  // const TokenContract = await ethers.getContractFactory("PlebToken", addr1);
  // const tokenContract = await TokenContract.deploy();
  // await tokenContract.deployed();

  // console.log(" Pleb Token Contract deployed at:", tokenContract.address);

  const StakingContract = await ethers.getContractFactory("PlebStaking", addr1);
  const stakingContract = await StakingContract.deploy(
    "0xbE012C87d2e2D3CE1402Ce9ABA4D52BFFB8db6D9"
  );
  await stakingContract.deployed();

  console.log(" Pleb Staking Contract deployed at:", stakingContract.address);

  const PlebReferral = await ethers.getContractFactory("PlebReferral", addr1);
  const plebReferral = await PlebReferral.deploy(
    "0xbE012C87d2e2D3CE1402Ce9ABA4D52BFFB8db6D9"
  );
  await plebReferral.deployed();

  console.log("Referal contract deployed at : ", plebReferral.address);

  const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  const contract = await Contract.deploy(
    "0xbE012C87d2e2D3CE1402Ce9ABA4D52BFFB8db6D9",
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

// Pleb Token Contract deployed at: 0xbE012C87d2e2D3CE1402Ce9ABA4D52BFFB8db6D9
// Pleb Staking Contract deployed at: 0x862b122B8575A1CDC8A25eb2687c9B018ae0212A
// Referal contract deployed at :  0xf1621115FE07a270cf4d494D13D41e983128584E
//  Pleb Contract deployed at: 0x2C082D260519371eFaa0565de44dD3c1dB3038ba

// https://scan.v2b.testnet.pulsechain.com/address/0xbE012C87d2e2D3CE1402Ce9ABA4D52BFFB8db6D9#code  - token

//https://scan.v2b.testnet.pulsechain.com/address/0xf1621115FE07a270cf4d494D13D41e983128584E#code - referrral

// https://scan.v2b.testnet.pulsechain.com/address/0x862b122B8575A1CDC8A25eb2687c9B018ae0212A#code - staking

// https://scan.v2b.testnet.pulsechain.com/address/0x2C082D260519371eFaa0565de44dD3c1dB3038ba#code - pleb game
