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
        sudo apt update && sudo apt-get upgrade -y
        sudo apt install git make jq build-essential gcc unzip wget lz4 aria2 -y

        # Проверка архитектуры системы
        #ARCH=$(uname -m)
        #if [[ "$ARCH" == "aarch64" ]]; then
            #curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip
        #elif [[ "$ARCH" == "x86_64" ]]; then
            #curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip
        #else
            #echo -e "${RED}Не поддерживаемая архитектура системы: $ARCH${NC}"
            #exit 1
        #fi

        # Распаковываем ZIP-файл и переходим в папку
        #unzip dkn-compute-node.zip
        #cd dkn-compute-node

        # Запускаем приложение для ввода данных
        #./dkn-compute-launcher
        curl -fsSL https://dria.co/launcher | bash
        sleep 3
        mkdir -p "$HOME/.dria/dkn-compute-launcher" && wget -O "$HOME/.dria/dkn-compute-launcher/.env" https://raw.githubusercontent.com/firstbatchxyz/dkn-compute-launcher/master/.env.example
        dkn-compute-launcher start
        ;;
    2)
        echo -e "${GREEN}У вас актуальная версия ноды Dria.${NC}"
        ;;
    3)
        # Проверка логов
        screen -r dria
        ;;
    4)
        echo -e "${BLUE}Удаление ноды Dria...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop dria
        sudo systemctl disable dria
        sudo rm /etc/systemd/system/dria.service
        sudo systemctl daemon-reload
        sleep 2

        # Удаление папки ноды
        rm -rf $HOME/.dria
        rm -rf ~/dkn-compute-node

        echo -e "${GREEN}Нода Dria успешно удалена!${NC}"

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
