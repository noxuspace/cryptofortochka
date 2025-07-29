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
        sudo apt install iptables-persistent
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

        sudo apt update
        sudo apt install -y iptables-persistent

        sudo iptables -I INPUT -p tcp --dport 40400 -j ACCEPT
        sudo iptables -I INPUT -p udp --dport 40400 -j ACCEPT
        sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
        sudo sh -c "iptables-save > /etc/iptables/rules.v4"

        # 1) Создать папку и спросить у пользователя все параметры
        mkdir -p "$HOME/aztec-sequencer"
        cd "$HOME/aztec-sequencer"

        docker pull aztecprotocol/aztec:1.2.0
        
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
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef
EOF

        # 3) Запуск контейнера (разовый, с привязкой тома и env-файлом)
        docker run -d \
          --name aztec-sequencer \
          --network host \
          --env-file "$HOME/aztec-sequencer/.evm" \
          -e DATA_DIRECTORY=/data \
          -e LOG_LEVEL=debug \
          -v "$HOME/my-node/node":/data \
          --entrypoint /bin/sh \
          aztecprotocol/aztec:1.2.0 \
          -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
            start --network alpha-testnet --node --archiver --sequencer \
            --sequencer.validatorPrivateKeys \"\$VALIDATOR_PRIVATE_KEY\" \
            --l1-rpc-urls \"\$ETHEREUM_HOSTS\" \
            --l1-consensus-host-urls \"\$L1_CONSENSUS_HOST_URLS\" \
            --sequencer.coinbase \"\$WALLET\" \
            --p2p.p2pIp \"\$P2P_IP\""

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
        # создаём временный файл
        tmpf=$(mktemp) && \
        # скачиваем role.sh в этот файл
        curl -fsSL https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/aztec/role.sh > "$tmpf" && \
        # исполняем его
        bash "$tmpf" && \
        # удаляем временный файл
        rm -f "$tmpf"
        ;;
    3)
        tmpf=$(mktemp) &&
        curl -fsSL https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/aztec/validator.sh >"$tmpf" &&
        bash "$tmpf" &&
        rm -f "$tmpf"
        ;;
    4)
        echo -e "${BLUE}Обновление ноды Aztec...${NC}"
        # 1) Подтягиваем новую версию образа
        docker pull aztecprotocol/aztec:1.2.0

        # 2) Останавливаем и удаляем старый контейнер (тома и .evm сохранятся)
        docker stop aztec-sequencer
        docker rm aztec-sequencer

        #rm -rf "$HOME/my-node/node/"*

        # 3) Запускаем контейнер заново с теми же параметрами, но новым тегом
        docker run -d \
          --name aztec-sequencer \
          --network host \
          --env-file "$HOME/aztec-sequencer/.evm" \
          -e DATA_DIRECTORY=/data \
          -e LOG_LEVEL=debug \
          -v "$HOME/my-node/node":/data \
          --entrypoint /bin/sh \
          aztecprotocol/aztec:1.2.0 \
          -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
            start --network alpha-testnet --node --archiver --sequencer \
            --sequencer.validatorPrivateKeys \"\$VALIDATOR_PRIVATE_KEY\" \
            --l1-rpc-urls \"\$ETHEREUM_HOSTS\" \
            --l1-consensus-host-urls \"\$L1_CONSENSUS_HOST_URLS\" \
            --sequencer.coinbase \"\$WALLET\" \
            --p2p.p2pIp \"\$P2P_IP\""

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

        rm -rf "$HOME/my-node/node/"*
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
