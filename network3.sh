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
    echo -e "${CYAN}3) Получение ключа ноды${NC}"
    echo -e "${CYAN}4) Удаление ноды${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Установка ноды Network3...${NC}"

            # Обновление и установка зависимостей
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt install -y screen net-tools iptables

            # Скачивание и распаковка ноды
            wget https://network3.io/ubuntu-node-v2.1.1.tar.gz
            if [ -f "ubuntu-node-v2.1.1.tar.gz" ]; then
                tar -xvf ubuntu-node-v2.1.1.tar.gz
                rm ubuntu-node-v2.1.1.tar.gz
            else
                echo -e "${RED}Ошибка: Файл ubuntu-node-v2.1.1.tar.gz не найден.${NC}"
                exit 1
            fi

            # Проверка и открытие порта 8080
            if ! sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
                echo -e "${BLUE}Открываем порт 8080 через iptables...${NC}"
                sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
                sudo iptables-save > /etc/iptables/rules.v4
            else
                echo -e "${GREEN}Порт 8080 уже открыт.${NC}"
            fi

            if sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
                echo -e "${GREEN}Правила уже сохранены.${NC}"
            else
                echo -e "${BLUE}Сохраняем правила...${NC}"
                sudo iptables-save > /etc/iptables/rules.v4
            fi

            # Запуск ноды
            cd ubuntu-node
            sudo bash manager.sh up
            cd

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Нода установлена. Перейдите по ссылке, чтобы проверить её работу:${NC}"
            echo "http://account.network3.ai:8080/login_page"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            ;;

        2)
            echo -e "${BLUE}Обновление ноды Network3...${NC}"

            # Остановка сервиса, если он существует
            if [ -f "/etc/systemd/system/manager.service" ]; then
                echo -e "${BLUE}Останавливаем и удаляем сервис manager...${NC}"
                sudo systemctl stop manager 2>/dev/null || true
                sudo systemctl disable manager 2>/dev/null || true
                sudo rm /etc/systemd/system/manager.service
                sudo systemctl daemon-reload
            else
                echo -e "${GREEN}Сервис manager не существует. Пропускаем удаление.${NC}"
            fi

            # Скачивание и распаковка бинарника
            wget https://network3.io/ubuntu-node-v2.1.1.tar.gz
            if [ -f "ubuntu-node-v2.1.1.tar.gz" ]; then
                tar -xvf ubuntu-node-v2.1.1.tar.gz
                rm ubuntu-node-v2.1.1.tar.gz
            else
                echo -e "${RED}Ошибка: Файл ubuntu-node-v2.1.1.tar.gz не найден.${NC}"
                exit 1
            fi

            # Проверка и открытие порта 8080
            if ! sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
                echo -e "${BLUE}Открываем порт 8080 через iptables...${NC}"
                sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
                sudo iptables-save > /etc/iptables/rules.v4
            else
                echo -e "${GREEN}Порт 8080 уже открыт.${NC}"
            fi

            if sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
                echo -e "${GREEN}Правила уже сохранены.${NC}"
            else
                echo -e "${BLUE}Сохраняем правила...${NC}"
                sudo iptables-save > /etc/iptables/rules.v4
            fi

            # Запуск ноды
            cd ubuntu-node
            sudo bash manager.sh up
            cd

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Нода обновлена. Перейдите по ссылке, чтобы проверить её работу:${NC}"
            echo "http://account.network3.ai:8080/login_page"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo
            ;;

        3)
            echo -e "${BLUE}Получение ключа ноды...${NC}"
            cd ubuntu-node/
            sudo bash manager.sh key
            ;;

        4)
            echo -e "${BLUE}Удаление ноды Network3...${NC}"

            # Остановка сервиса, если он существует
            if [ -f "/etc/systemd/system/manager.service" ]; then
                echo -e "${BLUE}Останавливаем и удаляем сервис manager...${NC}"
                sudo systemctl stop manager 2>/dev/null || true
                sudo systemctl disable manager 2>/dev/null || true
                sudo rm /etc/systemd/system/manager.service
                sudo systemctl daemon-reload
            else
                echo -e "${GREEN}Сервис manager не существует. Пропускаем удаление.${NC}"
            fi

            # Удаление папки
            if [ -d "$HOME/ubuntu-node" ]; then
                rm -rf $HOME/ubuntu-node
                echo -e "${GREEN}Директория ноды удалена.${NC}"
            else
                echo -e "${RED}Директория ноды не найдена.${NC}"
            fi

            echo -e "${GREEN}Нода Network3 успешно удалена!${NC}"

            # Завершающий вывод
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac
