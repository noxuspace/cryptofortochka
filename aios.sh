#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Отображение логотипа
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды Hyperspace${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Проверка логов${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${CYAN}Начинаем установку ноды Hyperspace...${NC}"

        # Обновление системы и установка зависимостей
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y mc wget curl git htop netcat net-tools unzip jq build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen
        sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
        sleep 1

        response=$(curl -s "https://api.github.com/repos/hyperspaceai/aios-cli/releases/latest")

        # Check if the response contains a rate limit error
        if echo "$response" | grep -q "API rate limit exceeded"; then
            echo "Введите Гитхаб токен"
            read GITHUB_TOKEN
        
            curl -o install_script.sh https://download.hyper.space/api/install
            chmod +x install_script.sh
            sed -i "s|curl|curl -H \"Authorization: token $GITHUB_TOKEN\"|" install_script.sh
            bash install_script.sh --verbose
            rm install_script.sh
        else
            curl https://download.hyper.space/api/install --verbose | bash
        fi
        
        source /root/.bashrc

        # Проверка наличия директории
        if [[ ! -d "$HOME/.aios" ]]; then
            echo "Установка ноды прервана из-за недоступности серверов Hyperspace. Перезапустите скрипт установки позже."
            exit 1
        fi

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)
        
        # Создание и настройка сервиса
        sudo tee /etc/systemd/system/aios.service > /dev/null << EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        # Запуск сервиса
        sudo systemctl daemon-reload
        sudo systemctl enable aios
        sudo systemctl start aios

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        sudo systemctl journalctl -n 100 -f -u aios -o cat       
        ;;

    2)
        echo -e "${GREEN}У вас актуальная версия ноды Hyperspace.${NC}"
        ;;

    3)
        echo -e "${CYAN}Просмотр логов...${NC}"
        sudo systemctl journalctl -n 100 -f -u aios -o cat
        ;;

    4)
        echo -e "${RED}Удаляем ноду Hyperspace...${NC}"
        sudo systemctl stop aios
        sudo systemctl disable aios
        sudo systemctl daemon-reload
        sleep 2
        sudo rm -rf /etc/systemd/system/aios.service
        sudo rm -rf $HOME_DIR/.aios
        sudo rm -rf $HOME_DIR/.cache/hyperspace
        sudo rm -rf $HOME_DIR/.config/hyperspace
        echo -e "${GREEN}Нода успешно удалена.${NC}"
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
