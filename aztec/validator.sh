#!/usr/bin/env bash
set -euo pipefail

# Цвета
RED=$'\033[0;31m'
NC=$'\033[0m'

# Функция форматирования (секунды → "X ч Y м")
format_delta() {
  local delta=$1
  printf "%d ч %d м" $((delta/3600)) $(((delta%3600)/60))
}

# Запускаем регистрацию без привязки к TTY
output=$(docker exec -i aztec-sequencer \
  sh -c 'node /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator \
    --l1-rpc-urls "'"${ETHEREUM_HOSTS-}"'" \
    --private-key "'"${VALIDATOR_PRIVATE_KEY-}"'" \
    --attester "'"${WALLET-}"'" \
    --proposer-eoa "'"${WALLET-}"'" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111' 2>&1 || true)

# Ищем число в скобках после ValidatorQuotaFilledUntil
if ts=$(printf '%s\n' "$output" | grep -oP 'ValidatorQuotaFilledUntil\(\K[0-9]+(?=\))'); then
  now=$(date +%s)
  delta=$((ts - now))
  if (( delta > 0 )); then
    human=$(format_delta "$delta")
    echo -e "${RED}На данный момент превышена квота регистрации валидаторов, вы сможете попробовать зарегистрировать валидатора через ${human}.${NC}"
    exit 0
  fi
fi

# Если сюда дошли — либо нет квоты, либо время уже истекло; выводим весь оригинал
printf '%s\n' "$output"
