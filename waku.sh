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
    echo -e "${CYAN}4) Замена портов${NC}"
    echo -e "${CYAN}5) Удаление ноды${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Устанавливаем ноду Waku...${NC}"

            # Обновление и установка компонентов
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli \
                                pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

            # Проверка наличия Docker и версии
            if ! command -v docker &> /dev/null; then
                echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker версии 24.0.7...${NC}"
                curl -fsSL https://get.docker.com | sh
            else
                DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
                MIN_DOCKER_VERSION="24.0.7"
                if [[ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]]; then
                    echo -e "${YELLOW}Обновляем Docker до версии 24.0.7...${NC}"
                    curl -fsSL https://get.docker.com | sh
                fi
            fi

            # Проверка наличия Docker Compose и версии
            if ! command -v docker-compose &> /dev/null; then
                echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем версию 1.29.2...${NC}"
                sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            else
                DOCKER_COMPOSE_VERSION=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+')
                MIN_COMPOSE_VERSION="1.29.2"
                if [[ "$(printf '%s\n' "$MIN_COMPOSE_VERSION" "$DOCKER_COMPOSE_VERSION" | sort -V | head -n1)" != "$MIN_COMPOSE_VERSION" ]]; then
                    echo -e "${YELLOW}Обновляем Docker Compose до версии 1.29.2...${NC}"
                    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                    sudo chmod +x /usr/local/bin/docker-compose
                fi
            fi

            # Клонируем репозиторий и настраиваем
            cd $HOME
            git clone https://github.com/waku-org/nwaku-compose
            cd $HOME/nwaku-compose
            cp .env.example .env

            # Запрашиваем у пользователя данные
            echo -e "${YELLOW}Введите RPC URL для доступа к тестнету:${NC}"
            read RPC_URL
            echo -e "${YELLOW}Введите ваш приватный ключ EVM кошелька:${NC}"
            read ETH_KEY
            echo -e "${YELLOW}Введите пароль для RLN Membership:${NC}"
            read RLN_PASSWORD

            # Обновление конфигурации .env
            sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC_URL|" .env
            sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$ETH_KEY|" .env
            sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$RLN_PASSWORD|" .env

            # Регистрация ноды
            ./register_rln.sh

            # Запуск docker-compose
            docker-compose up -d

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Нода Waku успешно установлена и запущена!${NC}"
            echo -e "${YELLOW}Для проверки логов используйте:${NC}"
            echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
           
            ;;

        2)
            echo -e "${BLUE}Обновление ноды Waku...${NC}"
            cd $HOME/nwaku-compose
            docker-compose down
            sudo rm -r keystore rln_tree
            git pull origin master
            ./register_rln.sh
            docker-compose up -d
            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Нода Waku успешно обновлена и запущена!${NC}"
            echo -e "${YELLOW}Для проверки логов используйте:${NC}"
            echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            
            ;;

        3)
            echo -e "${BLUE}Проверка логов ноды Waku...${NC}"
            cd $HOME/nwaku-compose
            docker-compose logs -f
            ;;

        4)
           # Путь к файлу docker-compose.yml
            COMPOSE_FILE="$HOME/nwaku-compose/docker-compose.yml"
            
            # Проверка существования файла
            if [[ ! -f "$COMPOSE_FILE" ]]; then
                echo -e "${RED}Файл docker-compose.yml не найден по пути: $COMPOSE_FILE${NC}"
                exit 1
            fi
            
            # Функция замены только внешнего порта
            replace_port() {
                local OLD_PORT="$1"
                local NEW_PORT="$2"
            
                # Проверяем наличие старого порта в файле
                if ! grep -qE "[[:space:]]${OLD_PORT}:" "$COMPOSE_FILE"; then
                    echo -e "${RED}Порт ${OLD_PORT} не найден в файле.${NC}"
                    return 1
                fi
            
                # Замена только внешнего порта
                sed -i -E "s/([[:space:]])${OLD_PORT}:([0-9]+)/\1${NEW_PORT}:\2/g" "$COMPOSE_FILE"
            
                # Проверяем успешность замены
                if grep -qE "[[:space:]]${NEW_PORT}:" "$COMPOSE_FILE"; then
                    echo -e "${GREEN}Порт ${OLD_PORT} успешно заменен на ${NEW_PORT} в файле.${NC}"
                else
                    echo -e "${RED}Ошибка: не удалось заменить порт ${OLD_PORT} на ${NEW_PORT}.${NC}"
                    return 1
                fi
            }
            
            # Запрашиваем старый и новый порты
            echo -e "${YELLOW}Введите внешний порт, который вы хотите заменить:${NC} \c"
            read OLD_PORT
            
            if ! [[ "$OLD_PORT" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Ошибка: порт должен быть числом.${NC}"
                exit 1
            fi
            
            echo -e "${YELLOW}Введите новый внешний порт для замены:${NC} \c"
            read NEW_PORT
            
            if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Ошибка: новый порт должен быть числом.${NC}"
                exit 1
            fi
            
            # Подтверждение действий
            echo -e "${YELLOW}Вы хотите заменить внешний порт ${OLD_PORT} на ${NEW_PORT}. Продолжить? (y/n)${NC} \c"
            read CONFIRM
            if [[ "$CONFIRM" != "y" ]]; then
                echo -e "${CYAN}Замена отменена пользователем.${NC}"
                exit 0
            fi
            
            # Остановка Docker Compose
            echo -e "${YELLOW}Останавливаем контейнеры...${NC}"
            cd "$HOME/nwaku-compose" || exit
            docker-compose down
            
            # Замена порта
            replace_port "$OLD_PORT" "$NEW_PORT"
            
            # Перезапуск Docker Compose
            echo -e "${YELLOW}Перезапускаем контейнеры...${NC}"
            docker-compose up -d
            echo -e "${GREEN}Контейнеры успешно запущены!${NC}"

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Порты успешно изменены и нода запущена!${NC}"
            echo -e "${YELLOW}Для проверки логов используйте:${NC}"
            echo -e "cd $HOME/nwaku-compose && docker-compose logs -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1

            ;;

        5)
            echo -e "${BLUE}Удаление ноды Waku...${NC}"
            cd $HOME/nwaku-compose
            docker-compose down
            cd $HOME
            rm -rf nwaku-compose
            echo -e "${GREEN}Нода Waku успешно удалена!${NC}"
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac
