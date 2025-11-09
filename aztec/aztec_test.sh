#!/bin/bash

set -euo pipefail

EVM_FILE="$HOME/aztec-sequencer/.evm"
[ -f "$EVM_FILE" ] || { echo "Не найден файл: $EVM_FILE" >&2; exit 1; }
set -a; . "$EVM_FILE"; set +a

: "${ETHEREUM_HOSTS:?нет ETHEREUM_HOSTS в .evm}"
: "${L1_CONSENSUS_HOST_URLS:?нет L1_CONSENSUS_HOST_URLS в .evm}"
: "${VALIDATOR_PRIVATE_KEY:?нет VALIDATOR_PRIVATE_KEY в .evm}"
: "${WALLET:?нет WALLET в .evm}"

ETHEREUM_RPC_URL="$ETHEREUM_HOSTS"
CONSENSUS_BEACON_URL="$L1_CONSENSUS_HOST_URLS"
OLD_VALIDATOR_PK="$VALIDATOR_PRIVATE_KEY"
WITHDRAW_ADDR="$WALLET"
PUBLIC_IP="${P2P_IP:-}"
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS="0xDCd9DdeAbEF70108cE02576df1eB333c4244C666"

docker stop aztec-sequencer
docker rm aztec-sequencer
sudo rm -rf "$HOME/my-node
sudo rm -rf $HOME/aztec-sequencer

sudo apt-get update -y
sudo apt-get install -y jq unzip lz4 ca-certificates gnupg curl

sudo -iu "${SUDO_USER:-$USER}" bash -lc 'curl -L https://foundry.paradigm.xyz | bash && export PATH="$HOME/.foundry/bin:$PATH" && foundryup && command -v cast >/dev/null 2>&1 || { echo "cast не установлен" >&2; exit 1; }'

bash -i <(curl -s https://install.aztec.network)
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> "$HOME/.bashrc"
. "$HOME/.bashrc" 2>/dev/null || true
aztec-up "2.1.2" || true
command -v aztec >/dev/null 2>&1 || { echo "aztec не установлен" >&2; exit 1; }

KFILE="$HOME/.aztec/keystore/key1.json"
if [ ! -f "$KFILE" ]; then
  aztec validator-keys new --fee-recipient 0x0000000000000000000000000000000000000000000000000000000000000000
  n=0; until [ -f "$KFILE" ] || [ $n -ge 20 ]; do sleep 1; n=$((n+1)); done
  [ -f "$KFILE" ] || { echo "keystore не найден: $KFILE" >&2; exit 1; }
fi

RAW_ETH_FIELD=$(jq -r '.validators[0].attester.eth // empty' "$KFILE")
BLS_KEY=$(jq -r '.validators[0].attester.bls // empty' "$KFILE")
FEE_RECIPIENT=$(jq -r '.validators[0].feeRecipient // "0x0000000000000000000000000000000000000000"' "$KFILE")
[ -n "$RAW_ETH_FIELD" ] || { echo "в $KFILE нет attester.eth" >&2; exit 1; }
[ -n "$BLS_KEY" ] || echo "внимание: attester.bls пустой" >&2

if [[ "$RAW_ETH_FIELD" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  ETH_ADDRESS="$RAW_ETH_FIELD"
elif [[ "$RAW_ETH_FIELD" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
  ETH_ADDRESS="$(cast wallet address "$RAW_ETH_FIELD")"
  [[ "$ETH_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo "не удалось получить адрес из приватника" >&2; exit 1; }
else
  echo "attester.eth в неизвестном формате" >&2; exit 1
fi

cast send 0x139d2a7a0881e16332d7D1F8DB383A4507E1Ea7A \
  "approve(address,uint256)" 0xebd99ff0ff6677205509ae73f93d0ca52ac85d67 200000ether \
  --private-key "$OLD_VALIDATOR_PK" \
  --rpc-url "$ETHEREUM_RPC_URL"

aztec add-l1-validator \
  --l1-rpc-urls "$ETHEREUM_RPC_URL" \
  --network testnet \
  --private-key "$OLD_VALIDATOR_PK" \
  --attester "$ETH_ADDRESS" \
  --withdrawer "$WITHDRAW_ADDR" \
  --bls-secret-key "$BLS_KEY" \
  --rollup "0xebd99ff0ff6677205509ae73f93d0ca52ac85d67"

WORKDIR="$HOME/aztec"
mkdir -p "$WORKDIR/keys" "$WORKDIR/data"

cat > "$WORKDIR/keys/keystore.json" <<EOF
{
  "schemaVersion": 1,
  "validators": [
    {
      "attester": { "eth": "$RAW_ETH_FIELD", "bls": "$BLS_KEY" },
      "coinbase": "$WITHDRAW_ADDR",
      "feeRecipient": "$FEE_RECIPIENT"
    }
  ]
}
EOF
chmod 600 "$WORKDIR/keys/keystore.json"

cat > "$WORKDIR/.env" <<EOF
ETHEREUM_RPC_URL=${ETHEREUM_RPC_URL}
CONSENSUS_BEACON_URL=${CONSENSUS_BEACON_URL}
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=${GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS}
P2P_IP=${PUBLIC_IP}
P2P_PORT=40400
AZTEC_PORT=8080
LOG_LEVEL=info
EOF

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  as_root sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
  as_root systemctl enable --now docker
fi
if ! docker compose version >/dev/null 2>&1; then
  as_root apt-get install -y docker-compose-plugin
  docker compose version >/dev/null 2>&1 || { echo "docker compose не найден" >&2; exit 1; }
fi

cat > "$WORKDIR/docker-compose.yml" <<EOF
services:
  aztec-node:
    container_name: aztec-sequencer
    image: aztecprotocol/aztec:2.1.2
    restart: unless-stopped
    network_mode: host
    environment:
      GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS: \${GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS}
      ETHEREUM_HOSTS: \${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: \${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /var/lib/data
      KEY_STORE_DIRECTORY: /var/lib/keystore
      P2P_IP: \${P2P_IP}
      P2P_PORT: \${P2P_PORT:-40400}
      AZTEC_PORT: \${AZTEC_PORT:-8080}
      LOG_LEVEL: \${LOG_LEVEL:-info}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network testnet --node --archiver --sequencer --snapshots-urls https://s3.us-east-1.amazonaws.com/aztec-testnet-snapshots'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
    volumes:
      - "$WORKDIR/data:/var/lib/data"
      - "$WORKDIR/keys:/var/lib/keystore"
EOF

cd "$WORKDIR"
docker compose --env-file "$WORKDIR/.env" up -d
docker compose logs -f -n 200
