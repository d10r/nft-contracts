## Deploy

Checkout the repo, then

```
yarn install
yarn build
```

Then deploy to one of the supported networks (see `hardhat.config.ts`) with `yarn deploy-to <network>`.  
Provide a private key and RPC via .env file or cmdline env vars.
Example for deploying to Polygon:
```
MATIC_RPC=https://your.rpc MATIC_PK=0x123... yarn deploy-to matic
```
