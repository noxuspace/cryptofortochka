#!/bin/bash
set -euo pipefail

# ---- Цвета ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
NC='\033[0m'

USER_NAME="geth_sepolia"
STACK_DIR="/home/${USER_NAME}/eth-docker"
ENV_FILE="${STACK_DIR}/.env"
NEEDED_FLAG="--p2p-subscribe-all-custody-subnets-enabled"

echo -e "${BLUE}Проверяем файлы eth-docker...${NC}"
if [ ! -d "$STACK_DIR" ] || [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}Не найден ${ENV_FILE}. Проверь пользователя и путь.${NC}" >&2
  exit 1
fi

echo -e "${BLUE}Делаем бэкап .env...${NC}"
cp -a "${ENV_FILE}" "${ENV_FILE}.bak.$(date +%F_%H-%M-%S)"

echo -e "${BLUE}Обновляем CL_EXTRAS (включаем Teku supernode)...${NC}"
sed -i '/^CL_EXTRAS=/d' "${ENV_FILE}"
printf "CL_EXTRAS=%s\n" "${NEEDED_FLAG}" >> "${ENV_FILE}"
grep -n '^CL_EXTRAS=' "${ENV_FILE}"

cd "${STACK_DIR}"

echo -e "${BLUE}Полностью перезапускаем стек Eth Docker (down -> up)...${NC}"
sudo -u "${USER_NAME}" ./ethd down || true
sudo -u "${USER_NAME}" ./ethd cmd up -d --force-recreate
sleep 10

# Проверка наличия флага в контейнере consensus
CID=$(docker ps --format '{{.ID}} {{.Names}}' | awk '/consensus/{print $1}' || true)
if [ -z "$CID" ]; then
  echo -e "${RED}Не удалось найти контейнер consensus после рестарта!${NC}"
else
  if docker inspect "$CID" | grep -q -- "${NEEDED_FLAG}"; then
    echo -e "${GREEN}OK: Teku работает с флагом supernode: ${NEEDED_FLAG}${NC}"
  else
    echo -e "${RED}Флаг ${NEEDED_FLAG} не обнаружен в аргументах контейнера!${NC}"
    echo -e "${YELLOW}Проверь вручную:${NC}"
    echo "docker inspect \"$CID\" | grep -n -- \"${NEEDED_FLAG}\""
  fi
fi

echo -e "${BLUE}Проверяем логи консенсуса (custody/subnet/peerdas/supernode)...${NC}"
sudo -u "${USER_NAME}" ./ethd logs consensus | egrep -i 'custody|subnet|peerdas|supernode' -n | tail -n 50 || true

echo -e "${BLUE}Быстрая проверка синхронизации EL RPC:${NC}"
curl -s -X POST http://127.0.0.1:58545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'; echo
curl -s -X POST http://127.0.0.1:58545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":2}' | jq -r .result || true; echo

echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Онлайн-логи консенсуса:${NC}"
echo "cd ${STACK_DIR} && ./ethd logs -f consensus"
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
