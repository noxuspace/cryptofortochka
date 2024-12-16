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
echo -e "${CYAN}2) Проверка логов${NC}"
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
        sudo apt install -y screen net-tools

        # Скачиваем и распаковываем бинарник
        wget https://network3.io/ubuntu-node-v2.1.1.tar.gz
        if [ -f "ubuntu-node-v2.1.1.tar.gz" ]; then
            tar -xvf ubuntu-node-v2.1.1.tar.gz
            rm ubuntu-node-v2.1.1.tar.gz
            echo "Временный файл удалён."
        else
            echo -e "${RED}Ошибка: Файл ubuntu-node-v2.1.1.tar.gz не найден.${NC}"
            exit 1
        fi

        # Проверка наличия iptables
        if ! command -v iptables &> /dev/null; then
            echo "iptables не установлен. Устанавливаем..."
            sudo apt install -y iptables
        else
            echo "iptables уже установлен."
        fi

        # Проверка и открытие порта 8080
        if ! sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
            echo "Открываем порт 8080 через iptables..."
            sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
        else
            echo "Порт 8080 уже открыт."
        fi

        # Сохраняем правила, чтобы они работали после перезагрузки
        if command -v netfilter-persistent &> /dev/null; then
            echo "Сохраняем правила с помощью netfilter-persistent..."
            sudo netfilter-persistent save
            sudo netfilter-persistent reload
        else
            echo "Устанавливаем netfilter-persistent для сохранения правил..."
            export DEBIAN_FRONTEND=noninteractive
            sudo apt install -y iptables-persistent
            sudo netfilter-persistent save
            sudo netfilter-persistent reload
        fi

        echo "Порт 8080 успешно открыт и правило сохранено."

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Создаем сервис
        sudo bash -c "cat <<EOT > /etc/systemd/system/manager.service
[Unit]
Description=Manager Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/ubuntu-node/
ExecStart=/bin/bash $HOME_DIR/ubuntu-node/manager.sh up
ExecStop=/bin/bash $HOME_DIR/ubuntu-node/manager.sh down
Restart=always
Type=forking

[Install]
WantedBy=multi-user.target
EOT"

        # Запуск сервиса
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable manager
        sudo systemctl start manager

        # Проверка состояния сервиса
        if sudo systemctl is-active --quiet manager; then
            echo -e "${GREEN}Сервис успешно запущен!${NC}"
        else
            echo -e "${RED}Ошибка запуска сервиса. Проверьте логи командой:${NC}"
            echo "sudo journalctl -xe"
            exit 1
        fi

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -fu manager.service"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sudo journalctl -fu manager.service
        ;;
        
    2)
        # Проверка логов
        sudo journalctl -fu manager.service
        ;;
    3)
        echo -e "${BLUE}Получение ключа ноды...${NC}"
        cd ubuntu-node/
        sudo bash manager.sh key
        ;;
    4)
        echo -e "${BLUE}Удаление ноды Network3...${NC}"

        # Остановка и удаление сервиса
        sudo systemctl stop manager
        sudo systemctl disable manager
        sudo rm /etc/systemd/system/manager.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки
        if [ -d "$HOME/ubuntu-node" ]; then
            rm -rf $HOME/ubuntu-node
            echo "Директория ноды удалена."
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
