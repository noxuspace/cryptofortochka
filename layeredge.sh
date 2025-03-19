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
echo -e "${CYAN}2) Запуск Merkle-сервиса${NC}"
echo -e "${CYAN}3) Запуск ноды${NC}"
echo -e "${CYAN}4) Проверка логов ноды${NC}"
echo -e "${CYAN}5) Перезапуск ноды${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем зависимости...${NC}"

        # Обновление и установка зависимостей
        sudo apt update && sudo apt-get upgrade -y

        git clone https://github.com/Layer-Edge/light-node.git
        cd light-node

        LATEST_GO_VERSION="1.21.3"  # Замените на актуальную версию, если нужно

        if ! command -v go &> /dev/null; then
            echo -e "${BLUE}Go не установлен. Устанавливаем последнюю версию ($LATEST_GO_VERSION)...${NC}"
            wget https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            rm go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            echo -e "${GREEN}Go установлен.${NC}"
        else
            echo -e "${BLUE}Go уже установлен. Обновляем его до версии $LATEST_GO_VERSION...${NC}"
            wget https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            rm go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            echo -e "${GREEN}Go обновлён до версии $LATEST_GO_VERSION.${NC}"
        fi

        if ! command -v rustc &> /dev/null; then
            echo -e "${BLUE}Rust не установлен. Устанавливаем Rust через rustup...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
            echo -e "${GREEN}Rust успешно установлен.${NC}"
        else
            echo -e "${BLUE}Rust уже установлен. Обновляем его через rustup update...${NC}"
            rustup update
            source $HOME/.cargo/env
            echo -e "${GREEN}Rust успешно обновлён.${NC}"
        fi

        curl -L https://risczero.com/install | bash
        rzup install

        # Запрашиваем приватный ключ у пользователя
        echo -e "${YELLOW}Введите ваш приватный ключ:${NC} "
        read PRIV_KEY
        
        # Создаем файл .env с нужным содержимым
        echo "export GRPC_URL=34.31.74.109:9090" > .env
        echo "export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
        echo "export ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
        echo "export API_REQUEST_TIMEOUT=100" >> .env
        echo "export POINTS_API=http://127.0.0.1:8080" >> .env
        echo "export PRIVATE_KEY='$PRIV_KEY'" >> .env

        cd ~
        
        echo -e "${GREEN}Зависимости установлены и настроены!${NC}"
        ;;
    2)
        echo -e "${BLUE}Запускаем Merkle-сервис...${NC}"

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/merkle.service
[Unit]
Description=Merkle Service for Light Node
After=network.target

[Service]
User=$USERNAME
Environment=PATH=$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
WorkingDirectory=$HOME_DIR/light-node/risc0-merkle-service
ExecStart=/usr/bin/env bash -c \"cargo build && cargo run --release\"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable merkle.service
        sudo systemctl start merkle.service
        # Проверка логов
        sudo journalctl -u merkle.service -f
        ;;
    3)
        echo -e "${BLUE}Запускаем ноду...${NC}"
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Определяем путь к Go
        GO_PATH=$(which go)
        
        # Проверяем, что GO_PATH не пустой
        if [ -z "$GO_PATH" ]; then
            echo "Go не найден в PATH. Проверьте установку Go."
            exit 1
        fi

        sudo bash -c "cat <<EOT > /etc/systemd/system/light-node.service
[Unit]
Description=LayerEdge Light Node Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/light-node
ExecStartPre=$GO_PATH build
ExecStart=$HOME_DIR/light-node/light-node
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable light-node.service
        sudo systemctl start light-node.service

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u light-node.service -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sudo journalctl -u light-node.service -f
        ;;
    4)
        echo -e "${BLUE}Проверяем логи ноды...${NC}"
        sudo journalctl -u light-node.service -f
        ;;
    5)
        echo -e "${BLUE}Перезапускаем ноду...${NC}"
        sudo systemctl restart light-node.service
        sudo journalctl -u light-node.service -f
        ;;
    6)
        echo -e "${BLUE}Удаление ноды...${NC}"
        sudo systemctl stop light-node.service
        sudo systemctl disable light-node.service
        sudo systemctl stop merkle.service
        sudo systemctl disable merkle.service

        sudo rm /etc/systemd/system/light-node.service
        sudo rm /etc/systemd/system/merkle.service
        sudo systemctl daemon-reload

        rm -rf ~/light-node

        echo -e "${GREEN}Нода успешно удалена!${NC}"

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
