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
            echo -e "${GREEN}Go установлен.${NC}"
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
                echo -e "${GREEN}Go обновлён до версии $LATEST_GO_VERSION.${NC}"
            else
                echo -e "${GREEN}Установленная версия Go удовлетворяет требованиям.${NC}"
            fi
        fi

        REQUIRED_RUST_VERSION="1.81.0"

        if ! command -v rustc >/dev/null 2>&1; then
            echo -e "${BLUE}Rust не установлен. Устанавливаем Rust (через rustup)...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
            echo -e "${GREEN}Rust установлен.${NC}"
        else
            current_version=$(rustc --version | awk '{print $2}')
            echo -e "${BLUE}Установленная версия Rust: $current_version${NC}"
            # Сравниваем версии: если текущая версия меньше требуемой, обновляем.
            if [ "$(printf '%s\n' "$REQUIRED_RUST_VERSION" "$current_version" | sort -V | head -n1)" = "$current_version" ] && [ "$current_version" != "$REQUIRED_RUST_VERSION" ]; then
                echo -e "${BLUE}Версия Rust ($current_version) ниже требуемой ($REQUIRED_RUST_VERSION). Обновляем Rust...${NC}"
                rustup update
                source $HOME/.cargo/env
                echo -e "${GREEN}Rust обновлён до последней версии.${NC}"
            else
                echo -e "${GREEN}Установленная версия Rust удовлетворяет требованиям.${NC}"
            fi
        fi

        if ! command -v rzup >/dev/null 2>&1; then
            echo -e "${BLUE}Risc0 Toolchain не установлен. Устанавливаем Risc0 Toolchain...${NC}"
            curl -L https://risczero.com/install | bash && rzup install
            echo -e "${GREEN}Risc0 Toolchain установлен.${NC}"
        else
            echo -e "${GREEN}Risc0 Toolchain уже установлен.${NC}"
        fi

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
        
        echo -e "${GREEN}Зависимости установлены и настроены!${NC}"
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
