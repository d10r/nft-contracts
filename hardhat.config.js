require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-chai-matchers");
require("hardhat-gas-reporter");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {}
  },
  solidity: "0.8.16",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
