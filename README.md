# About

This repo contains contracts representing Superfluid CFA flows.

**FlowNFT** is stateful and intended as visualization of incoming flows.  
Minting can be done via CFAv1 flow creatoin hooks or retroactively (permissionless).

**FlowSender721** is a minimal [ERC721](https://eips.ethereum.org/EIPS/eip-721) implementation (without ERC721Metadata extension)
which maps the ERC721 API to flows of a specific SuperToken and receiver.  
It's stateless and intended for token-curated communities like https://guild.xyz/.  
The 2 relevant methods are `ownerOf(tokenId)` and `balanceOf(owner)`,
where `tokenId` is the flow sender (cast to uint256) and `owner` is also the flow sender.

## Deployment

The hardhat network config is dynamically created from the [Superfluid metadata package](https://github.com/superfluid-finance/metadata).  
In order to list the names of the networks injected into the config, do
```sh
yarn list-sf-networks
```
(requires `jq` to be installed).

## Deploy FlowNFT

Clone the repo, then

```sh
yarn install
yarn build
```

Then deploy to one of the supported networks (see `hardhat.config.ts`) with `yarn deploy-flownft-to <network>`.  
Provide a private key and RPC via .env file or cmdline env vars.
Example for deploying to Görli:
```
ETH_GOERLI_RPC=https://eth-goerli.g.alchemy.com/v2/demo ETH_GOERLI_PK=0x123... yarn deploy-flownft-to eth-goerli
```

The canonical network names as defined in [@superfluid-finance/metadata](https://github.com/superfluid-finance/metadata) are used.

## Deploy FlowSender721

Since a dedicated contract per SuperToken and receiver is required, this contract comes with a factory.  
The hardhat script [scripts/deploy-fs721factory.js] deploys that factory using [this deterministic deployment proxy](https://github.com/Zoltu/deterministic-deployment-proxy) already available on most relevant public networks at address [0x7A0D94F55792C434d74a40883C6ed8545E406D12](https://blockscan.com/address/0x7A0D94F55792C434d74a40883C6ed8545E406D12).

In order to deploy the factory, do:
```sh
npx hardhat run --network <network> scripts/deploy-fs721factory.js
```

For public networks with Superfluid deployment, the needed host address will be fetched from the [superfluid metadata package](https://github.com/superfluid-finance/metadata) injected into the hardhat network config (see [hardhat.config.ts]).

Once the factory is deployed, instances of the FlowSender721 contract can be deployed with:
```sh
SUPERTOKEN=<supertoken address> RECEIVER=<receiver address> npx hardhat run --network <network> scripts/deploy-fs721.js
```

If an instance with the given configuration already exists, the script will printed its address to stdout and exit.

You can find SuperToken addresses at https://console.superfluid.finance/supertokens (select the right network).

You may want to verify the first instance deployed on a network on the canonical block explorer. Successive instances will then automatically be verified:
```sh
npx hardhat verify --network <network> <instance addr> <cfa addr> <supertoken addr> <receiver addr>
```

## UI

There's a simple Dapp for deploying FlowSender721 instances in directory `ui`.
In order to run locally, you can start a webserver with
```sh
python -m SimpleHTTPServer 1337
```
then navigate to http://localhost:1337 in a browser.

Or use an IPFS-hosted instance at https://ipfs.io/ipfs/QmNxTTeeoFKeNSpUJ3SfoPqb4n1MTSYQRGSj4oASCYFWMd.

## Known bugs

FlowNFT:  
* The method `tokenURI` of the `FlowNFT` contract will append a `0` to the value of `flowRate` if the start date is not set (that is, if `mint()` is not invoked via the hook). Can be worked around by the caller.
* The method `balanceOf` always returns 1 - this is not a bug per se, but a conscious choice in order to save gas.