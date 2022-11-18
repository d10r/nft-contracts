/*
 * Deploy a FlowSender721 contract using its factory.
 * Required ENV vars:
 * - SUPERTOKEN: address of the associated SuperToken contract
 * - RECEIVER: address of the associated receiver (can be any EOA or contract)
 *
 * Optional ENV vars:
 * - FACTORY: address of the factory contract to be used. Needed only for devnets
 */

const hre = require("hardhat");

async function main() {
    const superTokenAddr = process.env.SUPERTOKEN;
    const receiverAddr = process.env.RECEIVER;
    if (superTokenAddr === undefined || receiverAddr === undefined) {
        throw "not all needed ENV vars (SUPERTOKEN, RECEIVER) set"
    }

    const factoryAddr = process.env.FACTORY || "0x04b4cd83d925e672580f44ef1aeddc68726c737d";

    const Factory = await hre.ethers.getContractFactory("FlowSender721Factory");
    const factory = Factory.attach(factoryAddr);

    const { instanceAddr, isDeployed } = await factory.getAddressFor(superTokenAddr, receiverAddr);

    if (isDeployed) {
        console.log(`Already deployed at ${instanceAddr}`);
    } else {
        console.log(`Need to deploy - computed address: ${instanceAddr}`);
        const deployTx = await factory.deployFor(superTokenAddr, receiverAddr);
        console.log(`Waiting for deploy tx ${deployTx.hash} …`);
        await deployTx.wait();
        console.log("tx executed!");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
