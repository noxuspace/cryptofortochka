#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
echo -e "${CYAN}1) Установка ноды Hyperspace${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Ввывод ключей ноды${NC}"
echo -e "${CYAN}4) Проверка логов${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${CYAN}Начинаем установку ноды Hyperspace...${NC}"

        # Обновление системы и установка зависимостей
        sudo apt update && sudo apt upgrade -y
        sudo apt install mc wget git htop netcat net-tools unzip jq git build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen -y
        
        # Проверка, установлен ли Rust
        if ! command -v rustc &>/dev/null; then
            echo "Rust не найден, начинаем установку..."
            sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
            source $HOME/.cargo/env
            sleep 3
        else
            echo "Rust уже установлен, пропускаем установку."
        fi

        response=$(curl -s "https://api.github.com/repos/hyperspaceai/aios-cli/releases/latest")

        # Check if the response contains a rate limit error
        if echo "$response" | grep -q "API rate limit exceeded"; then
            echo "Введите Гитхаб токен"
            read GITHUB_TOKEN
        
            curl -o install_script.sh https://download.hyper.space/api/install
            chmod +x install_script.sh
            sed -i "s|curl|curl -H \"Authorization: token $GITHUB_TOKEN\"|" install_script.sh
            bash install_script.sh --verbose
            rm install_script.sh
        else
            curl https://download.hyper.space/api/install --verbose | bash
        fi
        
        source $HOME/.bashrc

        # Проверка наличия директории
        if [[ ! -d "$HOME/.aios" ]]; then
            echo -e "${RED}Сервера Hyperspace недоступны, установка ноды прервана. Попробуйте установить ноду позже!${NC}"
            exit 1  # Завершение скрипта с кодом 1
        fi

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)
        
        sudo tee /etc/systemd/system/aios.service > /dev/null << EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo tee $HOME/.aios/private_key.pem > /dev/null << EOF
$PRIVATE_KEY
EOF

        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable aios
        sudo systemctl start aios
        
        end_time=$((SECONDS + 60))
        
        journalctl -n 100 -f -u aios -o cat | while read line; do
            if [[ "$line" == *"Authenticated successfully"* ]]; then
                echo -e "${BLUE}Начинаем настройку ноды...${NC}"
        
                $HOME/.aios/aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
                $HOME/.aios/aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf
        
                sudo systemctl restart aios
        
                $HOME/.aios/aios-cli hive whoami
                break
            fi
            
            if [[ SECONDS -ge end_time ]]; then
                echo -e "${RED}Сервера Hyperspace недоступны, установка ноды прервана. Попробуйте установить ноду позже!${NC}"
                systemctl stop aios
                systemctl disable aios
                rm -rf /etc/systemd/system/aios.service
                rm -rf $HOME/.aios
                rm -rf $HOME/.cache/hyperspace
                rm -rf $HOME/.config/hyperspace
                
                exit 1
            fi
        done

        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "journalctl -n 100 -f -u aios -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2     
        ;;

    2)
        echo -e "${GREEN}У вас актуальная версия ноды Hyperspace.${NC}"
        ;;

    3)
        echo -e "${CYAN}Ввывод ключей ноды...${NC}"
        \$HOME/.aios/aios-cli hive whoami
        ;;

    4)
        echo -e "${CYAN}Просмотр логов...${NC}"
        journalctl -n 100 -f -u aios -o cat
        ;;

    5)
        echo -e "${RED}Удаляем ноду Hyperspace...${NC}"
        systemctl stop aios
        systemctl disable aios
        sleep 2
        rm -rf /etc/systemd/system/aios.service
        rm -rf $HOME/.aios
        rm -rf $HOME/.cache/hyperspace
        rm -rf $HOME/.config/hyperspace
        sudo systemctl daemon-reload
        sleep 2
        echo -e "${GREEN}Нода успешно удалена.${NC}"
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
