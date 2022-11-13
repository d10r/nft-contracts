/*
 * Hardhat script which deploys an instance of FlowNFT.
 *
 * Optional ENV vars:
 * - CFA: address of the CFA contract (needed for devnets)
 * - NAME: Name of the token (to override the default)
 * - SYMBOL: Symbol of the token (to override the default)
 * 
 * Note: this script deploys existing binaries, doesn't compile itself.
 */

const hre = require("hardhat");

async function main() {
    const cfaAddr = process.env.CFA || network.config.sfMeta.contractsV1.host;
    const name = process.env.NAME || "Superfluid Stream";
    const symbol = process.env.SYMBOL || "SFS";

    if(cfaAddr === undefined || name === undefined || symbol === undefined) {
        throw "not all needed ENV vars (CFA, NAME, SYMBOL) set"
    }

    console.log(`Deploying for CFA ${cfaAddr} with name "${name}" and symbol "${symbol}"`);

    const FlowNFT = await hre.ethers.getContractFactory("FlowNFT");
    const flowNFT = await FlowNFT.deploy(cfaAddr, name, symbol);

    // changing this output can break the bash script using it
    console.log("FlowNFT deployed to", flowNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
