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
    echo -e "${CYAN}1) Запуск RPC${NC}"
    echo -e "${CYAN}2) Удаление RPC${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            sudo apt update -y
            sudo apt install mc wget curl git htop netcat-openbsd net-tools unzip jq build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen -y

            sudo apt update
            sudo apt install ufw -y
            sudo ufw allow 22:65535/tcp
            sudo ufw allow 22:65535/udp
            sudo ufw deny out from any to 10.0.0.0/8
            #sudo ufw deny out from any to 172.16.0.0/12
            sudo ufw deny out from any to 192.168.0.0/16
            sudo ufw deny out from any to 100.64.0.0/10
            sudo ufw deny out from any to 198.18.0.0/15
            sudo ufw deny out from any to 169.254.0.0/16
            sudo ufw --force enable

            
            ;;

        2)
            
            ;;


        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 2!${NC}"
            ;;
    esac
