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
      accounts: [ process.env.AVAFUJI_PK ]
    },
    matic: {
      url: process.env.MATIC_RPC,
      accounts: [ process.env.MATIC_PK ]
    },
  },
  solidity: "0.8.16",
  etherscan: {
    apiKey: {
      avalancheFujiTestnet: process.env.AVAFUJI_API_KEY,
      polygon: process.env.MATIC_API_KEY,
    }
  }
};

export default config;