#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'

# Собираем весь вывод в переменную
output=$(docker exec -i aztec-sequencer \
  sh -c 'node /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator \
    --l1-rpc-urls "'"${ETHEREUM_HOSTS-}"'" \
    --private-key "'"${VALIDATOR_PRIVATE_KEY-}"'" \
    --attester "'"${WALLET-}"'" \
    --proposer-eoa "'"${WALLET-}"'" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111' 2>&1) || true

# Если в выводе есть упоминание quota — обрабатываем ошибку
if printf '%s\n' "$output" | grep -q 'ValidatorQuotaFilledUntil'; then
  # Извлекаем первое число в скобках
  ts=$(printf '%s\n' "$output" | grep -oP '\(\K[0-9]+(?=\))' | head -n1)
  now=$(date +%s)
  delta=$(( ts - now ))
  hours=$(( delta / 3600 ))
  mins=$(( (delta % 3600) / 60 ))
  printf "${RED}На данный момент превышена квота регистрации валидаторов,\n"
  printf "вы сможете попробовать зарегистрироваться через %d ч %d м.${NC}\n" \
         "$hours" "$mins"
else
  # Иначе выводим оригинальный лог
  printf '%s\n' "$output"
fi
