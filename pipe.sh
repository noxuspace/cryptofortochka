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
    sudo apt update -y
    sudo apt install curl -y
fi

# Отображение логотипа
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
echo -e "${CYAN}3) Проверка логов${NC}"
echo -e "${CYAN}4) Статус ноды${NC}"
echo -e "${CYAN}5) Проверка поинтов${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${BLUE}Начинаем установку ноды Pipe...${NC}"

        # Обновление системы
        sudo apt update -y && sudo apt upgrade -y

        # Создание необходимых папок
        mkdir -p $HOME/pipenetwork
        mkdir -p $HOME/pipenetwork/download_cache

        # Скачиваем бинарник
        curl -o $HOME/pipenetwork/pop https://dl.pipecdn.app/v0.2.5/pop
        chmod +x $HOME/pipenetwork/pop
        $HOME/pipenetwork/pop --refresh

        # Создание .env файла
        echo -e "${YELLOW}Введите количество оперативной памяти для этой ноды, если хотите выделить 8 Gb, то напишите просто 8:${NC}"
        read -p "RAM: " ram
        echo -e "${YELLOW}Введите количество свободного дискового пространства для этой ноды, если хотите выделить 100 Gb, то напишите просто 100:${NC}"
        read -p "Max-disk: " max_disk
        echo -e "${YELLOW}Введите адрес кошелька Solana:${NC}"
        read -p "pubKey: " pubKey

        # Создаем .env файл с введенными данными
        echo -e "ram=$ram\nmax-disk=$max_disk\ncache-dir=$HOME/pipenetwork/download_cache\npubKey=$pubKey" > $HOME/pipenetwork/.env

        # Создание и запуск сервисного файла
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo tee /etc/systemd/system/pipe-pop.service > /dev/null << EOF
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$HOME_DIR/pipenetwork
ExecStart=$HOME_DIR/pipenetwork/pop \
    --ram $ram \
    --max-disk $max_disk \
    --cache-dir $HOME_DIR/pipenetwork/download_cache \
    --pubKey $pubKey
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node

[Install]
WantedBy=multi-user.target
EOF

        # Перезагрузка и запуск сервиса
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable pipe-pop
        sudo systemctl start pipe-pop

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u pipe-pop -f --no-hostname -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        sudo journalctl -u pipe-pop -f --no-hostname -o cat
        ;;

    2)
        sudo systemctl stop pipe-pop
        rm -f $HOME/pipenetwork/pop
        curl -o $HOME/pipenetwork/pop https://dl.pipecdn.app/v0.2.5/pop
        chmod +x $HOME/pipenetwork/pop
        $HOME/pipenetwork/pop --refresh
        sudo systemctl restart pipe-pop && sudo journalctl -u pipe-pop -f --no-hostname -o cat
        ;;

    3)
        echo -e "${BLUE}Просмотр логов Pipe...${NC}"
        sudo journalctl -u pipe-pop -f --no-hostname -o cat
        ;;

    4)
        echo -e "${BLUE}Статус ноды Pipe...${NC}"
        cd
        cd $HOME/pipenetwork/
        ./pop --status
        ;;

    5)
        echo -e "${BLUE}Проверка поинтов Pipe...${NC}"
        cd
        cd $HOME/pipenetwork/
        ./pop --points-route
        ;;

    6)
        echo -e "${BLUE}Удаляем ноду Pipe...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop pipe-pop
        sudo systemctl disable pipe-pop
        sudo rm /etc/systemd/system/pipe-pop.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папок
        rm -rf $HOME/pipenetwork

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
