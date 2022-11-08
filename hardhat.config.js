/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
const {
  chainConfig,
} = require("@nomiclabs/hardhat-etherscan/dist/src/ChainConfig");
chainConfig["testnet"] = {
  chainId: 941,
  urls: {
    apiURL: "https://scan.v2b.testnet.pulsechain.com/api",
    browserURL: "https://scan.v2b.testnet.pulsechain.com",
  },
};
module.exports = {
  solidity: "0.8.17",
  networks: {
    testnet: {
      chainId: 941,
      url: "https://rpc.v2b.testnet.pulsechain.com",
      accounts: (process.env.PKEYS || "").split(","),
      gasPrice: 50000000000,
    },
  },
  etherscan: {
    // needed for contract verification
    apiKey: {
      testnet: "0",
    },
  },
};
