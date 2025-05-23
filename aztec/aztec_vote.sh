#!/bin/bash
set -e

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
  sudo apt install -y curl
fi

curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

echo -e "${BLUE}Настраиваем конфигурацию...${NC}"

# Останавливаем и удаляем старый контейнер
docker stop aztec-sequencer &> /dev/null || true
docker rm   aztec-sequencer &> /dev/null || true

EVM_FILE="$HOME/aztec-sequencer/.evm"
LINE="GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef"

# Диагностика пути
if [[ ! -f "$EVM_FILE" ]]; then
  echo -e "${RED}Файл не найден:${NC} $EVM_FILE"
  exit 1
fi

# Проверяем, нет ли уже нужной строки
if grep -Fxq "$LINE" "$EVM_FILE"; then
  echo -e "${GREEN}Строка уже есть в $EVM_FILE, пропускаем настройку конфигурации!${NC}"
else
  echo -e "${BLUE}Добавляем строку в $EVM_FILE…${NC}"
  printf "\n%s\n" "$LINE" >> "$EVM_FILE"
  echo -e "${GREEN}Настройка успешно завершена!${NC}"
fi

# Запускаем новый контейнер
docker run -d \
  --name aztec-sequencer \
  --network host \
  --env-file "$EVM_FILE" \
  -e DATA_DIRECTORY=/data \
  -e LOG_LEVEL=debug \
  -v "$HOME_DIR/my-node/node":/data \
  aztecprotocol/aztec:0.85.0-alpha-testnet.8 \
  sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
    start --network alpha-testnet --node --archiver --sequencer'

# Небольшая задержка, чтобы контейнер успел запуститься
sleep 2

# Показать последние 100 строк логов
docker logs --tail 100 -f aztec-sequencer
