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
LINE="GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0xDCd9DdeAbEF70108cE02576df1eB333c4244C666"

# Диагностика пути
if [[ ! -f "$EVM_FILE" ]]; then
  echo -e "${RED}Файл не найден:${NC} $EVM_FILE"
  exit 1
fi

# --- БЛОК ПРОВЕРКИ/ОЧИСТКИ/ДОБАВЛЕНИЯ СТРОКИ ---
if grep -Fxq "$LINE" "$EVM_FILE"; then
  echo -e "${GREEN}Точное совпадение уже есть в $EVM_FILE — изменения не требуются.${NC}"
else
  echo -e "${YELLOW}Точного совпадения нет. Удаляю все строки, начинающиеся с 'GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS'...${NC}"
  # Удаляем любые строки, начинающиеся на префикс (значение справа может быть любым)
  sed -i '/^GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS.*/d' "$EVM_FILE"

  echo -e "${BLUE}Добавляю требуемую строку в $EVM_FILE...${NC}"
  printf "\n%s\n" "$LINE" >> "$EVM_FILE"
  echo -e "${GREEN}Настройка успешно завершена!${NC}"
fi
# --- КОНЕЦ БЛОКА ---

# Запускаем новый контейнер
docker run -d \
  --name aztec-sequencer \
  --network host \
  --memory=10g \
  --memory-swap=12g \
  --env-file "$HOME/aztec-sequencer/.evm" \
  -e DATA_DIRECTORY=/data \
  -e LOG_LEVEL=debug \
  -e NODE_OPTIONS="--max-old-space-size=8192 --max-semi-space-size=1024" \
  -v "$HOME/my-node/node":/data \
  --entrypoint /bin/sh \
  aztecprotocol/aztec:2.0.4 \
  -c "node --max-old-space-size=8192 --max-semi-space-size=1024 --optimize-for-size --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
    start --network testnet --node --archiver --sequencer \
    --sequencer.validatorPrivateKeys \"\$VALIDATOR_PRIVATE_KEY\" \
    --l1-rpc-urls \"\$ETHEREUM_HOSTS\" \
    --l1-consensus-host-urls \"\$L1_CONSENSUS_HOST_URLS\" \
    --sequencer.coinbase \"\$WALLET\" \
    --p2p.p2pIp \"\$P2P_IP\""

# Небольшая задержка, чтобы контейнер успел запуститься
sleep 2

# Показать последние 100 строк логов
docker logs --tail 100 -f aztec-sequencer
