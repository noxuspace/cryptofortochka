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
echo -e "${CYAN}2) Проверка логов${NC}"
echo -e "${CYAN}3) Получение ключа ноды${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка ноды Network3...${NC}"

        # Обновление и установка зависимостей
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y screen net-tools

        # Скачиваем и распаковываем бинарник
        wget https://network3.io/ubuntu-node-v2.1.0.tar
        tar -xvf ubuntu-node-v2.1.0.tar
        rm -rf ubuntu-node-v2.1.0.tar
        sudo ufw allow 8080

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Создаем сервис
        sudo bash -c "cat <<EOT > /etc/systemd/system/manager.service
[Unit]
Description=Manager Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/ubuntu-node/
ExecStart=/bin/bash $HOME_DIR/ubuntu-node/manager.sh up
ExecStop=/bin/bash $HOME_DIR/ubuntu-node/manager.sh down
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Запуск сервиса
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable manager
        sudo systemctl start manager

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -fu manager.service"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sudo journalctl -fu manager.service
        ;;
    2)
        # Проверка логов
        sudo journalctl -fu manager.service
        ;;
    3)
        echo -e "${BLUE}Получение ключа ноды...${NC}"
        sudo bash ubuntu-node/manager.sh key
        ;;
    4)
        echo -e "${BLUE}Удаление ноды Network3...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop manager
        sudo systemctl disable manager
        sudo rm /etc/systemd/system/manager.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки
        rm -rf $HOME_DIR/ubuntu-node

        echo -e "${GREEN}Нода Network3 успешно удалена!${NC}"

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
