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

//Contract deployed to: 0x95786A2B5E8d760557490cE4238A9bac015C2B9F

//https://scan.v2b.testnet.pulsechain.com/address/0x95786A2B5E8d760557490cE4238A9bac015C2B9F#code
