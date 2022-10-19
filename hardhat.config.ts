import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
import { config, config as dotenvConfig } from "dotenv";
dotenvConfig();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    avafuji: {
      url: process.env.AVAFUJI_RPC,
      accounts: [ process.env.OVERRIDE_PK || process.env.AVAFUJI_PK || process.env.DEFAULT_PK ]
    },
    mumbai: {
      url: process.env.MUMBAI_RPC,
      accounts: [ process.env.OVERRIDE_PK || process.env.MUMBAI_PK || process.env.DEFAULT_PK ]
    },
    goerli: {
      url: process.env.GOERLI_RPC,
      accounts: [ process.env.OVERRIDE_PK || process.env.GOERLI_PK || process.env.DEFAULT_PK ]
    },

    matic: {
      url: process.env.MATIC_RPC,
      accounts: [ process.env.OVERRIDE_PK || process.env.MATIC_PK || process.env.DEFAULT_PK ]
    },
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      // avoid stack too deep issue
      viaIR: true
    }
  },
  etherscan: {
    // list supported explorers with: npx hardhat verify --list-networks
    apiKey: {
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
    }
  }
};

export default config;