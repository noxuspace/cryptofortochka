#!/bin/bash

# Цвета текста
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
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
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Запуск ноды${NC}"
echo -e "${CYAN}3) Перезапуск ноды${NC}"
echo -e "${CYAN}4) Обновление ноды${NC}"
echo -e "${CYAN}5) Ввывод ключей ноды${NC}"
echo -e "${CYAN}6) Проверка логов${NC}"
echo -e "${CYAN}7) Просмотр поинтов${NC}"
echo -e "${CYAN}8) Удаление ноды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${BLUE}Начинаем установку ноды Hyperspace...${NC}"

        # Обновление системы и установка зависимостей
        sudo apt update && sudo apt upgrade -y
        sudo apt install mc wget git htop netcat net-tools unzip jq git build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen -y
        
        curl https://download.hyper.space/api/install --verbose | bash
        sleep 5
        source $HOME/.bashrc
        ;;

    2)
        echo -e "${BLUE}Подготовка к запуску ноды Hyperspace...${NC}"

        SERVICE_FILE="/etc/systemd/system/aios.service"

        if [ -f "$SERVICE_FILE" ]; then
            echo "Файл сервиса найден. Останавливаем и удаляем его..."
            systemctl stop aios
            systemctl disable aios
            sleep 2
            rm -rf "$SERVICE_FILE"
            sudo systemctl daemon-reload
            sleep 2
        else
            echo "Файл сервиса не найден, продолжаем..."
        fi
        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)
        
        sudo tee /etc/systemd/system/aios.service > /dev/null << EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}Введите приватный ключ:${NC}"
read PRIVATE_KEY

sudo tee $HOME/.aios/private_key.pem > /dev/null << EOF
$PRIVATE_KEY
EOF

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable aios
        sudo systemctl start aios

        $HOME/.aios/aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
        $HOME/.aios/aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

        aios-cli hive login
        sleep 2
        aios-cli hive select-tier 5
        aios-cli hive select-tier 3

        systemctl stop aios
        systemctl disable aios
        sleep 2
        rm -rf /etc/systemd/system/aios.service
        sudo systemctl daemon-reload
        sleep 2

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo tee /etc/systemd/system/aios.service > /dev/null << EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable aios
        sudo systemctl start aios
        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "journalctl -n 100 -f -u aios -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        journalctl -n 100 -f -u aios -o cat
        ;;

    3)
        echo -e "${BLUE}Перезапускаем ноду Hyperspace...${NC}"
        systemctl stop aios
        systemctl disable aios
        sleep 2
        rm -rf /etc/systemd/system/aios.service
        sudo systemctl daemon-reload
        sleep 2

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo tee /etc/systemd/system/aios.service > /dev/null << EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable aios
        sudo systemctl start aios
        journalctl -n 100 -f -u aios -o cat
        ;;
        
    4)
        echo -e "${GREEN}У вас актуальная версия ноды Hyperspace.${NC}"
        ;;

    5)
        echo -e "${BLUE}Ввывод ключей ноды...${NC}"
        $HOME/.aios/aios-cli hive whoami
        ;;

    6)
        echo -e "${BLUE}Просмотр логов...${NC}"
        journalctl -n 100 -f -u aios -o cat
        ;;

    7)
        echo -e "${BLUE}Просмотр поинтов...${NC}"
        journalctl -n 100 -f -u aios -o cat
        ;;    

    8)
        echo -e "${RED}Удаляем ноду Hyperspace...${NC}"
        systemctl stop aios
        systemctl disable aios
        sleep 2
        rm -rf /etc/systemd/system/aios.service
        rm -rf $HOME/.aios
        rm -rf $HOME/.cache/hyperspace
        rm -rf $HOME/.config/hyperspace
        sudo systemctl daemon-reload
        sleep 2
        echo -e "${GREEN}Нода успешно удалена.${NC}"
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
