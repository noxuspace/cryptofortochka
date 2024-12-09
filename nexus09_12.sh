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

# Проверка версии Ubuntu
REQUIRED_VERSION=22.04
UBUNTU_VERSION=$(lsb_release -rs)
if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Для этой ноды нужна минимальная версия Ubuntu 22.04${NC}"
    exit 1
fi

# Меню
while true; do
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo -e "${CYAN}1) Установка ноды${NC}"
    echo -e "${CYAN}2) Обновление ноды${NC}"
    echo -e "${CYAN}3) Переход в сессию screen${NC}"
    echo -e "${CYAN}4) Удаление ноды${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Устанавливаем ноду Nexus...${NC}"

            # Обновление и установка необходимых компонентов
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen

            # Проверка наличия сессий screen для Nexus
            SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)

            if [ -n "$SESSION_IDS" ]; then
                echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
                for SESSION_ID in $SESSION_IDS; do
                    screen -S "$SESSION_ID" -X quit
                done
            else
                echo -e "${BLUE}Сессии screen для ноды Nexus не найдены, создаем сессию...${NC}"
            fi

            # Создание новой сессии screen
            screen -dmS nexus

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Для перехода в сессию используйте:${NC}"
            echo -e "screen -r nexus"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            ;;

        2)
            echo -e "${BLUE}Обновление ноды Nexus...${NC}"
            echo -e "${GREEN}Установлена актуальная версия ноды!${NC}"
            ;;

        3)
            echo -e "${BLUE}Переход в сессию Nexus...${NC}"
            screen -r nexus
            ;;

        4)
            echo -e "${BLUE}Удаление ноды Nexus...${NC}"

            # Проверка наличия сессий screen для Nexus
            SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)

            if [ -n "$SESSION_IDS" ]; then
                echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
                for SESSION_ID in $SESSION_IDS; do
                    screen -S "$SESSION_ID" -X quit
                done
            else
                echo -e "${BLUE}Сессии screen для ноды Nexus не найдены, удаление завершено.${NC}"
            fi

            rm -rf .nexus/
            sleep 1

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac

done
