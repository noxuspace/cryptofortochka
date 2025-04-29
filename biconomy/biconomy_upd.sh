#!/bin/bash
set -e

# Перейти в папку с docker-compose
cd mee-node-deployment

# Остановить контейнеры
docker compose down
sleep 5

# Обновить версию образа в docker-compose.yml
# Любую строку вида "image: bcnmy/mee-node:<текущая-версия>" заменяем на "...:1.1.14"
sed -i -E 's#^(\s*image:\s*bcnmy/mee-node:).*#\11.1.14#' docker-compose.yml

# Запустить заново в фоне
docker compose up -d

# Подключиться к логам контейнера
docker logs -f mee-node-deployment-node-1
