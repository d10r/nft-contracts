#!/bin/bash -eux

declare -A cfaAddrs

# TODO: fetch from metadata

# testnets
cfaAddrs["avafuji"]=0xED74d30B8034152b0638CB03cc5c3c906dd1c482
cfaAddrs["mumbai"]=0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873
cfaAddrs["goerli"]=0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8

# mainnets
cfaAddrs["matic"]=0x6EeE6060f715257b970700bc2656De21dEdF074C

name=${NAME:-"Superfluid Stream"}
symbol=${SYMBOL:-"SFS"}

network=$1
cfa=${cfaAddrs[$network]}

echo "network: $network, cfa: $cfa name: $name, symbol: $symbol"

nftAddr=$(CFA=$cfa NAME="$name" SYMBOL="$symbol" npx hardhat run --network $network scripts/deploy.js | cut -d " " -f 4)

echo "NFT contract addr: $nftAddr"

# give the explorer some time to index
sleep 15

echo "trying to verify. If it fails, manually retry the last command after waiting a bit more"
npx hardhat verify --network $network $nftAddr $cfa "$name" "$symbol"
