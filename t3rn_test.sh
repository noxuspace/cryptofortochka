#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # Нет цвета

# Копируем файл t3rn.env в root
echo -e "${GREEN}Копируем файл t3rn.env в /root...${NC}"
cp /root/t3rn/executor/executor/bin/t3rn.env /root/

# Останавливаем сервис t3rn
echo -e "${YELLOW}Останавливаем сервис t3rn...${NC}"
sudo systemctl stop t3rn.service

# Удаляем папку t3rn со всеми файлами
echo -e "${YELLOW}Удаляем папку t3rn...${NC}"
rm -rf /root/t3rn

# Создаем новую папку t3rn
echo -e "${GREEN}Создаем новую папку t3rn...${NC}"
mkdir /root/t3rn

# Скачиваем новый бинарник
echo -e "${GREEN}Скачиваем новый бинарник...${NC}"
wget https://github.com/t3rn/executor-release/releases/download/v0.21.9/executor-linux-v0.21.9.tar.gz

# Разархивируем в папку t3rn
echo -e "${GREEN}Распаковываем бинарник...${NC}"
tar -xzf executor-linux-v0.21.9.tar.gz -C /root/t3rn/

# Скачиваем и проверяем контрольную сумму
echo -e "${GREEN}Скачиваем и проверяем контрольную сумму...${NC}"
wget https://github.com/t3rn/executor-release/releases/download/v0.21.9/executor-linux-v0.21.9.tar.gz.sha256sum
sha256sum -c executor-linux-v0.21.9.tar.gz.sha256sum

# Спим 3 секунды
sleep 3

# Копируем файл t3rn.env обратно
echo -e "${YELLOW}Копируем t3rn.env обратно в bin директорию...${NC}"
cp /root/t3rn.env /root/t3rn/executor/executor/bin/

# Переходим в директорию
cd /root/t3rn/executor/executor/bin/

# Перезапускаем сервис и проверяем логи
echo -e "${GREEN}Перезапуск сервиса и проверка логов...${NC}"
sudo systemctl restart t3rn.service && sudo journalctl -u t3rn -f
