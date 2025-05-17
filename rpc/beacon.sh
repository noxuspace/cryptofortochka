#!/bin/bash
set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # сброс цвета

# Проверка наличия curl
if ! command -v curl &>/dev/null; then
    echo -e "${BLUE}Устанавливаю curl...${NC}"
    sudo apt update && sudo apt install -y curl
else
    echo -e "${YELLOW}curl уже установлен, пропускаю${NC}"
fi

# Логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

echo -e "${PURPLE}-----------------------------------------------------------------------------${NC}"
echo -e "${BLUE}Добавление Beacon-ноды (Teku) к вашему стэку Sepolia RPC${NC}"
echo -e "${PURPLE}-----------------------------------------------------------------------------${NC}"

sleep 4

ETHDOCKER="/home/geth_sepolia/eth-docker"
ENVFILE="$ETHDOCKER/.env"
JWTFILE="$ETHDOCKER/jwtsecret"

# Останавливаем текущие сервисы Sepolia RPC
echo -e "${BLUE}Останавливаю текущие контейнеры RPC...${NC}"
export COMPOSE_PROJECT_NAME=sepolia
sudo -u geth_sepolia "$ETHDOCKER/ethd" down

# Генерация JWT-секрета, если нет
if [ ! -f "$JWTFILE" ]; then
    echo -e "${BLUE}Генерирую JWT-секрет...${NC}"
    sudo -u geth_sepolia openssl rand -hex 32 > "$JWTFILE"
else
    echo -e "${YELLOW}JWT-секрет уже есть, пропускаю генерацию${NC}"
fi
sudo chown geth_sepolia:docker "$JWTFILE"

# Настройка COMPOSE_FILE и JWT_SECRET_PATH в .env
echo -e "${BLUE}Конфигурирую .env для Beacon-ноды...${NC}"
sudo -u geth_sepolochia sed -i \
    -e "s|^COMPOSE_FILE=.*|COMPOSE_FILE=teku-cl-only.yml:geth.yml:grafana.yml:grafana-shared.yml:el-shared.yml|" \
    -e "s|^#*JWT_SECRET_PATH=.*|JWT_SECRET_PATH=$JWTFILE|" \
    "$ENVFILE"

# Запуск всех сервисов
echo -e "${BLUE}Запускаю все контейнеры...${NC}"
sudo -u geth_sepolia "$ETHDOCKER/ethd" up -d

# Получаем адрес и порт Beacon-ноды
BEACON_BIND=$(sudo -u geth_sepolia docker-compose -p sepolia -f "$ETHDOCKER/teku-cl-only.yml" port teku 5052)
if [ -z "$BEACON_BIND" ]; then
    # fallback: первый IP хоста + порт 5052
    HOST_IP=$(hostname -I | awk '{print $1}')
    BEACON_BIND="$HOST_IP:5052"
fi

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
