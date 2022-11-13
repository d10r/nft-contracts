/*
 * Deploys the FlowSender721Factory using pre-existing deterministic deployment proxy
 * at 0x7A0D94F55792C434d74a40883C6ed8545E406D12 - see https://github.com/Zoltu/deterministic-deployment-proxy
 *
 * required ENV vars:
 * - HOST: address of the Superfluid host contract
 */

const hre = require("hardhat");

const DETERMINISTIC_DEPLOYER_ADDR = "0x7A0D94F55792C434d74a40883C6ed8545E406D12";

async function main() {
    const host = process.env.HOST;
    if (host === undefined) {
        throw "not all needed ENV vars (HOST) set"
    }

    const signer = await hre.ethers.getSigner();
    console.log("using signer", signer.address);

    // check if deployment proxy exists (TODO: deploy if not - for devnets)
    if (! (await ethers.provider.getCode(DETERMINISTIC_DEPLOYER_ADDR) > 2)) {
        throw "ERR: Deterministic deployer not found at 0x7A0D94F55792C434d74a40883C6ed8545E406D12"
    }

    // get initcode of the factory contract
    const Factory = await hre.ethers.getContractFactory("FlowSender721Factory");
    const factoryInitcode = Factory.getDeployTransaction(host).data;

    // precompute deterministic target address - will fail if already deployed
    // in order to retroactively get the address: check in a block explorer
    try {
        const targetAddr = await signer.call({to: DETERMINISTIC_DEPLOYER_ADDR, data: factoryInitcode});
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
    console.log("tx executed!");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });