#!/usr/bin/env bash
set -euo pipefail

# Цвета
RED=$'\033[0;31m'
NC=$'\033[0m'  # сброс цвета

# Функция: переводит разницу в секундах в "X ч Y м"
format_delta() {
  local delta=$1
  local hours=$((delta/3600))
  local minutes=$(((delta%3600)/60))
  printf "%d ч %d м" "$hours" "$minutes"
}

# Основная команда регистрации
output=$(docker exec aztec-sequencer \
  sh -c 'node /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator \
    --l1-rpc-urls "'"${ETHEREUM_HOSTS-}"'" \
    --private-key "'"${VALIDATOR_PRIVATE_KEY-}"'" \
    --attester "'"${WALLET-}"'" \
    --proposer-eoa "'"${WALLET-}"'" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111' 2>&1 || true)

# Ищем в выводе строку с ValidatorQuotaFilledUntil
if echo "$output" | grep -q 'ValidatorQuotaFilledUntil'; then
  # извлекаем timestamp (цифры внутри скобок)
  ts=$(echo "$output" \
       | grep 'ValidatorQuotaFilledUntil' \
       | sed -E 's/.*\(([0-9]+)\).*/\1/')
  # текущее время в секундах
  now=$(date +%s)
  # сколько осталось до разблокировки
  delta=$((ts - now))
  if (( delta > 0 )); then
    human=$(format_delta "$delta")
    echo -e "${RED}На данный момент превышена квота регистрации валидаторов, вы сможете попробовать зарегистрировать валидатора через ${human}.${NC}"
    exit 0
  fi
fi

# Если не было ошибки квоты, можно просто вывести оригинальный вывод:
echo "$output"
