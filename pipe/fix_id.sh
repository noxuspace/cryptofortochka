#!/usr/bin/env bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # Сброс цвета

# Остановить и удалить старый контейнер
docker rm -f popnode || true

# Запрос нового уникального имени ноды
echo -e "${YELLOW}Придумайте новое уникальное имя ноды:${NC}"
read NEW_POP_NAME

# Обновление поля pop_name в конфиге
CONFIG_FILE="/opt/popcache/config.json"
if [ -f "$CONFIG_FILE" ]; then
  sudo sed -i "s/\"pop_name\": *\"[^"]*\"/\"pop_name\": \"${NEW_POP_NAME}\"/" "$CONFIG_FILE"
else
  echo -e "${RED}Файл $CONFIG_FILE не найден!${NC}" >&2
  exit 1
fi

# Пересборка и перезапуск контейнера
cd /opt/popcache
docker build -t popnode .

docker run -d \
  --name popnode \
  -p 80:80 \
  -p 443:443 \
  --restart unless-stopped \
  popnode

# Дать контейнеру немного времени
sleep 1
cd ~

# Просмотр последних логов в реальном времени
docker logs -f popnode
