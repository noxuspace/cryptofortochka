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
    echo -e "${CYAN}1) Установка бота${NC}"
    echo -e "${CYAN}2) Обновление бота${NC}"
    echo -e "${CYAN}3) Просмотр логов${NC}"
    echo -e "${CYAN}4) Рестарт бота${NC}"
    echo -e "${CYAN}5) Заменить на свои вопросы${NC}"
    echo -e "${CYAN}6) Удаление бота${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Установка бота...${NC}"

            # --- 1. Обновление системы и установка необходимых пакетов ---
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y python3 python3-venv python3-pip curl
            
            # --- 2. Создание папки проекта ---
            PROJECT_DIR="$HOME/nous"
            mkdir -p "$PROJECT_DIR"
            cd "$PROJECT_DIR" || exit 1
            
            # --- 3. Создание виртуального окружения и установка зависимостей ---
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install requests
            deactivate
            cd
            
            # --- 4. Скачивание файла hyper_bot.py ---
            BOT_URL="https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/nous/nous_bot.py"
            curl -fsSL -o nous/nous_bot.py "$BOT_URL"

            # --- 5. Запрос API-ключа и его замена в hyper_bot.py ---
            echo -e "${YELLOW}Введите ваш API-ключ для Nous:${NC}"
            read USER_API_KEY
            # Заменяем $API_KEY (в строке) на введённое значение. Предполагается, что в файле строка выглядит как:
            # NOUS_API_KEY = "$API_KEY"
            sed -i "s/NOUS_API_KEY = \"\$API_KEY\"/NOUS_API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/nous_bot.py"
            
            # --- 6. Скачивание файла questions.txt ---
            QUESTIONS_URL="https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/nous/questions.txt"
            curl -fsSL -o nous/questions.txt "$QUESTIONS_URL"

            # --- 7. Создание systemd сервиса ---
            # Определяем пользователя и домашнюю директорию
            USERNAME=$(whoami)
            HOME_DIR=$(eval echo ~$USERNAME)

            sudo bash -c "cat <<EOT > /etc/systemd/system/nous-bot.service
[Unit]
Description=Nous API Bot Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/nous
ExecStart=$HOME_DIR/nous/venv/bin/python $HOME_DIR/nous/nous_bot.py
Restart=always
Environment=PATH=$HOME_DIR/nous/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT"

            # --- 8. Обновление конфигурации systemd и запуск сервиса ---
            sudo systemctl daemon-reload
            sudo systemctl restart systemd-journald
            sudo systemctl enable nous-bot.service
            sudo systemctl start nous-bot.service
            
            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для проверки логов:${NC}"
            echo "sudo journalctl -u nous-bot.service -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 2
            sudo journalctl -u nous-bot.service -f
            ;;

        2)
            echo -e "${BLUE}Обновление бота...${NC}"
            sleep 2
            echo -e "${GREEN}Обновление бота не требуется!${NC}"
            ;;

        3)
            echo -e "${BLUE}Просмотр логов...${NC}"
            sudo journalctl -u nous-bot.service -f
            ;;

        4)
            echo -e "${BLUE}Рестарт бота...${NC}"
            sudo systemctl restart nous-bot.service
            sudo journalctl -u nous-bot.service -f
            ;;
        5)
            sudo systemctl stop nous-bot.service
            sleep 2
            QUESTIONS_FILE="$HOME/nous/questions.txt"

            # Очищаем содержимое файла
            > "$QUESTIONS_FILE"
            
            echo -e "${YELLOW}Вставьте ваши вопросы (каждая строка — отдельный вопрос)${NC}"
            echo -e "${RED}Когда закончите, нажмите Ctrl+D:${NC}"
            
            # Читаем все строки из STDIN и записываем в файл
            cat > "$QUESTIONS_FILE"

            sudo systemctl restart nous-bot.service
            sudo journalctl -u nous-bot.service -f           
            ;;
        6)
            echo -e "${BLUE}Удаление бота...${NC}"

            # Остановка и удаление сервиса
            sudo systemctl stop nous-bot.service
            sudo systemctl disable nous-bot.service
            sudo rm /etc/systemd/system/nous-bot.service
            sudo systemctl daemon-reload
            sleep 2
    
            # Удаление папки executor
            rm -rf $HOME_DIR/nous
    
            echo -e "${GREEN}Бот успешно удален!${NC}"
            # Завершающий вывод
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
            echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 6!${NC}"
            ;;
    esac
