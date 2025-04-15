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
echo -e "${CYAN}1) Установка зависимостей${NC}"
echo -e "${CYAN}2) Деплой Trap${NC}"
echo -e "${CYAN}3) Установка ноды${NC}"
echo -e "${CYAN}4) Запуск ноды${NC}"
echo -e "${CYAN}5) Обновление ноды${NC}"
echo -e "${CYAN}6) Просмотр логов ноды${NC}"
echo -e "${CYAN}7) Перезапуск ноды${NC}"
echo -e "${CYAN}8) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка зависимостей...${NC}"
        sudo apt-get update && sudo apt-get upgrade -y
        sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

        curl -L https://app.drosera.io/install | bash
        curl -L https://foundry.paradigm.xyz | bash
        curl -fsSL https://bun.sh/install | bash
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2      
        ;;
    2)
        echo -e "${BLUE}Деплой Trap...${NC}"
        droseraup
        foundryup

        mkdir my-drosera-trap
        cd my-drosera-trap

        # Запрос Email
        read -p "${YELLOW}Введите вашу Github почту:${NC}" GITHUB_EMAIL
        # Запрос Username
        read -p "${YELLOW}Введите ваш Github юзернейм:${NC}" GITHUB_USERNAME
        
        # Применяем настройки git
        git config --global user.email "$GITHUB_EMAIL"
        git config --global user.name "$GITHUB_USERNAME"

        forge init -t drosera-network/trap-foundry-template

        bun install
        forge build

        
      

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        ;;
    3)
        echo -e "${BLUE}Установка ноды...${NC}"



        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        ;;
    4)
        echo -e "${BLUE}Запуск ноды...${NC}"

        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "journalctl -u drosera.service -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        journalctl -u drosera.service -f
        ;;
    5)
        echo -e "${GREEN}У вас актуальная версия ноды Drosera!${NC}"
        ;;
    6)
        journalctl -u drosera.service -f
        ;;
    7)
        sudo systemctl restart drosera && journalctl -u drosera.service -f
        ;;
    8)
        echo -e "${BLUE}Удаление ноды Drosera...${NC}"

        # Остановка и удаление сервиса Hemi
        sudo systemctl stop drosera.service
        sudo systemctl disable drosera.service
        sudo rm /etc/systemd/system/drosera.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки с названием, содержащим "hemi"
        echo -e "${BLUE}Удаляем файлы ноды Drosera...${NC}"
        rm -rf my-drosera-trap
        
        echo -e "${GREEN}Нода Drosera успешно удалена!${NC}"
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
        ;;
esac


       
