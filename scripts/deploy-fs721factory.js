/*
 * Deploys the FlowSender721Factory using pre-existing deterministic deployment proxy
 * at 0x7A0D94F55792C434d74a40883C6ed8545E406D12 - see https://github.com/Zoltu/deterministic-deployment-proxy
 *
 * optional ENV vars:
 * - HOST: address of the Superfluid host contract (needed for devnets, auto-discovered otherwise)
 * - FACTORY_INITIALIZER: address doing the initialize call on the factory. Changing it changes contract address.
 */

const hre = require("hardhat");

const DETERMINISTIC_DEPLOYER_ADDR = "0x7A0D94F55792C434d74a40883C6ed8545E406D12";

async function main() {
    const signer = await hre.ethers.getSigner();
    const factoryInitializerAddr = process.env.FACTORY_INITIALIZER || signer.address;
    const hostAddr = process.env.HOST || network.config.sfMeta.contractsV1.host;
    if (hostAddr === undefined) {
        throw "not all needed ENV vars (HOST) set"
    }

    console.log(`Using factory initializer ${factoryInitializerAddr}, Superfluid host: ${hostAddr}, signer ${signer.address}`);

    // check if deployment proxy exists (TODO: deploy if not - for devnets)
    if (! (await ethers.provider.getCode(DETERMINISTIC_DEPLOYER_ADDR) > 2)) {
        throw "ERR: Deterministic deployer not found at 0x7A0D94F55792C434d74a40883C6ed8545E406D12"
    }

    // get initcode of the factory contract
    const Factory = await hre.ethers.getContractFactory("FlowSender721Factory");
    const factoryInitcode = Factory.getDeployTransaction(factoryInitializerAddr).data;
    let targetAddr;

    // precompute deterministic target address - will fail if already deployed
    // in order to retroactively get the address: check in a block explorer
    try {
        targetAddr = await signer.call({to: DETERMINISTIC_DEPLOYER_ADDR, data: factoryInitcode});
        console.log("Factory contract will be deployed to:", targetAddr);
    } catch(e) {
        if (e.code === "CALL_EXCEPTION") {
            throw "Factory contract already deployed";
        }
    }

    // deploy the factory
    const deployTx = await signer.sendTransaction({to: DETERMINISTIC_DEPLOYER_ADDR, data: factoryInitcode});
    console.log(`Waiting for deployment tx ${deployTx.hash} …`);
    await deployTx.wait();
    console.log("Deploy tx executed!");

    // initialize tx
    if (signer.address === ethers.utils.getAddress(factoryInitializerAddr)) {
        const factory = Factory.attach(targetAddr);
        const initTx = await factory.initialize(hostAddr);
        console.log(`Waiting for init tx ${initTx.hash} …`);
        await deployTx.wait();
        console.log("Init tx executed!");
    } else {
        console.log("Signer is not the factory initializer.");
        console.log(`Initializer needs to run initialize("${hostAddr}")`);
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });