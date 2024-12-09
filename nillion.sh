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
echo -e "${CYAN}3) Посмотреть логи${NC}"
echo -e "${CYAN}4) Заменить RPC${NC}"
echo -e "${CYAN}5) Бекап ноды${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Nillion...${NC}"

        # Обновление и установка необходимых компонентов
        sudo apt update -y
        sudo apt upgrade -y

        # Проверка наличия Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
            echo -e "${GREEN}Docker успешно установлен!${NC}"
        else
            DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
            MIN_DOCKER_VERSION="27.2.0"
            if [[ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]]; then
                echo -e "${YELLOW}Docker версии $DOCKER_VERSION ниже необходимой $MIN_DOCKER_VERSION. Обновляем Docker...${NC}"
                sudo apt install --only-upgrade docker.io -y
                echo -e "${GREEN}Docker обновлен до версии $(docker --version | grep -oP '\d+\.\d+\.\d+')!${NC}"
            fi
        fi

        # Проверка наличия Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            echo -e "${GREEN}Docker Compose успешно установлен!${NC}"
        fi

        # Установка Accuser Image
        docker pull nillion/verifier:v1.0.1

        # Создание директории для Accuser
        mkdir -p $HOME/nillion/verifier

        # Запуск контейнера для инициализации и регистрации Accuser
        docker run -v $HOME/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise

        # Ожидание действия пользователя
        echo -e "${YELLOW}Вернитесь к гайду и выполните шаги, начиная с пункта запроса токенов в кране. После выполнения 5-го пункта на платформе, вернитесь сюда и нажмите Enter${NC}"
        read -p ""

        # Запуск ноды
        docker run -d --name nillion -v $HOME/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com"

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов контейнера:${NC}"
        echo "docker logs -f nillion"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f nillion
        ;;

    2)
        echo -e "${GREEN}Установлена актуальная версия ноды.${NC}"
        ;;

    3)
        echo -e "${BLUE}Проверяем логи контейнера...${NC}"
        docker logs -f nillion
        ;;

    4)
        echo -e "${YELLOW}Введите новый RPC:${NC}"
        read NEW_RPC

        # Остановка и удаление контейнера
        docker stop nillion
        docker rm nillion

        # Запуск с новым RPC
        docker run -d --name nillion -v $HOME/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "$NEW_RPC"

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов контейнера:${NC}"
        echo "docker logs -f nillion"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        # Запуск логов
        docker logs -f nillion
        ;;

    5)
        echo -e "${RED}Сохраните эти данные в надежное место!${NC}"
        cat $HOME/nillion/verifier/credentials.json
        ;;

    6)
        echo -e "${BLUE}Удаление ноды...${NC}"

        # Остановка и удаление контейнера
        docker stop nillion
        docker rm nillion

        # Удаление папки проекта
        rm -rf $HOME/nillion

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}Нода Nillion успешно удалена!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 6.${NC}"
        ;;
esac
