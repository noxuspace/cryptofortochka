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
echo -e "${CYAN}2) Запуск ноды${NC}"
echo -e "${CYAN}3) Обновление ноды${NC}"
echo -e "${CYAN}4) Изменение порта${NC}"
echo -e "${CYAN}5) Проверка логов${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Dria...${NC}"

        # Обновление и установка зависимостей
        sudo apt update && sudo apt-get upgrade -y
        sudo apt install git make jq build-essential gcc unzip wget lz4 aria2 -y

        # Проверка архитектуры системы
        #ARCH=$(uname -m)
        #if [[ "$ARCH" == "aarch64" ]]; then
            #curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip
        #elif [[ "$ARCH" == "x86_64" ]]; then
            #curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip
        #else
            #echo -e "${RED}Не поддерживаемая архитектура системы: $ARCH${NC}"
            #exit 1
        #fi

        # Распаковываем ZIP-файл и переходим в папку
        #unzip dkn-compute-node.zip
        #cd dkn-compute-node

        # Запускаем приложение для ввода данных
        #./dkn-compute-launcher
        curl -fsSL https://dria.co/launcher | bash
        sleep 3
        mkdir -p "$HOME/.dria/dkn-compute-launcher" && wget -O "$HOME/.dria/dkn-compute-launcher/.env" https://raw.githubusercontent.com/firstbatchxyz/dkn-compute-launcher/master/.env.example
        dkn-compute-launcher start
        ;;
    2)
        echo -e "${BLUE}Запускаем ноду Dria...${NC}"

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Создание файла сервиса
        sudo bash -c "cat <<EOT > /etc/systemd/system/dria.service
[Unit]
Description=Dria Compute Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/.dria/dkn-compute-launcher/.env
ExecStart=/usr/local/bin/dkn-compute-launcher start
WorkingDirectory=$HOME_DIR/.dria/dkn-compute-launcher/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Перезагрузка и старт сервиса
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl enable dria
        sudo systemctl start dria

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u dria -f --no-hostname -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Проверка логов
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;
    3)
        echo -e "${BLUE}Обновляем ноду...${NC}"
        sudo systemctl stop dria
        sleep 3
        # Если старая версия есть, можно удалить её по пути, указанному в сервисе.
        # Если $(which dkn-compute-launcher) пустой, эта строка можно убрать или заменить проверкой.
        sudo rm /usr/local/bin/dkn-compute-launcher 2>/dev/null
        curl -fsSL https://dria.co/launcher | bash
        sleep 3
        # Явно копируем бинарник из нового пути в /usr/local/bin
        sudo cp $HOME/.dria/bin/dkn-compute-launcher /usr/local/bin/dkn-compute-launcher
        sudo chmod +x /usr/local/bin/dkn-compute-launcher
        sudo systemctl daemon-reload
        sleep 3
        sudo systemctl restart dria
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;
    4)
        echo -e "${BLUE}Изменение порта...${NC}"

        # Остановка сервиса
        sudo systemctl stop dria

        # Запрашиваем новый порт у пользователя
        echo -e "${YELLOW}Введите новый порт для Dria:${NC}"
        read NEW_PORT

        # Путь к файлу .env
        ENV_FILE="$HOME/.dria/dkn-compute-launcher/.env"

        # Обновляем порт в файле .env
        sed -i "s|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/[0-9]*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$NEW_PORT|" "$ENV_FILE"

        # Перезапуск сервиса
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl start dria

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u dria -f --no-hostname -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Проверка логов
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;
    5)
        # Проверка логов
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;
    6)
        echo -e "${BLUE}Удаление ноды Dria...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop dria
        sudo systemctl disable dria
        sudo rm /etc/systemd/system/dria.service
        sudo systemctl daemon-reload
        sleep 2

        # Удаление папки ноды
        rm -rf $HOME/.dria
        rm -rf ~/dkn-compute-node

        echo -e "${GREEN}Нода Dria успешно удалена!${NC}"

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
