#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# 1. Обновление системы и установка proxychains
echo -e "${BLUE}Обновление системы и установка proxychains...${NC}"
sudo apt update -y
sudo apt install -y proxychains

# 2. Резервная копия конфигурационного файла /etc/proxychains.conf
echo -e "${BLUE}Создаём резервную копию /etc/proxychains.conf...${NC}"
sudo cp /etc/proxychains.conf /etc/proxychains.conf.bak

# 3. Комментируем строку с socks4
sudo sed -i '/^socks4 / s/^/# /' /etc/proxychains.conf

# 4. Ввод прокси от пользователя
echo -e "${BLUE}Вводите прокси для настройки socks5-прокси.${NC}"
echo -e "${RED}Формат ввода: IP_адрес Порт Логин Пароль${NC}"
echo -e "${YELLOW}Для завершения введите пустую строку. Максимум можно ввести 50 прокси.${NC}"

PROXY_COUNT=0
while [ $PROXY_COUNT -lt 50 ]; do
    read -p "$(echo -e "${YELLOW}Введите прокси #$((PROXY_COUNT+1)):${NC} ")" proxy_line
    # Если пользователь ввёл пустую строку, выходим из цикла
    if [ -z "$proxy_line" ]; then
        break
    fi
    # Добавляем строку в /etc/proxychains.conf, предваряя её "socks5"
    echo "socks5 ${proxy_line}" | sudo tee -a /etc/proxychains.conf >/dev/null
    PROXY_COUNT=$((PROXY_COUNT+1))
done

# 5. Вывод итоговых сообщений
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
echo -e "${GREEN}✓ Proxychains установлен.${NC}"
echo -e "${GREEN}✓ Файл /etc/proxychains.conf обновлён:${NC}"
echo -e "${CYAN}Добавлено $PROXY_COUNT прокси${NC}"
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
