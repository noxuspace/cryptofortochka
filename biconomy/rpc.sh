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

# Запросы новых RPC (Enter — пропустить и оставить старое)
echo -e "${YELLOW}Вставьте адрес новой RPC Sepolia (Enter — оставить прежний):${NC}"
read SEP_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Base Sepolia (Enter — оставить прежний):${NC}"
read BASE_SEP_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Optimism Sepolia (Enter — оставить прежний):${NC}"
read OP_SEP_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Arbitrum Sepolia (Enter — оставить прежний):${NC}"
read ARB_SEP_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Base Mainnet (Enter — оставить прежний):${NC}"
read BASE_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Ethereum Mainnet (Enter — оставить прежний):${NC}"
read ETH_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Optimism Mainnet (Enter — оставить прежний):${NC}"
read OPT_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Arbitrum Mainnet (Enter — оставить прежний):${NC}"
read ARB_RPC

echo -e "${YELLOW}Вставьте адрес новой RPC Polygon Mainnet (Enter — оставить прежний):${NC}"
read POLY_RPC

# Переход в папку проекта
cd "$HOME/mee-node-deployment"

# Останавливаем контейнеры
$DC down
sleep 3

# ——— TESTNET ———

# Sepolia
if [[ -n "$SEP_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$SEP_RPC\2#" chains-testnet/11155111.json
fi

# Base Sepolia
if [[ -n "$BASE_SEP_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$BASE_SEP_RPC\2#" chains-testnet/84532.json
fi

# Optimism Sepolia
if [[ -n "$OP_SEP_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$OP_SEP_RPC\2#" chains-testnet/11155420.json
fi

# Arbitrum Sepolia
if [[ -n "$ARB_SEP_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$ARB_SEP_RPC\2#" chains-testnet/421614.json
fi

# ——— MAINNET ———

# Base
if [[ -n "$BASE_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$BASE_RPC\2#" chains-prod/8453.json
fi

# Ethereum
if [[ -n "$ETH_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$ETH_RPC\2#" chains-prod/1.json
fi

# Optimism
if [[ -n "$OPT_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$OPT_RPC\2#" chains-prod/10.json
fi

# Arbitrum
if [[ -n "$ARB_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$ARB_RPC\2#" chains-prod/42161.json
fi

# Polygon
if [[ -n "$POLY_RPC" ]]; then
  sed -i -E "s#(\"rpc\":\s*\")[^\"]*(\")#\1$POLY_RPC\2#" chains-prod/137.json
fi

# Спрашиваем, планирует ли пользователь пополнять основные сети нативными токенами
echo -en "${YELLOW}Вы планируете пополнять основные сети реальными нативными токенами? (y/n): ${NC}"
read -n1 FILL_MAIN; echo

if [[ "$FILL_MAIN" =~ ^[Yy]$ ]]; then
  # копируем обновлённые мейннет-файлы в папку chains-testnet
  cp chains-prod/8453.json   chains-testnet/
  cp chains-prod/1.json      chains-testnet/
  cp chains-prod/10.json     chains-testnet/
  cp chains-prod/42161.json  chains-testnet/
  cp chains-prod/137.json    chains-testnet/
else
  # удаляем файлы мейннетов из chains-testnet, кроме 1.json
  rm -f chains-testnet/8453.json
  rm -f chains-testnet/10.json
  rm -f chains-testnet/42161.json
  rm -f chains-testnet/137.json
fi

# Запускаем ноду
$DC up -d

# Возвращаемся в домашнюю и показываем логи Sepolia-ноды
cd ~
docker logs -f mee-node-deployment-node-1
