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
    echo -e "${CYAN}4) Рестарт ноды${NC}"
    echo -e "${CYAN}5) Удаление ноды${NC}"
    read -p "Введите номер: " choice

    case $choice in
        1)
            echo -e "${BLUE}Установка ноды OpenLedger...${NC}"

            # Проверка и установка Docker
            if ! command -v docker &> /dev/null; then
                echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
                apt remove docker docker-engine docker.io containerd runc -y
                apt install -y apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update
                apt install -y docker-ce docker-ce-cli containerd.io
                echo -e "${GREEN}Docker успешно установлен.${NC}"
            else
                echo -e "${GREEN}Docker уже установлен.${NC}"
            fi

            # Проверка и установка необходимых зависимостей
            sudo apt update && sudo apt upgrade -y
            sudo apt install ubuntu-desktop xrdp unzip -y

            # Настройка XRDP
            sudo adduser xrdp ssl-cert
            sudo systemctl start gdm
            sudo systemctl restart xrdp
            sudo systemctl enable xrdp

            # Загрузка и установка OpenLedger
            wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip
            unzip openledger-node-1.0.0-linux.zip
            sudo dpkg -i openledger-node-1.0.0.deb

            # Проверяем, активен ли Docker
            if systemctl is-active --quiet docker; then
                echo "Docker уже запущен."
            else
                echo "Запускаем Docker..."
                sudo systemctl start docker
            fi
            
            # Проверяем, включён ли Docker в автозагрузку
            if systemctl is-enabled --quiet docker; then
                echo "Docker уже добавлен в автозагрузку."
            else
                echo "Добавляем Docker в автозагрузку..."
                sudo systemctl enable docker
            fi

            # Создание systemd-сервиса для OpenLedger
            cat > /etc/systemd/system/openledger.service << EOF
[Unit]
Description=OpenLedger Node
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openledger-node --no-sandbox --disable-gpu
Restart=always
User=root
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

            # Перезапуск systemd и включение сервиса
            systemctl daemon-reload
            systemctl enable openledger.service
            systemctl start openledger.service

            # Завершающий вывод
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для проверки логов:${NC}" 
            echo "sudo journalctl -u openledger -f --no-hostname -o cat"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 2
            sudo journalctl -u openledger -f --no-hostname -o cat
            
            ;;

        2)
            echo -e "${GREEN}У вашей ноды актуальная версия.${NC}"
            ;;

        3)
            echo -e "${YELLOW}Проверка логов ноды...${NC}"
            sudo journalctl -u openledger -f --no-hostname -o cat
            ;;

        4)
            echo -e "${YELLOW}Рестарт ноды...${NC}"
            sudo systemctl restart openledger && sudo journalctl -u openledger -f --no-hostname -o cat
            ;;

        5)
            echo -e "${RED}Удаление ноды OpenLedger...${NC}"
            systemctl stop openledger.service
            systemctl disable openledger.service
            rm -f /etc/systemd/system/openledger.service
            systemctl daemon-reload
            echo -e "${GREEN}Нода OpenLedger успешно удалена.${NC}"
            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 5.${NC}"
            ;;
    esac
