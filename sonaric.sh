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

# Проверка наличия bc и установка, если не установлен
echo -e "${BLUE}Проверяем версию вашей OS...${NC}"
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Для этой ноды нужна минимальная версия Ubuntu 22.04${NC}"
    exit 1
fi

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Проверка работы ноды${NC}"
echo -e "${CYAN}4) Проверка поинтов${NC}"
echo -e "${CYAN}5) Бекап ноды${NC}"
echo -e "${CYAN}6) Регистрация ноды${NC}"
echo -e "${CYAN}7) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Sonaric...${NC}"

        # Обновление и установка зависимостей
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install git -y
        sudo apt install jq -y
        sudo apt install build-essential -y
        sudo apt install gcc -y
        sudo apt install unzip -y
        sudo apt install wget -y
        sudo apt install lz4 -y

        # Установка Node.js
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install nodejs -y

        # Установка Sonaric
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки состояния ноды:${NC}"
        echo "sonaric node-info"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sonaric node-info
        ;;
    2)
        echo -e "${BLUE}Обновляем ноду Sonaric...${NC}"
        
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки состояния ноды:${NC}"
        echo "sonaric node-info"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sonaric node-info
        ;;
    3)
        echo -e "${BLUE}Проверка работы ноды...${NC}"
        sonaric node-info
        ;;
    4)
        echo -e "${BLUE}Проверка поинтов...${NC}"
        sonaric points
        ;;
    5)
        echo -e "${YELLOW}Введите имя вашей ноды, которое вы указывали на этапе установки:${NC}"
        read NODE_NAME

        sonaric identity-export -o "$NODE_NAME.identity"

        echo -e "${GREEN}Бекап успешно создан: ${NODE_NAME}.identity${NC}"
        cd && cat ${NODE_NAME}.identity
        ;;
    6)
        # Вывод запроса и ожидание ввода
        echo -e "${YELLOW}Вставьте код, который вы получили в Discord:${NC}"
        read DISCORD_CODE

        # Проверка, что код не пустой
        if [ -z "$DISCORD_CODE" ]; then
            echo -e "${YELLOW}Код не был введен. Попробуйте снова.${NC}"
            exit 1
        fi
        
        # Выполнение команды с введенным кодом
        sonaric node-register "$DISCORD_CODE"
        ;;
    7)
        echo -e "${BLUE}Удаление ноды Sonaric...${NC}"

        sudo systemctl stop sonaricd
        sudo rm -rf $HOME/.sonaric

        echo -e "${GREEN}Нода Sonaric успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 6.${NC}"
        ;;
esac
