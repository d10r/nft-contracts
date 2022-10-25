## Deploy

Clone the repo, then

```
yarn install
yarn build
```

Then deploy to one of the supported networks (see `hardhat.config.ts`) with `yarn deploy-to <network>`.  
Provide a private key and RPC via .env file or cmdline env vars.
Example for deploying to Görli:
```
ETH_GOERLI_RPC=https://eth-goerli.g.alchemy.com/v2/demo ETH_GOERLI_PK=0x123... yarn deploy-to eth-goerli
```

The canonical network names as defined in [@superfluid-finance/metadata](https://github.com/superfluid-finance/metadata) are used.

## Known bugs

Method `tokenURI` of the `FlowNFT` contract will append a `0` to the value of `flowRate` if the start date is not set (that is, if `mint()` is not invoked via the hook). Can be worked around by the caller.