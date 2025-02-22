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
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Изменение комиссии${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"
echo -e "${CYAN}5) Проверка логов (выход из логов CTRL+C)${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду Hemi...${NC}"

        # Обновляем и устанавливаем необходимые пакеты
        sudo apt update && sudo apt upgrade -y
        sleep 1

        # Проверка и установка tar, если его нет
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi

        # Установка бинарника
        echo -e "${BLUE}Загружаем бинарник Hemi...${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.11.5/heminetwork_v0.11.5_linux_amd64.tar.gz

        # Создание директории и извлечение бинарника
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.11.5_linux_amd64.tar.gz -C hemi
        cd hemi

        # Создание tBTC кошелька
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

        # Вывод содержимого файла popm-address.json
        echo -e "${RED}Сохраните эти данные в надежное место:${NC}"
        cat ~/popm-address.json
        echo -e "${PURPLE}Ваш pubkey_hash — это ваш tBTC адрес, на который нужно запросить тестовые токены в Discord проекта.${NC}"

        echo -e "${YELLOW}Введите ваш приватный ключ от кошелька:${NC} "
        read PRIV_KEY
        echo -e "${YELLOW}Укажите желаемый размер комиссии (минимум 50):${NC} "
        read FEE

        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Определяем имя текущего пользователя и его домашнюю директорию
USERNAME=$(whoami)

if [ "$USERNAME" == "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$USERNAME"
fi

# Создаем или обновляем файл сервиса с использованием определенного имени пользователя и домашней директории
cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        # Обновление сервисов и включение hemi
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hemi
        sleep 1

        # Запуск ноды
        sudo systemctl start hemi

        # Заключительный вывод
        echo -e "${GREEN}Установка завершена и нода запущена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        ;;
    2)
        echo -e "${BLUE}Обновляем ноду Hemi...${NC}"

        # Находим все сессии screen, содержащие "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        # Если сессии найдены, удаляем их
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Сессии screen для ноды Hemi не найдены, начинаем обновление${NC}"
        fi

        # Проверка существования сервиса
        if systemctl list-units --type=service | grep -q "hemi.service"; then
            sudo systemctl stop hemi.service
            sudo systemctl disable hemi.service
            sudo rm /etc/systemd/system/hemi.service
            sudo systemctl daemon-reload
        else
            echo -e "${BLUE}Сервис hemi.service не найден, продолжаем обновление.${NC}"
        fi
        sleep 1

        # Удаление папки с бинарниками, содержащими "hemi" в названии
        echo -e "${BLUE}Удаляем старые файлы ноды...${NC}"
        rm -rf *hemi*

        # Установка бинарника
        echo -e "${BLUE}Загружаем бинарник Hemi...${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.11.5/heminetwork_v0.11.5_linux_amd64.tar.gz

        # Создание директории и извлечение бинарника
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.11.5_linux_amd64.tar.gz -C hemi
        cd hemi

        # Запрос приватного ключа и комиссии
        echo -e "${YELLOW}Введите ваш приватный ключ от кошелька:${NC} "
        read PRIV_KEY
        echo -e "${YELLOW}Укажите желаемый размер комиссии (минимум 50):${NC} "
        read FEE

        # Создание файла popmd.env
        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Определяем имя текущего пользователя и его домашнюю директорию
USERNAME=$(whoami)

if [ "$USERNAME" == "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$USERNAME"
fi

# Создаем или обновляем файл сервиса с использованием определенного имени пользователя и домашней директории
cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        # Обновление сервисов и включение hemi
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hemi
        sleep 1

        # Запуск ноды
        sudo systemctl start hemi

        # Заключительный вывод
        echo -e "${GREEN}Нода обновлена и запущена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        ;;
    3)
        echo -e "${YELLOW}Укажите новое значение комиссии (минимум 50):${NC}"
        read NEW_FEE

        # Проверка, что введенное значение не меньше 50
        if [ "$NEW_FEE" -ge 50 ]; then
            # Обновляем значение комиссии в файле popmd.env
            sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" $HOME/hemi/popmd.env
            sleep 1

            # Перезапуск сервиса Hemi
            sudo systemctl restart hemi

            echo -e "${GREEN}Значение комиссии успешно изменено!${NC}"

            # Завершающий вывод
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для проверки логов:${NC}" 
            echo "sudo journalctl -u hemi -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        else
            echo -e "${RED}Ошибка: комиссия должна быть не меньше 50!${NC}"
        fi
        ;;

    4)
        echo -e "${BLUE}Удаление ноды Hemi...${NC}"

        # Находим все сессии screen, содержащие "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        # Если сессии найдены, удаляем их
        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершение сессий screen с идентификаторами: $SESSION_IDS${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Сессии screen для ноды Hemi не найдены, продолжаем удаление${NC}"
        fi

        # Остановка и удаление сервиса Hemi
        sudo systemctl stop hemi.service
        sudo systemctl disable hemi.service
        sudo rm /etc/systemd/system/hemi.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки с названием, содержащим "hemi"
        echo -e "${BLUE}Удаляем файлы ноды Hemi...${NC}"
        rm -rf *hemi*
        
        echo -e "${GREEN}Нода Hemi успешно удалена!${NC}"

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "sudo journalctl -u hemi -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        ;;
    5)
        sudo journalctl -u hemi -f
        ;;
        
esac
