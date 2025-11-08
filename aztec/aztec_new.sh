#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
BASE_DIR="/root/aztec"
KEYS_DIR="$BASE_DIR/keys"
DATA_DIR="$BASE_DIR/data"
ENV_FILE="$BASE_DIR/.env"
DC_FILE="$BASE_DIR/docker-compose.yml"

AZTEC_BIN_DIR="$HOME/.aztec/bin"
export PATH="$AZTEC_BIN_DIR:$PATH"

GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS="0xDCd9DdeAbEF70108cE02576df1eB333c4244C666"
AZTEC_IMAGE="aztecprotocol/aztec:2.1.2"
AZTEC_VERSION_CLI="2.1.2"
ROLLUP_ADDR="0xebd99ff0ff6677205509ae73f93d0ca52ac85d67"
SEP_RPC_DEFAULT="https://0xrpc.io/sep"

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  $SUDO apt-get update -y >/dev/null 2>&1 || true
  $SUDO apt-get install -y curl >/dev/null 2>&1 || true
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# ============================== Меню =========================
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Запуск ноды${NC}"
echo -e "${CYAN}3) Логи ноды${NC}"
echo -e "${CYAN}4) Перезапуск ноды${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"; read -r choice

case "$choice" in

# ================= 1) Установка окружения ====================
1)
  echo -e "${BLUE}Обновляем систему и базовые пакеты...${NC}"
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y jq git wget unzip ca-certificates lsb-release bash-completion

  # Foundry
  if ! command -v cast >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Foundry...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source "$HOME/.bashrc" 2>/dev/null || true
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup || true
  else
    echo -e "${PURPLE}Foundry уже установлен. Обновляем foundryup...${NC}"
    foundryup || true
  fi

  if command -v cast >/dev/null 2>&1; then
    echo -e "${GREEN}✅ cast: $(cast --version)${NC}"
  fi
  sleep 3

  # Aztec CLI
  if ! command -v aztec >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаtv Aztec CLI...${NC}"
    bash -i <(curl -s https://install.aztec.network)
    echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc" 2>/dev/null || true
  else
    echo -e "${PURPLE}Aztec CLI уже установлен.${NC}"
  fi

  if command -v aztec-up >/dev/null 2>&1; then
    echo -e "${BLUE}Переключаем Aztec CLI на версию ${AZTEC_VERSION_CLI}...${NC}"
    aztec-up "${AZTEC_VERSION_CLI}" || true
  fi

  if command -v aztec >/dev/null 2>&1; then
    echo -e "${GREEN}✅ aztec: $(aztec --version)${NC}"
  fi

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Подготовка сервера завершена, перейдите в текстовый гайд и следуйте дальнейшим инструкциям!${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ===================== 2) Запуск ноды ========================
2)
  mkdir -p "$KEYS_DIR" "$DATA_DIR"
  cd "$BASE_DIR" || exit 1

  # Создание ключей
  if [[ ! -f "$HOME/.aztec/keystore/key1.json" ]]; then
    echo -e "${BLUE}Создаю ключи валидатора...${NC}"
    aztec validator-keys new \
      --fee-recipient 0x0000000000000000000000000000000000000000000000000000000000000000
  fi

  KFILE="$HOME/.aztec/keystore/key1.json"
  ETH_KEY=$(jq -r '.validators[0].attester.eth' "$KFILE")
  BLS_KEY=$(jq -r '.validators[0].attester.bls' "$KFILE")
  FEE_RECIPIENT=$(jq -r '.validators[0].feeRecipient // "0x0000000000000000000000000000000000000000000000000000000000000000"' "$KFILE")

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${RED}Пополните минимум 0.2 ETH в сети Sepolia на адрес:${NC}"
  echo -e "${CYAN}${ETH_KEY}${NC}"
  echo -e "${RED}и убедитесь на сайте https://sepolia.etherscan.io, что средства зачислены!${NC}"
  echo -ne "${YELLOW}После этого нажмите Enter для продолжения...${NC}"
  read -r _

  echo -ne "${YELLOW}Введите приватный ключ от валидатора, который участвовал в предыдущих тестнетах (без 0x): ${NC}"
  read -r OLD_PRIV_NO0X
  OLD_PRIV="0x${OLD_PRIV_NO0X}"

  echo -ne "${YELLOW}Введите адрес вывода стейка (любой адрес кошелька, к которому вы имеете доступ): ${NC}"
  read -r WITHDRAW_ADDR

  echo -e "${BLUE}Отправляем approve(200000 STK)...${NC}"
  cast send 0x139d2a7a0881e16332d7D1F8DB383A4507E1Ea7A \
    "approve(address,uint256)" $ROLLUP_ADDR 200000ether \
    --private-key "$OLD_PRIV" --rpc-url "$SEP_RPC_DEFAULT" || true

  echo -e "${BLUE}Регистрируем валидатора...${NC}"
  aztec add-l1-validator \
    --l1-rpc-urls "$SEP_RPC_DEFAULT" \
    --network testnet \
    --private-key "$OLD_PRIV" \
    --attester "$ETH_KEY" \
    --withdrawer "$WITHDRAW_ADDR" \
    --bls-secret-key "$BLS_KEY" \
    --rollup "$ROLLUP_ADDR" || true

  echo -e "${PURPLE}Проверьте очередь валидаторов: https://dashtec.xyz/queue${NC}"
  sleep 2
  # keystore.json
  cat > "$KEYS_DIR/keystore.json" <<EOF
{
  "schemaVersion": 1,
  "validators": [
    {
      "attester": {
        "eth": "$ETH_KEY",
        "bls": "$BLS_KEY"
      },
      "coinbase": "$WITHDRAW_ADDR",
      "feeRecipient": "$FEE_RECIPIENT"
    }
  ]
}
EOF
  chmod 600 "$KEYS_DIR/keystore.json"

  # .env (фиксированные параметры)
  PUBLIC_IP=$(curl -4 -s https://ipecho.net/plain || true)
  if [[ -z "$PUBLIC_IP" ]]; then
    echo -ne "${YELLOW}Введите публичный IP сервера: ${NC}"
    read -r PUBLIC_IP
  fi
  echo -ne "${YELLOW}Введите ETHEREUM_RPC_URL (Sepolia): ${NC}"
  read -r ETHEREUM_RPC_URL
  echo -ne "${YELLOW}Введите CONSENSUS_BEACON_URL: ${NC}"
  read -r CONSENSUS_BEACON_URL

  cat > "$ENV_FILE" <<EOF
ETHEREUM_RPC_URL=${ETHEREUM_RPC_URL}
CONSENSUS_BEACON_URL=${CONSENSUS_BEACON_URL}
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=${GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS}
P2P_IP=${PUBLIC_IP}
P2P_PORT=40400
AZTEC_PORT=8080
LOG_LEVEL=info
EOF

  # docker-compose.yml
  cat > "$DC_FILE" <<'EOF'
services:
  aztec-node:
    container_name: aztec-sequencer
    image: aztecprotocol/aztec:2.1.2
    restart: unless-stopped
    network_mode: host
    environment:
      GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS: ${GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS}
      ETHEREUM_HOSTS: ${ETHEREUM_RPC_URL}
      L1_CONSENSUS_HOST_URLS: ${CONSENSUS_BEACON_URL}
      DATA_DIRECTORY: /var/lib/data
      KEY_STORE_DIRECTORY: /var/lib/keystore
      P2P_IP: ${P2P_IP}
      P2P_PORT: ${P2P_PORT:-40400}
      AZTEC_PORT: ${AZTEC_PORT:-8080}
      LOG_LEVEL: ${LOG_LEVEL:-info}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network testnet --node --archiver --sequencer --snapshots-urls https://s3.us-east-1.amazonaws.com/aztec-testnet-snapshots'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
    volumes:
      - /root/aztec/data:/var/lib/data
      - /root/aztec/keys:/var/lib/keystore
EOF

  docker compose up -d

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${YELLOW}Команда для проверки логов:${NC}"
  echo "cd $BASE_DIR && docker compose logs -fn 200"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  sleep 2
  docker compose logs -fn 200
  ;;

# ==================== 3) Логи =======================
3)
  (cd "$BASE_DIR" && docker compose logs -fn 200)
  ;;

# ==================== 4) Перезапуск ====================
4)
  (cd "$BASE_DIR" && docker compose restart)
  ;;

# ==================== 5) Удаление ====================
5)
  echo -ne "${RED}Удалить ноду и все данные (${BASE_DIR})? (YES/NO) ${NC}"
  read -r CONFIRM
  if [[ "$CONFIRM" = "YES" ]]; then
    (cd "$BASE_DIR" && docker compose down -v) || true
    rm -rf "$BASE_DIR"
    echo -e "${GREEN}Удалено.${NC}"
  else
    echo -e "${PURPLE}Отмена удаления.${NC}"
  fi
  ;;

*)
  echo -e "${RED}Неверный выбор.${NC}" ;;
esac

