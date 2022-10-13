const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("FlowNFT", function () {

    let sender, receiver, operator;
    let token1, token2, cfaMock, flowNFT;
  
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
        const tokId = await flowNFT.tokenIds();
        console.log("NFT created with id", tokId);

        await expect(createTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, tokId);

        const owner = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", owner);
        expect(owner).to.be.equal(receiver.address);

        const uri = await flowNFT.tokenURI(tokId);
        console.log("uri", uri);
        checkURI(uri);

        // timestamp...
        //expect(uri).to.equal("https://superfluid-nft.netlify.app/.netlify/functions/getmeta?token_symbol=MCK&token_decimals=18&sender=0x70997970c51812dc3a010c7d01b50e0d17dc79c8&receiver=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc&flowRate=1000&start_date=1665683687");
    });

    it("mint NFT to receiver by operator on create hook", async function () {
        const createTx = cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, operator.address, 1e9, true);

        const tokId = await flowNFT.tokenIds();
        console.log("NFT created with id", tokId);

        await expect(createTx)
            .to.emit(flowNFT, "Transfer")
            .withArgs(ZERO_ADDRESS, receiver.address, tokId);

        const owner = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", owner);
        expect(owner).to.be.equal(receiver.address);

        const uri = await flowNFT.tokenURI(tokId);
        console.log("uri", uri);
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
        const tokId = await flowNFT.tokenIds();
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

        // timestamp...
        //expect(uri).to.equal("https://superfluid-nft.netlify.app/.netlify/functions/getmeta?token_symbol=MCK&token_decimals=18&sender=0x70997970c51812dc3a010c7d01b50e0d17dc79c8&receiver=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc&flowRate=1000&start_date=1665683687");
    });

    it("burn NFT on delete hook", async function () {
        await cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, true);

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenIds();
        const o1 = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", o1);

        await cfaMock.fakeDeleteFlow(token1.address, sender.address, receiver.address, sender.address);
        await expect(flowNFT.ownerOf(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
        await expect(flowNFT.tokenURI(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
    });

    it("burn NFT on operator delete", async function () {
        await cfaMock.fakeCreateFlow(token1.address, sender.address, receiver.address, sender.address, 1e9, true);

        // TODO: hack to get the tokenId - should parse the Transfer event instead
        const tokId = await flowNFT.tokenIds();
        const o1 = await flowNFT.ownerOf(tokId);
        console.log("owner after mint", o1);

        await cfaMock.fakeDeleteFlow(token1.address, sender.address, receiver.address, operator.address);
        await expect(flowNFT.ownerOf(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
        await expect(flowNFT.tokenURI(tokId)).to.be.revertedWithCustomError(flowNFT, "NOT_EXISTS");
    });


    const BASE_URL = "https://superfluid-nft.netlify.app";
    function checkURI(uriStr, token, sender, receiver, startDate = 0) {
        const url = new URL(uriStr);
        const params = url.searchParams;
        expect(url.origin).to.be.equal(BASE_URL);
        //expect(params.token).to.be.equal(token.address);
    }

    /* test cases:
    * X create mints an NFT
    * X correct owner set
    * X delete burns the NFT
    * correct URI
    * manual minting: no start_date set
    * X ACL (flowOperator != sender): correct sender set
    */
})