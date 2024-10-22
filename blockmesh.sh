#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

echo -e "${BLUE}Проверяем версию вашей OS...${NC}"
# Проверка наличия bc и установка, если не установлен
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi

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
echo -e "${CYAN}2) Проверка логов (выход из логов CTRL+C)${NC}"
echo -e "${CYAN}3) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду BlockMesh...${NC}"

        # Проверка наличия tar и установка, если не установлен
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi
        sleep 1

        # Скачиваем бинарник BlockMesh
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Распаковываем архив
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        sleep 1

        # Удаляем архив
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Переходим в папку ноды
        cd target/release

        # Запрашиваем данные у пользователя
        echo -e "${YELLOW}Введите ваш email:${NC}"
        read USER_EMAIL

        echo -e "${YELLOW}Введите ваш пароль:${NC}"
        read USER_PASSWORD

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)

        if [ "$USERNAME" == "root" ]; then
            HOME_DIR="/root"
        else
            HOME_DIR="/home/$USERNAME"
        fi

        # Создаем или обновляем файл сервиса с использованием определенного имени пользователя и домашней директории
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/release/blockmesh-cli login --email $USER_EMAIL --password $USER_PASSWORD
WorkingDirectory=$HOME_DIR/target/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Обновляем сервисы и включаем BlockMesh
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl start blockmesh

        # Заключительный вывод
        echo -e "${GREEN}Установка завершена и нода запущена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Проверка логов
        sudo journalctl -u blockmesh -f
        ;;

    2)
        # Проверка логов
        sudo journalctl -u blockmesh -f
        ;;

    3)
        echo -e "${BLUE}Удаление ноды BlockMesh...${NC}"

        # Остановка и отключение сервиса
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки target с файлами
        rm -rf target

        echo -e "${GREEN}Нода BlockMesh успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
        
esac
