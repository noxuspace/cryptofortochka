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
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

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
echo -e "${CYAN}2) Проверка логов story-geth (CTRL+C для выхода из логов)${NC}"
echo -e "${CYAN}3) Проверка логов story (CTRL+C для выхода из логов)${NC}"
echo -e "${CYAN}4) Проверка синхронизации блоков (CTRL+C для выхода из логов)${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер: ${NC}"
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду...${NC}"

        # Обновление и установка зависимостей
        sudo apt update && sudo apt-get update
        sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 -y

        # Загрузка Story-Geth binary
        cd $HOME
        wget https://github.com/piplabs/story-geth/releases/download/v0.10.0/geth-linux-amd64
        [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
        if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
          echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
        fi
        chmod +x geth-linux-amd64
        mv $HOME/geth-linux-amd64 $HOME/go/bin/story-geth
        source $HOME/.bash_profile
        story-geth version
        sleep 2

        # Загрузка Story binary
        cd $HOME
        rm -rf story-linux-amd64
        wget https://github.com/piplabs/story/releases/download/v0.12.0/story-linux-amd64
        [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
        if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
          echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
        fi
        chmod +x story-linux-amd64
        sudo cp $HOME/story-linux-amd64 $HOME/go/bin/story
        source $HOME/.bash_profile
        story version
        sleep 2

        # Запрос ввода "Введите название (моникер) для вашей ноды"
        echo -e "${YELLOW}Введите название (моникер) для вашей ноды: ${NC}"
        read MONIKER

        # Инициализация Iliad ноды
        story init --network odyssey --moniker "$MONIKER"

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Создание файла сервиса story-geth
        sudo bash -c "cat <<EOT > /etc/systemd/system/story-geth.service
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/go/bin/story-geth --odyssey --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOT"

        # Создание файла сервиса story
        sudo bash -c "cat <<EOT > /etc/systemd/system/story.service
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOT"

        # Перезагрузка и старт story-geth
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl start story-geth
        sudo systemctl enable story-geth
        sleep 2

        # Перезагрузка и старт story
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl start story
        sudo systemctl enable story
        sleep 2

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов story-geth:${NC}"
        echo "sudo journalctl -u story-geth -f -o cat"
        echo -e "${YELLOW}Команда для проверки логов story:${NC}"
        echo "sudo journalctl -u story -f -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;
    2)
        sudo journalctl -u story-geth -f -o cat
        ;;
    3)
        sudo journalctl -u story -f -o cat
        ;;
    4)
        while true; do
            local_height=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height');
            network_height=$(curl -s https://odyssey.storyrpc.io/status | jq -r '.result.sync_info.latest_block_height');
            blocks_left=$((network_height - local_height));
            echo -e "\033[1;38mYour node height:\033[0m \033[1;34m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m";
            sleep 5;
        done
        ;;
    5)
        echo -e "${BLUE}Удаление ноды...${NC}"

        # Остановка и удаление сервисов
        sudo systemctl stop story-geth
        sudo systemctl stop story
        sudo systemctl disable story-geth
        sudo systemctl disable story
        sudo rm /etc/systemd/system/story-geth.service
        sudo rm /etc/systemd/system/story.service
        sudo systemctl daemon-reload
        sleep 2

        # Удаление папок проекта
        rm -rf $HOME/go/bin/story-geth
        rm -rf $HOME/go/bin/story

        echo -e "${GREEN}Нода успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 5.${NC}"
        ;;
esac
