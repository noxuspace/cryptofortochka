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
echo -e "${CYAN}1) Установка ноды в тестнете${NC}"
echo -e "${CYAN}2) Обновление ноды в тестнете${NC}"
echo -e "${CYAN}3) Проверка логов в тестнете${NC}"
echo -e "${CYAN}4) Удаление ноды в тестнете${NC}"
echo -e "${CYAN}5) Установка ноды в мейннете${NC}"
echo -e "${CYAN}6) Обновление ноды в мейннете${NC}"
echo -e "${CYAN}7) Проверка логов в мейннете${NC}"
echo -e "${CYAN}8) Удаление ноды в мейннете${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка ноды в тестнете...${NC}"

        # Обновление и установка зависимостей
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl git jq lz4 build-essential unzip

        # Проверка наличия Docker и Docker Compose
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi

        # Создание папки elixir и загрузка конфигурационного файла
        mkdir -p $HOME/elixir
        cd $HOME/elixir
        wget https://files.elixir.finance/validator.env

        # Запрос данных у пользователя
        echo -e "${YELLOW}Введите IP-адрес сервера:${NC}"
        read STRATEGY_EXECUTOR_IP_ADDRESS

        echo -e "${YELLOW}Введите имя валидатора:${NC}"
        read STRATEGY_EXECUTOR_DISPLAY_NAME

        echo -e "${YELLOW}Введите адрес EVM:${NC}"
        read STRATEGY_EXECUTOR_BENEFICIARY

        echo -e "${YELLOW}Введите приватный ключ EVM:${NC}"
        read SIGNER_PRIVATE_KEY

        # Обновление конфигурационного файла
        sed -i 's|ENV=prod|ENV=testnet-3|' validator.env
        echo "STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS" >> validator.env
        echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME" >> validator.env
        echo "STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY" >> validator.env
        echo "SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY" >> validator.env

        # Установка Docker-образа
        docker pull elixirprotocol/validator:testnet --platform linux/amd64

        # Ожидание пользователя
        echo -e "${YELLOW}Следуйте гайду и заклеймите токены на платформе, когда сделаете это, нажмите Enter...${NC}"
        read -p ""

        # Запуск контейнера
        docker run --name elixir --env-file validator.env --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "docker logs -f elixir"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f elixir
        ;;
    2)
        echo -e "${BLUE}Обновление ноды в тестнете...${NC}"

        # Остановка и удаление контейнера
        cd $HOME/elixir
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker rm

        # Установка новой версии
        docker pull elixirprotocol/validator:testnet --platform linux/amd64

        # Запуск контейнера
        docker run --name elixir --env-file validator.env --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "docker logs -f elixir"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f elixir
        ;;
    3)
        # Проверка логов
        docker logs -f elixir
        ;;
    4)
        echo -e "${BLUE}Удаление ноды в тестнете...${NC}"

        # Остановка и удаление контейнера
        cd $HOME/elixir
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir$" | awk '{print $1}' | xargs docker rm

        # Удаление папки проекта
        rm -rf $HOME/elixir

        echo -e "${GREEN}Нода успешно удалена!${NC}"

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    5)
        echo -e "${BLUE}Установка ноды в мейннете...${NC}"

        # Обновление и установка зависимостей
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl git jq lz4 build-essential unzip

        # Проверка наличия Docker и Docker Compose
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi

                # Создание папки elixir-main и загрузка конфигурационного файла
        mkdir -p $HOME/elixir-main
        cd $HOME/elixir-main
        wget https://files.elixir.finance/validator.env

        # Запрос данных у пользователя
        echo -e "${YELLOW}Введите IP-адрес сервера:${NC}"
        read STRATEGY_EXECUTOR_IP_ADDRESS

        echo -e "${YELLOW}Введите имя валидатора:${NC}"
        read STRATEGY_EXECUTOR_DISPLAY_NAME

        echo -e "${YELLOW}Введите адрес EVM:${NC}"
        read STRATEGY_EXECUTOR_BENEFICIARY

        echo -e "${YELLOW}Введите приватный ключ EVM:${NC}"
        read SIGNER_PRIVATE_KEY

        # Обновление конфигурационного файла
        sed -i 's|ENV=prod|ENV=prod|' validator.env
        echo "STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS" >> validator.env
        echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME" >> validator.env
        echo "STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY" >> validator.env
        echo "SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY" >> validator.env

        # Установка Docker-образа
        docker pull elixirprotocol/validator --platform linux/amd64

        # Запуск контейнера
        docker run --name elixir-main --env-file validator.env --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "docker logs -f elixir-main"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f elixir-main
        ;;
    6)
        echo -e "${BLUE}Обновление ноды в мейннете...${NC}"

        # Остановка и удаление контейнера
        cd $HOME/elixir-main
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker rm

        # Установка новой версии
        docker pull elixirprotocol/validator --platform linux/amd64

        # Запуск контейнера
        docker run --name elixir-main --env-file validator.env --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "docker logs -f elixir-main"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f elixir-main
        ;;
    7)
        # Проверка логов
        docker logs -f elixir-main
        ;;
    8)
        echo -e "${BLUE}Удаление ноды в мейннете...${NC}"

        # Остановка и удаление контейнера
        cd $HOME/elixir-main
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker stop
        docker ps -a | grep " elixir-main$" | awk '{print $1}' | xargs docker rm

        # Удаление папки проекта
        rm -rf $HOME/elixir-main

        echo -e "${GREEN}Нода успешно удалена!${NC}"

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
        ;;
esac


       
