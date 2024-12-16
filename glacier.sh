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
    echo -e "${CYAN}3) Просмотр логов${NC}"
    echo -e "${CYAN}4) Удаление ноды${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Устанавливаем ноду Glacier...${NC}"

            # Обновление и установка необходимых компонентов
            sudo apt update -y
            sudo apt upgrade -y

            # Проверка наличия Docker
            if ! command -v docker &> /dev/null; then
                echo -e "${BLUE}Docker не установлен. Устанавливаем Docker...${NC}"
                sudo apt install docker.io -y
            fi

            # Запрос приватного ключа
            echo -e "${YELLOW}Введите приватный ключ от вашего кошелька:${NC}"
            read -r YOUR_PRIVATE_KEY

            # Запуск контейнера
            docker run -d -e PRIVATE_KEY=$YOUR_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для просмотра логов:${NC}"
            echo "docker logs -f glacier-verifier"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 2

            # Проверка логов
            docker logs -f glacier-verifier
            ;;

        2)
            echo -e "${BLUE}Обновляем ноду Glacier...${NC}"

            # Запрос приватного ключа
            echo -e "${YELLOW}Введите приватный ключ от вашего кошелька:${NC}"
            read -r YOUR_PRIVATE_KEY

            # Остановка и обновление контейнера
            docker stop glacier-verifier
            docker rm glacier-verifier
            docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi
            docker run -d -e PRIVATE_KEY=$YOUR_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для просмотра логов:${NC}"
            echo "docker logs -f glacier-verifier"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 2

            # Проверка логов
            docker logs -f glacier-verifier
            ;;

        3)
            echo -e "${BLUE}Просмотр логов Glacier...${NC}"
            docker logs -f glacier-verifier
            ;;

        4)
            echo -e "${BLUE}Удаление ноды Glacier...${NC}"

            # Остановка и удаление контейнера
            docker stop glacier-verifier
            docker rm glacier-verifier
            docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi

            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}Нода Glacier успешно удалена!${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac
