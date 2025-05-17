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

ETHDOCKER="/home/geth_sepolia/eth-docker"
ENVFILE="$ETHDOCKER/.env"
JWTFILE="$ETHDOCKER/jwtsecret"

echo -e "${BLUE}-----------------------------------------------------------------------------${NC}"
echo -e "${BLUE}Откат к чистому стэку Sepolia RPC (geth + Grafana и метрики)${NC}"
echo -e "${BLUE}-----------------------------------------------------------------------------${NC}"

# 1) Останавливаем все текущие контейнеры (включая teku)
echo -e "${BLUE}Останавливаю все сервисы...${NC}"
export COMPOSE_PROJECT_NAME=sepolia
sudo -u geth_sepolia "$ETHDOCKER/ethd" down

# 2) Удаляем JWT-файл, если он существует
if [ -f "$JWTFILE" ]; then
    echo -e "${YELLOW}Удаляю JWT-секрет...${NC}"
    sudo rm -f "$JWTFILE"
else
    echo -e "${YELLOW}JWT-секрет не найден, пропускаю${NC}"
fi

# 3) Восстанавливаем COMPOSE_FILE в .env
echo -e "${BLUE}Восстанавливаю COMPOSE_FILE в .env...${NC}"
sudo -u geth_sepolia sed -i \
    -e "s|^COMPOSE_FILE=.*|COMPOSE_FILE=teku-cl-only.yml:geth.yml:grafana.yml:grafana-shared.yml:el-shared.yml|" \
    -e "/^JWT_SECRET_PATH=/d" \
    "$ENVFILE"

# 4) Запускаем только Execution Layer + Grafana & метрики
echo -e "${BLUE}Запускаю чистый стэк Sepolia RPC...${NC}"
sudo -u geth_sepolia "$ETHDOCKER/ethd" up -d

echo -e "${GREEN}Откат завершён!${NC}"
echo
echo -e "${CYAN}Логи Execution (Geth):${NC}"
echo "  sudo -u geth_sepolia docker-compose -p sepolia -f $ETHDOCKER/geth.yml logs -f geth"
echo
echo -e "${CYAN}Логи Grafana и метрик (Promtail/Loki/Prometheus):${NC}"
echo "  sudo -u geth_sepolia docker-compose -p sepolia -f $ETHDOCKER/grafana.yml logs -f grafana"
echo
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
