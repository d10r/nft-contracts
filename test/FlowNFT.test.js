const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("FlowNFT", function () {
    let admin, sender, receiver;
    let token1, token2, cfaMock, flowNFT;
  
    before(async function () {
      [admin, sender, receiver] = await ethers.getSigners(3);
      FlowNFT = await ethers.getContractFactory("FlowNFT");
      TokenMock = await ethers.getContractFactory("TokenMock");
      CFAv1Mock = await ethers.getContractFactory("CFAv1Mock");
    });

    this.beforeEach(async function () {
        token1 = await TokenMock.deploy(ethers.utils.parseUnits("1000000"));
        console.log("token1 deployed to", token1.address);
        token2 = await TokenMock.deploy(ethers.utils.parseUnits("1000000"));
        console.log("token2 deployed to", token2.address);
        cfaMock = await CFAv1Mock.deploy();
        console.log("CFAv1Mock deployed to", cfaMock.address);
        flowNFT = await FlowNFT.deploy(cfaMock.address, "TESTNFT", "TNFT");
        console.log("FlowNFT deployed to", flowNFT.address);
        await cfaMock.setHookImplementer(flowNFT.address);
    });

    it("mint NFT on create hook", async function () {
        const createTx = cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1000);

        await expect(createTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, anyValue);

        const receipt = await (await createTx).wait();

        console.log("createTx receipt: ", JSON.stringify(await receipt, null, 2));

        // This is supposed to be set, see https://docs.ethers.io/v5/api/contract/contract/#contract-functionsSend
        // But the logs seem to not be parsed by ethers
        console.log("createTx events[0].event: ", JSON.stringify(await receipt.events[0].event, null, 2));
    });
})