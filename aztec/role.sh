#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# 1) Получаем высоту последнего проверенного блока
TIP_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
  http://localhost:8080)

BLOCK_NUMBER=$(printf '%s' "$TIP_RESPONSE" | jq -r '.result.proven.number')

# Проверяем, что это целое неотрицательное число
if ! [[ "$BLOCK_NUMBER" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}Ошибка: ожидалось целое число, получили: $BLOCK_NUMBER${NC}" >&2
  exit 1
fi

echo -e "${GREEN}Успешно получили высоту блока: $BLOCK_NUMBER${NC}"
sleep 2

# 2) Запрашиваем proof — передаём числа без кавычек!
ARCHIVE_PROOF=$(curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[$BLOCK_NUMBER,$BLOCK_NUMBER],\"id\":67}" \
  http://localhost:8080 | jq -r '.result')

# Проверяем, что proof не пустой
if [[ -z "$ARCHIVE_PROOF" || "$ARCHIVE_PROOF" == "null" ]]; then
  echo -e "${RED}Ошибка: не удалось получить proof для блока $BLOCK_NUMBER${NC}" >&2
  exit 1
fi

echo -e "${GREEN}Proof для блока $BLOCK_NUMBER:${NC}"
echo "$ARCHIVE_PROOF"
