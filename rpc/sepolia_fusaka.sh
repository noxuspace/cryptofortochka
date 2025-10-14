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

echo -e "${BLUE}Нормализуем CL_EXTRAS (задаём Teku supernode)...${NC}"
sed -i '/^CL_EXTRAS=/d' "${ENV_FILE}"
printf "CL_EXTRAS=%s\n" "${NEEDED_FLAG}" >> "${ENV_FILE}"
grep -n '^CL_EXTRAS=' "${ENV_FILE}"

cd "${STACK_DIR}"

echo -e "${BLUE}Перезапускаем consensus (мягко)...${NC}"
sudo -u "${USER_NAME}" ./ethd restart consensus || true
sleep 5

# Функция: проверка наличия флага в запущенном контейнере consensus
check_flag() {
  local cid
  cid=$(docker ps --format '{{.ID}} {{.Names}}' | awk '/consensus/{print $1}')
  if [ -z "$cid" ]; then
    echo "consensus-контейнер не найден."
    return 1
  fi
  if docker inspect "$cid" 2>/dev/null | grep -q -- "${NEEDED_FLAG}"; then
    echo -e "${GREEN}Флаг найден в аргументах контейнера consensus.${NC}"
    return 0
  else
    echo -e "${YELLOW}Флаг не обнаружен в текущем контейнере consensus.${NC}"
    return 1
  fi
}

if ! check_flag; then
  echo -e "${BLUE}Пробуем форс-пересоздать только consensus через ethd cmd...${NC}"
  sudo -u "${USER_NAME}" ./ethd down consensus || true
  sudo -u "${USER_NAME}" ./ethd cmd up -d --force-recreate consensus
  sleep 8
fi

if ! check_flag; then
  echo -e "${YELLOW}Флаг всё ещё не виден. Пересоздаём ВЕСЬ стек (down -> up).${NC}"
  sudo -u "${USER_NAME}" ./ethd down || true
  sudo -u "${USER_NAME}" ./ethd cmd up -d --force-recreate
  sleep 10
fi

if check_flag; then
  echo -e "${GREEN}OK: Teku работает с supernode-флагом: ${NEEDED_FLAG}${NC}"
else
  echo -e "${RED}Не удалось подтвердить наличие флага. Проверь вручную:${NC}"
  echo 'CID=$(docker ps --format "{{.ID}} {{.Names}}" | awk "/consensus/{print $1}")'
  echo 'docker inspect "$CID" | grep -n -- "--p2p-subscribe-all-custody-subnets-enabled"'
fi

echo -e "${BLUE}Ключевые строки из логов консенсуса (custody/subnet/peerdas/supernode):${NC}"
sudo -u "${USER_NAME}" ./ethd logs consensus | egrep -i 'custody|subnet|peerdas|supernode' -n | tail -n 80 || true

echo -e "${BLUE}Быстрый sanity-check EL RPC:${NC}"
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
