#!/bin/bash

# Цвета (с использованием $'…' для интерпретации ANSI-последовательностей)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'  # Сброс цвета

# 1. Обновление системы и установка proxychains
echo -e "${BLUE}Обновление системы и установка proxychains...${NC}"
sudo apt update -y
sudo apt install -y proxychains

# 2. Создаём резервную копию /etc/proxychains.conf
echo -e "${BLUE}Создаём резервную копию /etc/proxychains.conf...${NC}"
sudo cp /etc/proxychains.conf /etc/proxychains.conf.bak

# 3. Комментируем строку с socks4
sudo sed -i '/^socks4 / s/^/# /' /etc/proxychains.conf

# 4. Ввод прокси от пользователя (пачкой)
echo -e "${BLUE}Вставьте список прокси для настройки socks5-прокси.${NC}"
echo -e "${RED}Формат ввода: IP_адрес Порт Логин Пароль (каждая прокси с новой строки)${NC}"
echo -e "${YELLOW}После вставки нажмите Ctrl-D (максимум можно ввести 50 прокси).${NC}"
# Читаем весь ввод до EOF (Ctrl-D)
proxy_input=$(cat)

# Преобразуем ввод в массив строк
readarray -t proxy_array <<< "$proxy_input"

PROXY_COUNT=0
for proxy_line in "${proxy_array[@]}"; do
    # Ограничиваем до 50 прокси
    if [ $PROXY_COUNT -ge 50 ]; then
        break
    fi
    # Если строка не пуста, добавляем её в конфиг с префиксом "socks5"
    if [ -n "$proxy_line" ]; then
        echo "socks5 ${proxy_line}" | sudo tee -a /etc/proxychains.conf >/dev/null
        PROXY_COUNT=$((PROXY_COUNT+1))
    fi
done

# 5. Вывод итоговых сообщений
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
echo -e "${GREEN}✓ Proxychains установлен.${NC}"
echo -e "${GREEN}✓ Файл /etc/proxychains.conf обновлён:${NC}"
echo -e "${CYAN}Добавлено $PROXY_COUNT прокси (каждая строка начинается с 'socks5')${NC}"
echo -e "${PURPLE}-----------------------------------------------------------${NC}"
