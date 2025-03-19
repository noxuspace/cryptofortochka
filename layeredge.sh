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

        REQUIRED_GO_VERSION="1.18"
        LATEST_GO_VERSION="1.20.3"  # Замените на актуальную последнюю версию, если нужно
        
        if ! command -v go >/dev/null 2>&1; then
            echo -e "${BLUE}Go не установлен. Устанавливаем последнюю версию ($LATEST_GO_VERSION)...${NC}"
            wget https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            rm go${LATEST_GO_VERSION}.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            echo -e "${BLUE}Go установлен.${NC}"
        else
            current_version=$(go version | awk '{print $3}' | sed 's/go//')
            echo -e "${BLUE}Установленная версия Go: $current_version${NC}"
            if [ "$(printf '%s\n' "$REQUIRED_GO_VERSION" "$current_version" | sort -V | head -n1)" = "$current_version" ] && [ "$current_version" != "$REQUIRED_GO_VERSION" ]; then
                echo -e "${BLUE}Версия Go ($current_version) ниже требуемой ($REQUIRED_GO_VERSION). Обновляем до версии $LATEST_GO_VERSION...${NC}"
                wget https://go.dev/dl/go${LATEST_GO_VERSION}.linux-amd64.tar.gz
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf go${LATEST_GO_VERSION}.linux-amd64.tar.gz
                rm go${LATEST_GO_VERSION}.linux-amd64.tar.gz
                export PATH=$PATH:/usr/local/go/bin
                echo -e "${BLUE}Go обновлён до версии $LATEST_GO_VERSION.${NC}"
            else
                echo -e "${GREEN}Установленная версия Go удовлетворяет требованиям.${NC}"
            fi
        fi

        
        ;;
    2)
        echo -e "${BLUE}Запускаем Merkle-сервис...${NC}"

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        

      

        

        # Проверка логов
        
        ;;
    3)
        echo -e "${BLUE}Запускаем ноду...${NC}"


        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u dria -f --no-hostname -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        
        ;;
    4)
        echo -e "${BLUE}Проверяем логи ноды...${NC}"

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
        
        ;;
    5)
        echo -e "${BLUE}Перезапускаем ноду...${NC}"
        # Проверка логов
        
        ;;
    6)
        echo -e "${BLUE}Удаление ноды...${NC}"

        

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
