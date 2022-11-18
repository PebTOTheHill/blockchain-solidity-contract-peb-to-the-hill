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

//Contract deployed to: 0x98E692d528Cf1482F7AaD53Ef36E96aC8C11C0fc

//https://scan.v2b.testnet.pulsechain.com/address/0x98E692d528Cf1482F7AaD53Ef36E96aC8C11C0fc#code
