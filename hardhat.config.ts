import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
import sfMeta from "@superfluid-finance/metadata";
import { config, config as dotenvConfig } from "dotenv";
dotenvConfig();

// Returns an RPC URL for the given network.
function getRpcUrl(n) {
  // If set, a network specific env var is read, else construction from template is attempted, else none set
  return process.env[`${n.uppercaseName}_RPC`] || process.env.RPC_TEMPLATE?.replace("{{NETWORK_NAME}}", n.name) || "";
}

// Returns a list of accounts for the given network
function getAccounts(n) {
  // in order of priority, provide an override pk or a network specific pk or a fallback pk
  return [ process.env.OVERRIDE_PK || process.env[`${n.uppercaseName}_PK`] || process.env.DEFAULT_PK ];
}

const sfNetworks = sfMeta.networks
  // uncomment and adapt to your needs in order to include only a subset of networks
  //.filter(n => ["eth-goerli", "avalanche-fuji"].includes(n.name))
  .map(n => ({
    [n.name]: {
      url: getRpcUrl(n),
      accounts: getAccounts(n)
    }
  }));

/** @type import('hardhat/config').HardhatUserConfig */
const hardhatConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
  },
  metadata: sfMeta,
  metanetworks: sfNetworks,

  solidity: {
    version: "0.8.17",
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
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      goerli: process.env.ETHERSCAN_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
      gnosis: process.env.GNOSISSCAN_API_KEY,
      avalanche: process.env.SNOWTRACE_API_KEY,
      optimisticEthereum: process.env.OPTIMISTIC_API_KEY,
      arbitrumOne: process.env.ARBISCAN_API_KEY,
      bsc: process.env.BSCSCAN_API_KEY
    }
  }
};

// merge the dynamically created network list
Object.assign(hardhatConfig.networks, ...sfNetworks);

// You may uncomment this in order to print the available networks to console
//console.log("available networks:", Object.keys(hardhatConfig.networks).join(", "));

module.exports = hardhatConfig;

export default config;
