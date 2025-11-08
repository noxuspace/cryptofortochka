#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
WORKDIR="/root/aztec"
KEYS_DIR="$WORKDIR/keys"
DATA_DIR="$WORKDIR/data"
KFILE="$HOME/.aztec/keystore/key1.json"

# Docker Compose (auto-detect)
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  COMPOSE=""
fi

ROLLUP_ADDR="0xebd99ff0ff6677205509ae73f93d0ca52ac85d67"
AZTEC_IMG_TAG="2.1.2"

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
echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in
# =================== 1) Установка Foundry + Aztec =============
1)
  echo -e "${BLUE}Обновляем систему и ставим зависимости...${NC}"
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y jq unzip lz4 ca-certificates gnupg

  echo -e "${BLUE}Устанавливаем Foundry...${NC}"
  curl -L https://foundry.paradigm.xyz | bash
  # shellcheck disable=SC1090
  source "$HOME/.bashrc" 2>/dev/null || true
  if ! command -v foundryup >/dev/null 2>&1; then
    # если bashrc не подхватился
    # shellcheck disable=SC1091
    source "$HOME/.foundry/bin/init" 2>/dev/null || true
  fi
  foundryup || { echo -e "${RED}Не удалось выполнить foundryup${NC}"; exit 1; }

  echo -e "${GREEN}cast версия:${NC} $(cast --version 2>/dev/null || echo 'не обнаружен')"

  echo -e "${BLUE}Устанавливаем Aztec CLI...${NC}"
  bash -i <(curl -s https://install.aztec.network)
  echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> "$HOME/.bashrc"
  # shellcheck disable=SC1090
  source "$HOME/.bashrc" 2>/dev/null || true
  aztec-up "$AZTEC_IMG_TAG" || true

  echo -e "${GREEN}aztec версия:${NC} $(aztec --version 2>/dev/null || echo 'не обнаружен')"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Подготовка сервера завершена, перейдите в текстовый гайд и следуйте дальнейшим инструкциям!${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# =================== 2) Запуск ноды (всё остальное) ===========
2)
  # каталоги
  mkdir -p "$KEYS_DIR" "$DATA_DIR"
  cd "$WORKDIR" || { echo -e "${RED}Не удалось перейти в $WORKDIR${NC}"; exit 1; }

  # --- КЛЮЧИ: генерируем 1 раз, иначе читаем файл (идемпотентно) ---
  if [ ! -f "$KFILE" ]; then
    echo -e "${BLUE}Создаем ключи валидатора...${NC}"
    # feeRecipient как в гайде (нулевой)
    aztec validator-keys new \
      --fee-recipient 0x0000000000000000000000000000000000000000000000000000000000000000 || {
      echo -e "${RED}Ошибка генерации ключей aztec${NC}"; exit 1;
    }
    # ждём появления файла
    n=0; until [ -f "$KFILE" ] || [ $n -ge 10 ]; do sleep 1; n=$((n+1)); done
    [ -f "$KFILE" ] || { echo -e "${RED}Keystore не найден: $KFILE${NC}"; exit 1; }
  else
    echo -e "${PURPLE}Файл ключей найден — пропускаю генерацию.${NC}"
  fi

  RAW_ETH_FIELD=$(jq -r '.validators[0].attester.eth // empty' "$KFILE" 2>/dev/null || true)
  BLS_KEY=$(jq -r '.validators[0].attester.bls // empty' "$KFILE" 2>/dev/null || true)
  FEE_RECIPIENT=$(jq -r '.validators[0].feeRecipient // "0x0000000000000000000000000000000000000000"' "$KFILE" 2>/dev/null || true)

  if [ -z "$RAW_ETH_FIELD" ]; then echo -e "${RED}Не найдено поле attester.eth в $KFILE${NC}"; exit 1; fi
  if [ -z "$BLS_KEY" ]; then echo -e "${YELLOW}Внимание: attester.bls пустой в $KFILE${NC}"; fi

  # Получаем публичный адрес из приватника при необходимости (cast обязателен)
  if [[ "$RAW_ETH_FIELD" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    ETH_ADDRESS="$RAW_ETH_FIELD"
  elif [[ "$RAW_ETH_FIELD" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    command -v cast >/dev/null 2>&1 || { echo -e "${RED}Нужен cast (Foundry) для вывода адреса из приватника${NC}"; exit 1; }
    ETH_ADDRESS="$(cast wallet address "$RAW_ETH_FIELD" 2>/dev/null || true)"
    [[ "$ETH_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo -e "${RED}Не удалось вычислить ETH-адрес через cast${NC}"; exit 1; }
  else
    echo -e "${RED}attester.eth в неизвестном формате: $RAW_ETH_FIELD${NC}"; exit 1
  fi

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${RED}Пополните минимум 0.2 ETH в сети Sepolia на адрес:${NC}"
  echo -e "${CYAN}${ETH_ADDRESS}${NC}"
  echo -e "${RED}и убедитесь на сайте https://sepolia.etherscan.io, что средства зачислены!${NC}"
  echo -ne "${YELLOW}После этого нажмите Enter для продолжения...${NC}"; read -r _

  # --- Параметры для регистрации валидатора ---
  echo -ne "${YELLOW}Введите приватный ключ от валидатора, который участвовал в предыдущих тестнетах (без 0x): ${NC}"; read -r OLD_VALIDATOR_PK
  echo -ne "${YELLOW}Введите адрес вывода стейка (любой адрес кошелька, к которому вы имеете доступ): ${NC}"; read -r WITHDRAW_ADDR

  # RPC + Beacon + IP
  echo -ne "${YELLOW}Введите ETHEREUM_RPC_URL (Sepolia): ${NC}"; read -r ETHEREUM_RPC_URL
  echo -ne "${YELLOW}Введите CONSENSUS_BEACON_URL: ${NC}"; read -r CONSENSUS_BEACON_URL
  DETECT_IP="$(curl -s4 https://ipecho.net/plain || curl -s4 ifconfig.me || echo "")"
  echo -ne "${YELLOW}Публичный IP этого сервера [${DETECT_IP}]: ${NC}"; read -r P2P_IP
  P2P_IP=${P2P_IP:-$DETECT_IP}

  # --- approve на 200k STK (ERC20) ---
  echo -e "${BLUE}Отправляю approve на 200000 STK для роллапа...${NC}"
  cast send 0x139d2a7a0881e16332d7D1F8DB383A4507E1Ea7A \
    "approve(address,uint256)" $ROLLUP_ADDR 200000ether \
    --private-key "$OLD_VALIDATOR_PK" \
    --rpc-url "$ETHEREUM_RPC_URL" || {
      echo -e "${RED}Не удалось выполнить approve (cast send)${NC}"; exit 1;
    }

  # --- регистрация валидатора ---
  echo -e "${BLUE}Регистрирую валидатора в сети Aztec...${NC}"
  aztec add-l1-validator \
    --l1-rpc-urls "$ETHEREUM_RPC_URL" \
    --network testnet \
    --private-key "$OLD_VALIDATOR_PK" \
    --attester "$ETH_ADDRESS" \
    --withdrawer "$WITHDRAW_ADDR" \
    --bls-secret-key "$BLS_KEY" \
    --rollup "$ROLLUP_ADDR" || {
      echo -e "${RED}Ошибка регистрации валидатора (aztec add-l1-validator)${NC}"; exit 1;
    }

  echo -e "${PURPLE}Проверьте очередь валидаторов: ${CYAN}https://dashtec.xyz/queue${NC}"
  echo -e "${PURPLE}Ищите по адресу аттестера: ${CYAN}${ETH_ADDRESS}${NC}"
  echo -ne "${YELLOW}После этого нажмите Enter для продолжения...${NC}"; read -r _

  # --- keystore.json для контейнера (coinbase = WITHDRAW_ADDR) ---
  cat > "$KEYS_DIR/keystore.json" <<EOF
{
  "schemaVersion": 1,
  "validators": [
    {
      "attester": {
        "eth": "$RAW_ETH_FIELD",
        "bls": "$BLS_KEY"
      },
      "coinbase": "$WITHDRAW_ADDR",
      "feeRecipient": "$FEE_RECIPIENT"
    }
  ]
}
EOF
  chmod 600 "$KEYS_DIR/keystore.json"
  echo -e "${GREEN}keystore.json создан: ${KEYS_DIR}/keystore.json${NC}"

  # --- .env с дефолтными портами/лог-левелом ---
  cat > "$WORKDIR/.env" <<EOF
ETHEREUM_RPC_URL=${ETHEREUM_RPC_URL}
CONSENSUS_BEACON_URL=${CONSENSUS_BEACON_URL}
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0xDCd9DdeAbEF70108cE02576df1eB333c4244C666
P2P_IP=${P2P_IP}
P2P_PORT=40400
AZTEC_PORT=8080
LOG_LEVEL=info
EOF

  # --- docker / compose ---
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаю Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -f get-docker.sh
    $SUDO usermod -aG docker "$USER" 2>/dev/null || true
    $SUDO systemctl enable --now docker 2>/dev/null || true
  fi
  if [ -z "$COMPOSE" ]; then
    echo -e "${BLUE}Ставлю docker compose-plugin...${NC}"
    $SUDO apt-get install -y docker-compose-plugin || true
    if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"; fi
    if [ -z "$COMPOSE" ] && command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"; fi
    [ -n "$COMPOSE" ] || { echo -e "${RED}Docker Compose не найден${NC}"; exit 1; }
  fi

  # --- docker-compose.yml ---
  cat > "$WORKDIR/docker-compose.yml" <<'EOF'
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

  cd ~
  # --- запуск и логи ---
  cd aztec
  $COMPOSE --env-file "$WORKDIR/.env" up -d
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${YELLOW}Команда для проверки логов:${NC}"
  echo "cd ~/aztec && docker compose logs -f -n 200"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  sleep 2
  $COMPOSE logs -fn 200
  ;;

# ==================== 3) Логи (онлайн) =======================
3)
  if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR" && ${COMPOSE:-"docker compose"} logs -fn 200
  else
    echo -e "${RED}Каталог $WORKDIR не найден.${NC}"
  fi
  ;;

# ===================== 4) Перезапуск =========================
4)
  if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR" && ${COMPOSE:-"docker compose"} restart && echo -e "${GREEN}Перезапущено.${NC}"
  else
    echo -e "${RED}Каталог $WORKDIR не найден.${NC}"
  fi
  ;;

# ==================== 5) Полное удаление =====================
5)
  echo -ne "${RED}Удалить контейнер, данные и конфиги Aztec? (YES/NO) ${NC}"; read CONFIRM
  if [ "$CONFIRM" = "YES" ]; then
    if [ -d "$WORKDIR" ]; then
      cd "$WORKDIR" || exit 1
      ${COMPOSE:-"docker compose"} down -v || true
    fi
    docker rm -f aztec-sequencer >/dev/null 2>&1 || true
    docker rmi aztecprotocol/aztec:${AZTEC_IMG_TAG} >/dev/null 2>&1 || true
    rm -rf "$WORKDIR" 2>/dev/null || true
    echo -ne "${YELLOW}Удалить локальный keystore ~/.aztec/ ? (YES/NO) ${NC}"; read DEL_KEYS
    if [ "$DEL_KEYS" = "YES" ]; then
      rm -rf "$HOME/.aztec" 2>/dev/null || true
      echo -e "${GREEN}~/.aztec удалён.${NC}"
    else
      echo -e "${PURPLE}Keystore ~/.aztec сохранён.${NC}"
    fi
    echo -e "${GREEN}Удаление завершено.${NC}"
  else
    echo -e "${PURPLE}Отмена удаления. Ничего не изменено.${NC}"
  fi
  ;;

# ============================ Неверный ввод ===================
*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}" ;;
esac
