#!/bin/bash
set -e

# Определяем, какой синтаксис compose доступен
if command -v docker-compose &> /dev/null; then
  DC="docker-compose"
elif docker compose version &> /dev/null; then
  DC="docker compose"
else
  echo "Ошибка: не найдено ни команды 'docker-compose', ни команды 'docker compose'." >&2
  exit 1
fi

# Переходим в папку проекта
cd mee-node-deployment

# Останавливаем
$DC down
sleep 5

# Обновляем образ в compose-файле
sed -i -E 's#^(\s*image:\s*bcnmy/mee-node:).*#\11.1.14#' docker-compose.yml

# Запускаем
$DC up -d

# Показываем логи
docker logs -f mee-node-deployment-node-1
