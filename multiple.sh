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
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Проверка статуса ноды${NC}"
echo -e "${CYAN}3) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду...${NC}"

        # Обновление и установка зависимостей
        sudo apt update && sudo apt upgrade -y

        # Проверка архитектуры системы и выбор подходящего клиента
        echo -e "${BLUE}Проверяем архитектуру системы...${NC}"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
        elif [[ "$ARCH" == "aarch64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
        else
            echo -e "${RED}Неподдерживаемая архитектура системы: $ARCH${NC}"
            exit 1
        fi

        # Скачиваем клиент
        echo -e "${BLUE}Скачиваем клиент с $CLIENT_URL...${NC}"
        wget $CLIENT_URL -O multipleforlinux.tar

        # Распаковываем архив
        echo -e "${BLUE}Распаковка файлов...${NC}"
        tar -xvf multipleforlinux.tar

        # Переход в папку клиента
        cd multipleforlinux

        # Выдача разрешений на выполнение
        echo -e "${BLUE}Выдача разрешений...${NC}"
        chmod +x ./multiple-cli
        chmod +x ./multiple-node

        # Добавление директории в системный PATH
        echo -e "${BLUE}Добавляем директорию в системный PATH...${NC}"
        echo "PATH=\$PATH:$(pwd)" >> ~/.bash_profile
        source ~/.bash_profile

        # Запуск ноды
        echo -e "${BLUE}Запускаем multiple-node...${NC}"
        nohup ./multiple-node > output.log 2>&1 &

        # Ввод Account ID и PIN
        echo -e "${YELLOW}Введите ваш Account ID:${NC}"
        read IDENTIFIER
        echo -e "${YELLOW}Установите ваш PIN:${NC}"
        read PIN

        # Привязка аккаунта
        echo -e "${BLUE}Привязываем аккаунт с ID: $IDENTIFIER и PIN: $PIN...${NC}"
        ./multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

        # Заключительный вывод
        echo -e "${GREEN}Установка завершена успешно!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки статуса ноды:${NC}"
        echo "cd ~/multipleforlinux && ./multiple-cli status"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    2)
        # Проверка логов
        echo -e "${BLUE}Проверяем статус...${NC}"
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    3)
        echo -e "${BLUE}Удаление ноды...${NC}"

        # Остановка процесса ноды
        pkill -f multiple-node

        # Удаление файлов ноды
        cd ~
        rm -rf multipleforlinux

        echo -e "${GREEN}Нода успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
        
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 3.${NC}"
        ;;
esac
