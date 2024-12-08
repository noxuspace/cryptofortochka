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
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Проверка логов${NC}"
echo -e "${CYAN}4) Проверка статуса работы ноды${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Unichain...${NC}"

        # Обновляем систему и устанавливаем пакеты
        sudo apt update -y
        sudo apt upgrade -y

        # Проверка, установлен ли Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
        else
            echo -e "${GREEN}Docker уже установлен. Пропускаем установку.${NC}"
        fi

        # Проверка, установлен ли Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        else
            echo -e "${GREEN}Docker Compose уже установлен. Пропускаем установку.${NC}"
        fi

        rm -rf unichain-node/

        # Клонируем репозиторий Uniswap Unichain Node
        if [ ! -d "$HOME/unichain-node" ]; then
            echo -e "${YELLOW}Клонируем репозиторий Uniswap Unichain Node...${NC}"
            git clone https://github.com/Uniswap/unichain-node $HOME/unichain-node
        else
            echo -e "${GREEN}Папка unichain-node уже существует. Пропускаем клонирование.${NC}"
        fi

        # Переходим в директорию unichain-node
        cd $HOME/unichain-node || { echo -e "${RED}Не удалось войти в директорию unichain-node. Выход.${NC}"; exit 1; }

        # Проверяем, существует ли файл .env.sepolia
        if [ -f ".env.sepolia" ]; then
            echo -e "${YELLOW}Редактируем файл .env.sepolia...${NC}"

            # Меняем значение OP_NODE_L1_ETH_RPC
            sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia

            # Меняем значение OP_NODE_L1_BEACON
            sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia

            echo -e "${GREEN}Файл .env.sepolia успешно обновлен.${NC}"
        else
            echo -e "${RED}Файл .env.sepolia не найден. Выход.${NC}"
            exit 1
        fi

        # Запуск контейнеров в фоновом режиме
        echo -e "${BLUE}Запускаем контейнеры с помощью docker-compose...${NC}"
        docker-compose up -d
        cd $HOME

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "cd unichain-node && docker-compose logs -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Проверка логов
        cd unichain-node && docker-compose logs -f
        ;;
    2)
        echo -e "${BLUE}Обновление ноды Unichain...${NC}"
        echo -e "${GREEN}Установлена актуальная версия ноды.${NC}"
        ;;
    3)
        echo -e "${BLUE}Проверка логов Unichain...${NC}"
        cd $HOME/unichain-node || { echo -e "${RED}Не удалось войти в директорию unichain-node. Выход.${NC}"; exit 1; }
        docker-compose logs -f
        ;;
    4)
        echo -e "${BLUE}Проверка статуса работы ноды Unichain...${NC}"
        curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
        -H "Content-Type: application/json" http://localhost:8545
        ;;
    5)
        echo -e "${BLUE}Удаление ноды Unichain...${NC}"
        cd $HOME/unichain-node || { echo -e "${RED}Не удалось войти в директорию unichain-node. Выход.${NC}"; exit 1; }
        docker-compose down -v
        cd $HOME
        rm -rf $HOME/unichain-node
        echo -e "${GREEN}Нода Unichain успешно удалена!${NC}"

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 5.${NC}"
        ;;
esac
