#!/bin/bash
# Accept chain name and transaction hash as command line arguments
CHAIN_NAME=$1
TRANSACTION_HASH=$2
# Check if both chain name and transaction hash are provided
if [ -z "$CHAIN_NAME" ] || [ -z "$TRANSACTION_HASH" ]; then
  echo "Error: Please provide both the chain name and transaction hash as arguments."
  exit 1
fi
#  if you want to test on mainnet or any other chain pass chain name it only support infura  aslo make sure to enable chain rpc url on infura
#1. arbitrum-sepolia
#2. arbitrum-mainnet
#3. sepolia.infura
yarn trace $TRANSACTION_HASH --rpc  https://${CHAIN_NAME}.infura.io/v3/44bc61f9083149c3a96b0d37f08ed8c0
