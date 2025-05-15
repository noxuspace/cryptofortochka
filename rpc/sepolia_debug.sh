#!/bin/bash

GETH_YML="/home/geth_sepolia/eth-docker/geth.yml"

cp "$GETH_YML" "${GETH_YML}.bak"

grep -F -- '--http.api' "$GETH_YML" > /dev/null || \
  sed -i '/- --http.corsdomain=*/a \      - --http.api=eth,net,web3,debug' "$GETH_YML"

grep -F -- '--ws.api' "$GETH_YML" > /dev/null || \
  sed -i '/- --ws.origins=*/a \      - --ws.api=eth,net,web3,debug' "$GETH_YML"

sudo -u geth_sepolia /home/geth_sepolia/eth-docker/ethd restart execution
