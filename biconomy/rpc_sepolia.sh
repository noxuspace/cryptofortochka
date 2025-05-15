#!/bin/bash
set -e

# Цвета
YELLOW='\033[0;33m'
NC='\033[0m' # сброс цвета

# Определяем, какой синтаксис compose доступен
if command -v docker-compose &> /dev/null; then
  DC="docker-compose"
elif docker compose version &> /dev/null; then
  DC="docker compose"
else
  echo "Ошибка: не найдено ни команды 'docker-compose', ни команды 'docker compose'." >&2
  exit 1
fi

# Запрос новой RPC Sepolia
echo -e "${YELLOW}Вставьте адрес новой RPC Sepolia:${NC}"
read NEW_RPC

# Переход в папку проекта
cd $HOME/mee-node-deployment

# Останавливаем контейнеры
$DC down
sleep 5

# Заменяем строку "rpc": "..." на новую
sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$NEW_RPC\2#" chains-testnet/11155111.json

# Запускаем ноду
$DC up -d

cd ~
# Показываем логи
docker logs -f mee-node-deployment-node-1
