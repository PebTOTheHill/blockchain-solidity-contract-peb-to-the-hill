const { ethers } = require("hardhat");

async function main() {
  const [addr1] = await ethers.getSigners();

  // const TokenContract = await ethers.getContractFactory("PlebToken", addr1);
  // const tokenContract = await TokenContract.deploy();
  // await tokenContract.deployed();

  // console.log(" Pleb Token Contract deployed to:", await tokenContract.address);

  const StakingContract = await ethers.getContractFactory("PlebStaking", addr1);
  const stakingContract = await StakingContract.deploy(
    "0xA63C107DE110237b64534b056b42a5dE84ED994A"
  );
  await stakingContract.deployed();

  console.log(
    " Pleb Staking Contract deployed to:",
    await stakingContract.address
  );

  // const Contract = await ethers.getContractFactory("PlebToHill", addr1);
  // const contract = await Contract.deploy(
  //   "0xA63C107DE110237b64534b056b42a5dE84ED994A",
  //   stakingContract.address
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

  console.log("-----------COMPLETED------------------");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//000000000000000000000000a63c107de110237b64534b056b42a5de84ed994a
