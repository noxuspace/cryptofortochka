#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# 1. Установка proxychains
echo -e "${BLUE}Обновление системы и установка proxychains...${NC}"
sudo apt update -y
sudo apt install -y proxychains

# 2. Запрос данных для прокси (с использованием цветных сообщений)
echo -e "${BLUE}Введите данные для настройки прокси:${NC}"

# Протокол
echo -e "${YELLOW}Протокол (например, socks5, http, https):${NC}"
read PROXY_PROTOCOL

# IP-адрес
echo -e "${YELLOW}IP-адрес прокси:${NC}"
read PROXY_IP

# Порт
echo -e "${YELLOW}Порт прокси:${NC}"
read PROXY_PORT

# Логин
echo -e "${YELLOW}Логин (если есть, иначе Enter):${NC}"
read PROXY_USER

# Пароль
echo -e "${YELLOW}Пароль (если есть, иначе Enter):${NC}"
read PROXY_PASS

# 3. Резервная копия /etc/proxychains.conf
sudo cp /etc/proxychains.conf /etc/proxychains.conf.bak

# 4. Комментируем строку с socks4
sudo sed -i '/^socks4 / s/^/# /' /etc/proxychains.conf

# 5. Добавляем новую строку с данными пользователя
#    (Будет вида: socks5 1.2.3.4 1080 user pass)
echo "${PROXY_PROTOCOL} ${PROXY_IP} ${PROXY_PORT} ${PROXY_USER} ${PROXY_PASS}" \
  | sudo tee -a /etc/proxychains.conf >/dev/null

# Вывод итоговых сообщений
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
echo -e "${GREEN}✓ Proxychains установлен.${NC}"
echo -e "${GREEN}✓ Файл /etc/proxychains.conf обновлён:${NC}"
echo -e "${CYAN}Добавлен ваш прокси: '${PROXY_PROTOCOL} ${PROXY_IP} ${PROXY_PORT} ${PROXY_USER} ${PROXY_PASS}'${NC}"
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
