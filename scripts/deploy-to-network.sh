#!/bin/bash -eu

name=${NAME:-"Superfluid Stream"}
symbol=${SYMBOL:-"SFS"}

network=$1

networksFile=https://raw.githubusercontent.com/superfluid-finance/metadata/master/networks.json
cfa=$(curl -sf $networksFile | jq -r '.[] | select(.name == "'$network'") | .contractsV1.cfaV1')

if [ -z $cfa ]; then
    echo "CFA contract not found for \"$network\" - double check if this is a canonical network name"
    exit 1
fi

echo "network: $network, cfa: $cfa, name: $name, symbol: $symbol"

nftAddr=$(CFA=$cfa NAME="$name" SYMBOL="$symbol" npx hardhat run --network $network scripts/deploy.js | cut -d " " -f 4)

echo "NFT contract addr: $nftAddr"

# give the explorer some time to index
sleep 15

echo "trying to verify. If it fails, manually retry with this command after waiting a bit more:"
verifyCmd="npx hardhat verify --network $network $nftAddr $cfa \"$name\" \"$symbol\""
echo "$verifyCmd"
eval $verifyCmd
