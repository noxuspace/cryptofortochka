#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

docker stop aztec-sequencer
docker rm aztec-sequencer

set -e

EVM_FILE="$HOME/aztec-sequencer/.evm"
LINE="GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef"

# Проверяем, существует ли файл
if [[ ! -f "$EVM_FILE" ]]; then
  echo -e "${RED}"Файл $EVM_FILE не найден!"${NC}"
  exit 1
fi

# Проверяем, нет ли уже нужной строки
if grep -Fxq "$LINE" "$EVM_FILE"; then
  echo -e "${GREEN}"Строка уже присутствует в $EVM_FILE, настройки менять не нужно!"${NC}"
else
  echo "$LINE" >> "$EVM_FILE"
  echo -e "${GREEN}"Конфигурация для голосования успешно настроена!"${NC}"
fi

docker run -d \
  --name aztec-sequencer \
  --network host \
  --env-file "$HOME/aztec-sequencer/.evm" \
  -e DATA_DIRECTORY=/data \
  -e LOG_LEVEL=debug \
  -v "$HOME/my-node/node":/data \
  aztecprotocol/aztec:0.85.0-alpha-testnet.8 \
  sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
    start --network alpha-testnet --node --archiver --sequencer'

sleep 2
docker logs --tail 100 -f aztec-sequencer


       
