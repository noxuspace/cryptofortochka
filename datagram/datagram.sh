#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Проверка логов${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Dria...${NC}"

        # Обновление и установка зависимостей
        sudo apt update
        sudo apt install screen git make jq build-essential gcc unzip wget lz4 aria2 -y

        cd ~
        mkdir datagram
        cd datagram
        wget -O datagram-cli https://github.com/Datagram-Group/datagram-cli-release/releases/latest/download/datagram-cli-x86_64-linux
        chmod +x datagram-cli
        cd ~
        ;;
    2)
        echo -e "${GREEN}У вас актуальная версия ноды Datagram!${NC}"
        ;;
    3)
        # Проверка логов
        screen -r datagram
        ;;
    4)
        echo -e "${BLUE}Удаление ноды Datagram...${NC}"

        # Находим все сессии screen, содержащие "datagram"
        SESSION_IDS=$(screen -ls | grep "datagram" | awk '{print $1}' | cut -d '.' -f 1)
    
        # Если сессии найдены, удаляем их
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Сессии screen для ноды Datagram не найдены, продолжаем удаление${NC}"
        fi
        
        
        # Удаление папки ноды
        rm -rf $HOME/datagram

        echo -e "${GREEN}Нода Datagram успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
        ;;
esac
