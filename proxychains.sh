#!/bin/bash

# Цвета (с использованием $'…' для интерпретации ANSI-последовательностей)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'  # Сброс цвета

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Отображение логотипа
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

CONFIG_FILE="/etc/proxychains.conf"

# Функция для запроса данных прокси
prompt_proxy_details() {
    echo -e "${BLUE}Введите данные для настройки socks5-прокси:${NC}"
    read -p "${YELLOW}IP-адрес: ${NC}" PROXY_IP
    read -p "${YELLOW}Порт: ${NC}" PROXY_PORT
    read -p "${YELLOW}Логин (если есть, иначе Enter): ${NC}" PROXY_USER
    read -p "${YELLOW}Пароль (если есть, иначе Enter): ${NC}" PROXY_PASS
    # Формируем строку, предваряя её "socks5"
    echo "socks5 ${PROXY_IP} ${PROXY_PORT} ${PROXY_USER} ${PROXY_PASS}"
}

# Функция для комментария строки с socks4
comment_socks4() {
    sudo sed -i '/^socks4 / s/^/# /' "$CONFIG_FILE"
}

# Создаём резервную копию файла
sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Комментируем строки с socks4
comment_socks4

# Меню
echo -e "${CYAN}Выберите опцию:${NC}"
echo -e "${YELLOW}1) Старт (начальная настройка прокси)${NC}"
echo -e "${YELLOW}2) Замена прокси${NC}"

read -p "Введите номер опции:" choice

case $choice in
    1)
        # Если строка с socks5 уже существует, выводим сообщение
        if sudo grep -q "^socks5 " "$CONFIG_FILE"; then
            echo -e "${RED}Прокси уже настроен в файле. Если нужно заменить, выберите опцию 2 (Замена прокси).${NC}"
        else
            proxy_line=$(prompt_proxy_details)
            echo "$proxy_line" | sudo tee -a "$CONFIG_FILE" >/dev/null
            echo -e "${GREEN}Прокси успешно добавлен в $CONFIG_FILE.${NC}"
        fi

        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;
    2)
        # Удаляем все строки, начинающиеся с "socks5 "
        sudo sed -i '/^socks5 /d' "$CONFIG_FILE"
        echo -e "${BLUE}Старые строки прокси удалены.${NC}"
        proxy_line=$(prompt_proxy_details)
        echo "$proxy_line" | sudo tee -a "$CONFIG_FILE" >/dev/null
        echo -e "${GREEN}Прокси успешно заменён в $CONFIG_FILE.${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;
    *)
        echo -e "${RED}Неверный выбор. Выход.${NC}"
        exit 1
        ;;
esac
