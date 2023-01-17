const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

  // const TokenContract = await ethers.getContractFactory("PlebToken", addr1);
  // const tokenContract = await TokenContract.deploy();
  // await tokenContract.deployed();

  // console.log(" Pleb Token Contract deployed to:", await tokenContract.address);

  // const StakingContract = await ethers.getContractFactory("PlebStaking", addr1);
  // const stakingContract = await StakingContract.deploy(
  //   "0xA63C107DE110237b64534b056b42a5dE84ED994A"
  // );
  // await stakingContract.deployed();

  // console.log(
  //   " Pleb Staking Contract deployed to:",
  //   await stakingContract.address
  // );

  // const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  // const contract = await Contract.deploy(
  //   "0xA63C107DE110237b64534b056b42a5dE84ED994A",
  //   "0x09B4dd3f7F8C873e6991F78bd11ed3c5dbe37018"
  // );
  // await contract.deployed();

  // console.log(" Pleb Contract deployed to:", await contract.address);

  // const tx1 = await contract.connect(addr1).setRoundDuration(5);
  // await tx1.wait();
  // const tx2 = await contract.connect(addr1).setExtraDuration(1);
  // await tx2.wait();
  // const tx3 = await contract.connect(addr1).setThresoldTime(2);
  // await tx3.wait();

  // await addr1.sendTransaction({
  //   to: contract.address,
  //   value: ethers.utils.parseEther("1.0"),
  // });

  // console.log("-----------COMPLETED------------------");

  const Faucet = await ethers.getContractFactory("Faucet");
  const faucet = await Faucet.deploy(
    "0xA63C107DE110237b64534b056b42a5dE84ED994A"
  );
  await faucet.deployed();

  console.log("Faucet contract deployed at => ", faucet.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// Pleb Token Contract deployed to: 0xA63C107DE110237b64534b056b42a5dE84ED994A
// Pleb Staking address :0x09B4dd3f7F8C873e6991F78bd11ed3c5dbe37018

//Faucet : 0xD331327d3d248a8c6E1CAD31bc24F05F5A66F994
