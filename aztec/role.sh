#!/usr/bin/env bash
set -euo pipefail

# Запрашиваем высоту последнего проверенного блока
TIP_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
  http://localhost:8080)

# Извлекаем число из поля .result.proven.number
BLOCK_NUMBER=$(printf '%s' "$TIP_RESPONSE" | jq -r '.result.proven.number')

# Проверяем, что получили целое неотрицательное число
if ! [[ "$BLOCK_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Ошибка: ожидается целое число, получили: $BLOCK_NUMBER" >&2
  exit 1
fi

echo "Успешно получили высоту блока: $BLOCK_NUMBER"

# Делаем паузу перед запросом proof
sleep 2

# Запрашиваем proof по этому же номеру блока
ARCHIVE_PROOF=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"$BLOCK_NUMBER\",\"$BLOCK_NUMBER\"],\"id\":67}" \
  http://localhost:8080 | jq -r '.result')

# Проверяем, что proof не пустой
if [ -z "$ARCHIVE_PROOF" ] || [ "$ARCHIVE_PROOF" = "null" ]; then
  echo "Ошибка: не удалось получить proof для блока $BLOCK_NUMBER" >&2
  exit 1
fi

echo "Proof для блока $BLOCK_NUMBER:"
echo "$ARCHIVE_PROOF"
