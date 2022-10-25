/*
 * Hardhat script which deploys an instance of FlowNFT.
 * Config ENV vars:
 * - CFA: address of the CFA contract its flows are represented
 * - NAME: Name of the token
 * - SYMBOL: Symbol of the token
 *
 * Note: this script deploys existing binaries, doesn't compile itself.
 */

const hre = require("hardhat");

async function main() {
    const cfaAddr = process.env.CFA;
    const name = process.env.NAME;
    const symbol = process.env.SYMBOL;

    if(cfaAddr === undefined || name === undefined || symbol === undefined) {
        throw "not all needed ENV vars (CFA, NAME, SYMBOL) set"
    }

    const FlowNFT = await hre.ethers.getContractFactory("FlowNFT");

    const flowNFT = await FlowNFT.deploy(cfaAddr, name, symbol);

    console.log("FlowNFT deployed to", flowNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
