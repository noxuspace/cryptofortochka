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

# Отображение логотипа
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Запуск ноды${NC}"
echo -e "${CYAN}3) Проверка логов${NC}"
echo -e "${CYAN}4) Рестарт ноды${NC}"
echo -e "${CYAN}5) Обновление ноды${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${BLUE}Начинаем установку ноды Privasea...${NC}"

        # Обновление системы
        sudo apt update && sudo apt upgrade -y

        # Проверка наличия Docker и Docker Compose
        if ! command -v docker &> /dev/null; then
            echo -e "${BLUE}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
            if ! command -v docker &> /dev/null; then
                echo -e "${RED}Ошибка: Docker не был установлен.${NC}"
                exit 1
            fi
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${BLUE}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            if ! command -v docker-compose &> /dev/null; then
                echo -e "${RED}Ошибка: Docker Compose не был установлен.${NC}"
                exit 1
            fi
        fi

        # Пуллим проект
        docker pull privasea/acceleration-node-beta:latest
        mkdir -p ~/privasea/config && cd ~/privasea
        ;;

    2)
        echo -e "${BLUE}Запуск ноды Privasea...${NC}"

        # Запрос пароля от пользователя
        echo -e "${YELLOW}Введите пароль, который вы вводили на этапе создания кошелька${NC}"
        read -s -p "Пароль: " PASS
        echo

        # Запуск контейнера с нодой
        docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$PASS privasea/acceleration-node-beta:latest
        if [ $? -ne 0 ]; then
            echo -e "${RED}Не удалось запустить контейнер Docker.${NC}"
            exit 1
        fi

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "docker logs -f privanetix-node"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2

        docker logs -f privanetix-node
        ;;

    3)
        echo -e "${BLUE}Просмотр логов Privasea...${NC}"
        docker logs -f privanetix-node
        ;;

    4)
        echo -e "${BLUE}Рестарт ноды Privasea...${NC}"

        # Перезапуск контейнера
        docker restart privanetix-node
        sleep 2

        # Вывод логов после перезапуска
        docker logs -f privanetix-node
        ;;

    5)
        echo -e "${GREEN}У вас актуальная версия ноды Privasea.${NC}"
        ;;

    6)
        echo -e "${BLUE}Удаляем ноду Privasea...${NC}"

        # Остановка и удаление контейнера
        docker stop privanetix-node
        docker rm privanetix-node
        rm -rf ~/privasea

        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
