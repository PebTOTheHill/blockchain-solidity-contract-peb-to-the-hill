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

//Contract deployed to: 0x61D8f07259B134184dfc1e7c9589882f35825E93
