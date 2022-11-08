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

//Contract deployed to: 0x4059e41393f1A8041D64fFcC3e307545e6035c0B
