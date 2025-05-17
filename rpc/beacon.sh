#!/bin/bash
set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

ETHDOCKER="/home/geth_sepolia/eth-docker"
ENVFILE="$ETHDOCKER/.env"
JWTFILE="$ETHDOCKER/jwtsecret"
USER="geth_sepolia"

echo -e "${BLUE}-----------------------------------------------------------------------------${NC}"
echo -e "${BLUE}Добавление Beacon-ноды (Teku) к вашему стэку Sepolia RPC${NC}"
echo -e "${BLUE}-----------------------------------------------------------------------------${NC}"
sleep 3

# Останавливаем текущие сервисы
echo -e "${BLUE}Останавливаю все контейнеры RPC...${NC}"
export COMPOSE_PROJECT_NAME=sepolia
sudo -u $USER "$ETHDOCKER/ethd" down

# Генерация JWT-секрета, если нет
if [ ! -f "$JWTFILE" ]; then
    echo -e "${BLUE}Генерирую JWT-секрет...${NC}"
    sudo -u $USER openssl rand -hex 32 > "$JWTFILE"
else
    echo -e "${YELLOW}JWT-секрет уже есть, пропускаю${NC}"
fi
sudo chown $USER:docker "$JWTFILE"

# Настройка COMPOSE_FILE и JWT_SECRET_PATH в .env
echo -e "${BLUE}Конфигурирую .env для Beacon-ноды...${NC}"
sudo -u $USER sed -i \
    -e "s|^#*JWT_SECRET_PATH=.*|JWT_SECRET_PATH=$JWTFILE|" \
    "$ENVFILE"

# Запуск всех сервисов
echo -e "${BLUE}Запускаю все контейнеры...${NC}"
sudo -u $USER "$ETHDOCKER/ethd" up -d

# Определяем внешний endpoint Beacon RPC
HOST_IP=$(hostname -I | awk '{print $1}')
BEACON_BIND="${HOST_IP}:5052"

echo -e "${GREEN}Beacon-нода запущена!${NC}"
echo -e "${CYAN}Beacon RPC endpoint: ${HOST_IP}:${5052}${NC}"
echo "  $BEACON_BIND"
echo
echo -e "${CYAN}Чтобы посмотреть статус (должно вернуть OK):${NC}"
echo "sudo -u geth_sepolia docker exec eth-docker-consensus-1 curl -s http://localhost:5052/eth/v1/node/health"

echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
# Команда для проверки логов Beacon-ноды
echo -e "${YELLOW}Команда для проверки логов Beacon-ноды:${NC}"
echo "sudo -u geth_sepolia docker-compose -p sepolia -f $ETHDOCKER/teku-cl-only.yml logs -f teku"
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"

# Заключительное сообщение
echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
