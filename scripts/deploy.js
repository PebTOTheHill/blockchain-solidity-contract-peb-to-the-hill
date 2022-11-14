const { ethers } = require("hardhat");

async function main() {
  const Contract = await ethers.getContractFactory("PlebToHill");
  const contract = await Contract.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", await contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//Contract deployed to: 0xb1203Fb8f8eC6fBd1335d6Fe732060965c26b96e
