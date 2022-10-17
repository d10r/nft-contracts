const { expect } = require("chai");
const { ethers } = require("hardhat");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("FlowNFT", function () {

    let sender, receiver, operator;
    let token1, token2, cfaMock, flowNFT;

    const BASE_URL = "https://nft.superfluid.finance";
    function checkURI(uriStr, tokenAddr, senderAddr, receiverAddr, startDateSet) {
        const url = new URL(uriStr);
        const params = url.searchParams;
        console.log("params", params);
        console.log("params.token", params.token);
        expect(url.origin).to.be.equal(BASE_URL);
        expect(params.get("token").toLowerCase()).to.be.equal(tokenAddr.toLowerCase());

        if(startDateSet) {
            expect(params.get("start_date")).to.exist;
        } else {
            expect(params.get("start_date")).to.be.null;
        }
    }

    before(async function () {
      [sender, receiver, operator] = await ethers.getSigners(3);
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

    it("mint NFT to receiver on create hook", async function () {
        const createTx = cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, true);

        //const receipt = await (await createTx).wait();

        //console.log("createTx receipt: ", JSON.stringify(await receipt, null, 2));

        // This is supposed to be set, see https://docs.ethers.io/v5/api/contract/contract/#contract-functionsSend
        // But the logs seem to not be parsed by ethers
        //console.log("createTx events[0].event: ", JSON.stringify(await receipt.events[0].event, null, 2));

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenCnt();
        console.log("NFT created with id", tokId);

        await expect(createTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, tokId);

        const owner = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", owner);
        expect(owner).to.be.equal(receiver.address);

        const bal = await flowNFT.balanceOf(receiver.address);
        expect(bal).to.be.equal(1);

        const uri = await flowNFT.tokenURI(tokId);
        console.log("uri", uri);
        checkURI(uri, token1.address, sender.address, receiver.address, true);
    });

    it("mint NFT to receiver by operator on create hook", async function () {
        const createTx = cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, operator.address, 1e9, true);

        const tokId = await flowNFT.tokenCnt();
        console.log("NFT created with id", tokId);

        await expect(createTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, tokId);

        const owner = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", owner);
        expect(owner).to.be.equal(receiver.address);

        const uri = await flowNFT.tokenURI(tokId);
        console.log("uri", uri);

        checkURI(uri, token1.address, sender.address, receiver.address, true);
    });

    it("mint NFT to receiver by manual hook", async function () {
        // can't mint for a non-existing flow
        await expect(flowNFT.mint(token1.address, sender.address, receiver.address))
            .to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");

        // flow is created without invoking the hook
        await cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, false);

        // now can mint
        const mintTx = flowNFT.mint(token1.address, sender.address, receiver.address);

        // ... but not twice
        await expect(flowNFT.mint(token1.address, sender.address, receiver.address))
            .to.be.revertedWithCustomError(flowNFT, "ALREADY_MINTED");

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenCnt();
        console.log("NFT created with id", tokId);

        await expect(mintTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, tokId);

        const receipt = await (await mintTx).wait();
        console.log("mintTx events[0].event: ", JSON.stringify(await receipt.events[0].event, null, 2));

        const owner = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", owner);
        expect(owner).to.be.equal(receiver.address);

        const uri = await flowNFT.tokenURI(tokId);
        console.log("uri", uri);

        checkURI(uri, token1.address, sender.address, receiver.address, false);
    });

    it("burn NFT on delete hook", async function () {
        await cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, true);

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenCnt();
        const o1 = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", o1);

        // mint a second, unrelated NFT and see if balanceOf accounts for correctly
        await cfaMock.fakeCreateFlow(token2.address, sender.address, receiver.address, sender.address, 1e9, true);
        const bal1 = await flowNFT.balanceOf(receiver.address);
        expect(bal1).to.be.equal(2);

        await cfaMock.fakeDeleteFlow(token1.address, sender.address, receiver.address, sender.address);

        const bal2 = await flowNFT.balanceOf(receiver.address);
        expect(bal2).to.be.equal(1);

        await expect(flowNFT.ownerOf(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
        await expect(flowNFT.tokenURI(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
    });

    it("burn NFT on operator delete", async function () {
        await cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, true);

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenCnt();
        const o1 = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", o1);

        await cfaMock.fakeDeleteFlow(token1.address, sender.address, receiver.address, operator.address);
        await expect(flowNFT.ownerOf(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
        await expect(flowNFT.tokenURI(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
    });
})