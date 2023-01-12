const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

const TokenContract= await ethers.getContractFactory('PlebToken',addr1);
const tokenContract= await TokenContract.deploy()
await tokenContract.deployed();


console.log(" Pleb Token Contract deployed to:", await tokenContract.address);

  const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  const contract = await Contract.deploy(tokenContract.address);
  await contract.deployed();

  console.log(" Pleb Contract deployed to:", await contract.address);

  const tx1 = await contract.connect(addr1).setRoundDuration(10);
  await tx1.wait();
  const tx2 = await contract.connect(addr1).setExtraDuration(1);
  await tx2.wait();
  const tx3 = await contract.connect(addr1).setThresoldTime(2);
  await tx3.wait();

  const tx4= await tokenContract.connect(addr1).setPlebContractAddress(contract.address);
   await tx4.wait();


   console.log('-----------COMPLETED------------------');

  await addr1.sendTransaction({
    to: contract.address,
    value: ethers.utils.parseEther("1.0"),
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//Contract deployed to: 0x95786A2B5E8d760557490cE4238A9bac015C2B9F

//https://scan.v2b.testnet.pulsechain.com/address/0x95786A2B5E8d760557490cE4238A9bac015C2B9F#code
