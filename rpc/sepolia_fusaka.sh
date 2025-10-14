#!/bin/bash
set -euo pipefail

# ---- Цвета (как в твоих шаблонах) ----
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

echo -e "${BLUE}Нормализуем CL_EXTRAS (удаляем дубли и задаём supernode для Teku)...${NC}"
# Удаляем все строки CL_EXTRAS= и добавляем нашу в конец
sed -i '/^CL_EXTRAS=/d' "${ENV_FILE}"
printf "CL_EXTRAS=%s\n" "${NEEDED_FLAG}" >> "${ENV_FILE}"

echo -e "${BLUE}Быстрая проверка .env:${NC}"
grep -n '^CL_EXTRAS=' "${ENV_FILE}" || { echo -e "${RED}CL_EXTRAS не найден в .env${NC}"; exit 1; }

# Информируем, если репо грязное (не стопаем из-за этого)
if command -v git >/dev/null 2>&1; then
  if git -C "${STACK_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ -n "$(git -C "${STACK_DIR}" status --porcelain || true)" ]; then
      echo -e "${YELLOW}ВНИМАНИЕ: в ${STACK_DIR} есть локальные изменения git (geth.yml / teku-cl-only.yml и т.п.).${NC}"
      echo -e "${YELLOW}Мы их НЕ трогаем. Обновление образов через 'ethd update' может ругаться. Сейчас применяем только перезапуск контейнеров.${NC}"
    fi
  fi
fi

cd "${STACK_DIR}"

echo -e "${BLUE}Форс-пересоздаём consensus с новым .env...${NC}"
# Через wrapper eth-docker; если wrapper недоступен, используем docker compose напрямую
if [ -x "${STACK_DIR}/ethd" ]; then
  sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" compose up -d --force-recreate consensus
else
  docker compose up -d --force-recreate consensus
fi

sleep 5

echo -e "${BLUE}Проверяем аргументы запущенного consensus-контейнера...${NC}"
CID=$(docker ps --format '{{.ID}} {{.Names}}' | awk '/consensus/{print $1}' || true)
if [ -z "${CID}" ]; then
  echo -e "${YELLOW}Не нашли контейнер consensus в docker ps. Попробуем поднять весь стек.${NC}"
fi

HAS_FLAG="no"
if [ -n "${CID}" ]; then
  # Ищем флаг в Cmd/Args/Entrypoint
  if docker inspect "$CID" | jq -e --arg f "${NEEDED_FLAG}" '
     (.[0].Args//[]) | join(" ") | test($f)
     or (.[0].Config.Cmd//[]) | join(" ") | test($f)
     or ((.[0].Config.Entrypoint//[]) | join(" ") | test($f))
  ' >/dev/null; then
    HAS_FLAG="yes"
  fi
fi

if [ "${HAS_FLAG}" != "yes" ]; then
  echo -e "${YELLOW}Флаг в текущем консенсус-контейнере не обнаружен. Перезапускаем ВЕСЬ стек для надёжности...${NC}"
  if [ -x "${STACK_DIR}/ethd" ]; then
    sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" down
    sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" compose up -d --force-recreate
  else
    docker compose down
    docker compose up -d --force-recreate
  fi
  sleep 8

  CID=$(docker ps --format '{{.ID}} {{.Names}}' | awk '/consensus/{print $1}' || true)
  if [ -n "${CID}" ] && docker inspect "$CID" | jq -e --arg f "${NEEDED_FLAG}" '
       (.[0].Args//[]) | join(" ") | test($f)
       or (.[0].Config.Cmd//[]) | join(" ") | test($f)
       or ((.[0].Config.Entrypoint//[]) | join(" ") | test($f))
     ' >/dev/null; then
    HAS_FLAG="yes"
  fi
fi

if [ "${HAS_FLAG}" = "yes" ]; then
  echo -e "${GREEN}OK: Teku запущен с флагом supernode: ${NEEDED_FLAG}${NC}"
else
  echo -e "${RED}ВНИМАНИЕ: не удалось подтвердить наличие флага в аргументах контейнера!${NC}"
  echo -e "${YELLOW}Ручная проверка:${NC}"
  echo "docker inspect \"\$CID\" | jq -r '.[0].Config.Cmd // [] | join(\" \")'"
  echo "docker exec -it \"\$CID\" ps aux | grep -i teku"
fi

echo -e "${BLUE}Просматриваем последние логи консенсуса (ключевые слова custody/subnet/peerdas)...${NC}"
if [ -x "${STACK_DIR}/ethd" ]; then
  sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" logs consensus | egrep -i 'custody|subnet|peerdas|supernode' -n | tail -n 80 || true
else
  docker logs "$(docker ps --format '{{.Names}}' | awk '/consensus/{print $1}' | head -n1)" 2>&1 | egrep -i 'custody|subnet|peerdas|supernode' -n | tail -n 80 || true
fi

echo -e "${BLUE}Быстрый sanity-check EL RPC:${NC}"
curl -s -X POST http://127.0.0.1:58545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
echo
curl -s -X POST http://127.0.0.1:58545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":2}' | jq -r .result
echo

echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Команда для проверки логов консенсуса в онлайне:${NC}"
echo "cd ${STACK_DIR} && ./ethd logs -f consensus"
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
