/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("@primitivefi/hardhat-dodoc");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("solidity-coverage");
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
  dodoc: {
    runOnCompile: false,
    debugMode: true,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};

//PKEYS=e00f259e96c342f73aa6f1798c36fbbcc2286c869c8fbbe50fcc4a842c32edf6
