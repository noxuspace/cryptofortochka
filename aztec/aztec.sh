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
echo -e "${CYAN}2) Получение роли${NC}"
echo -e "${CYAN}3) Регистрация валидатора${NC}"
echo -e "${CYAN}4) Обновление ноды${NC}"
echo -e "${CYAN}5) Просмотр логов${NC}"
echo -e "${CYAN}6) Рестарт ноды${NC}"
echo -e "${CYAN}7) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка зависимостей...${NC}"
        sudo apt-get update && sudo apt-get upgrade -y
        sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y
        
        # 1. Установка Docker, если не установлен
        if ! command -v docker &> /dev/null; then
          curl -fsSL https://get.docker.com -o get-docker.sh
          sh get-docker.sh
          sudo usermod -aG docker $USER
          rm get-docker.sh
        fi
        
        # 2. Создание группы docker, если её нет
        if ! getent group docker > /dev/null; then
          sudo groupadd docker
        fi
        
        # 3. Добавление пользователя в группу docker (на всякий случай ещё раз)
        sudo usermod -aG docker $USER
        
        # 4. Настройка прав на сокет
        if [ -S /var/run/docker.sock ]; then
          sudo chmod 666 /var/run/docker.sock
        else
          sudo systemctl start docker
          sudo chmod 666 /var/run/docker.sock
        fi

        # Проверка наличия iptables и установка, если отсутствует
        if ! command -v iptables &> /dev/null; then
          sudo apt-get update -y
          sudo apt-get install -y iptables
        fi

        sudo iptables -I INPUT -p tcp --dport 40400 -j ACCEPT
        sudo iptables -I INPUT -p udp --dport 40400 -j ACCEPT
        sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
        sudo sh -c "iptables-save > /etc/iptables/rules.v4"

        # 1) Создать папку и спросить у пользователя все параметры
        mkdir -p "$HOME/aztec-sequencer"
        cd "$HOME/aztec-sequencer"

        docker pull aztecprotocol/aztec:0.85.0-alpha-testnet.5
        
        read -p "Вставьте ваш URL RPC Sepolia: " RPC
        read -p "Вставьте ваш URL Beacon Sepolia: " CONSENSUS
        read -p "Вставьте приватный ключ от вашего кошелька (0x…): " PRIVATE_KEY
        read -p "Вставьте адрес вашего кошелька (0x…): " WALLET
        
        # Автоматически подтянем наружний IP сервера
        SERVER_IP=$(curl -s https://api.ipify.org)
        
        # 2) Записать всё это в файл .evm
        cat > .evm <<EOF
ETHEREUM_HOSTS=$RPC
L1_CONSENSUS_HOST_URLS=$CONSENSUS
VALIDATOR_PRIVATE_KEY=$PRIVATE_KEY
P2P_IP=$SERVER_IP
WALLET=$WALLET
EOF

        # 3) Запуск контейнера (разовый, с привязкой тома и env-файлом)
        docker run -d \
          --name aztec-sequencer \
          --network host \
          --env-file "$HOME/aztec-sequencer/.evm" \
          -e DATA_DIRECTORY=/data \
          -e LOG_LEVEL=debug \
          -v "$HOME/my-node/node":/data \
          aztecprotocol/aztec:0.85.0-alpha-testnet.5 \
          sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
            start --network alpha-testnet --node --archiver --sequencer'

        cd ~
        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "docker logs --tail 100 -f aztec-sequencer"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        docker logs --tail 100 -f aztec-sequencer     
        ;;
    2)
        curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/aztec/role.sh | bash
        ;;
    3)
    
        ;;
    4)
        echo -e "${GREEN}У вас актуальная версия ноды Aztec!${NC}"
        ;;
    5)
        docker logs --tail 100 -f aztec-sequencer
        ;;
    6)
        docker restart aztec-sequencer
        docker logs --tail 100 -f aztec-sequencer
        ;;
    7)
        echo -e "${BLUE}Удаление ноды Aztec...${NC}"
        docker stop aztec-sequencer
        docker rm aztec-sequencer

        rm -rf $HOME/aztec-sequencer
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
        ;;
esac


       
