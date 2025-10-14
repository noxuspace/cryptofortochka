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
    echo -e "${CYAN}1) Запуск RPC${NC}"
    echo -e "${CYAN}2) Удаление RPC${NC}"

    echo -e "${YELLOW}Введите номер:${NC} "
    read choice

    case $choice in
        1)
            sudo apt update -y
            sudo apt install mc wget curl git htop netcat-openbsd net-tools unzip jq build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler bc lz4 screen -y

            sudo apt update
            sudo apt install ufw -y
            sudo ufw allow 22:65535/tcp
            sudo ufw allow 22:65535/udp
            sudo ufw deny out from any to 10.0.0.0/8
            #sudo ufw deny out from any to 172.16.0.0/12
            sudo ufw deny out from any to 192.168.0.0/16
            sudo ufw deny out from any to 100.64.0.0/10
            sudo ufw deny out from any to 198.18.0.0/15
            sudo ufw deny out from any to 169.254.0.0/16
            sudo ufw --force enable

            curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/docker/docker_main.sh | bash &>/dev/null

            if ! id "geth_sepolia" &>/dev/null; then
                useradd -s /bin/bash -m geth_sepolia
                sudo usermod -aG sudo geth_sepolia
                sudo usermod -aG docker geth_sepolia
                sudo passwd geth_sepolia    
            else
                echo "User 'geth_sepolia' already exists."
            fi
            
            if [ ! -d "/home/geth_sepolia/eth-docker" ]; then
                    sudo -u geth_sepolia git clone https://github.com/eth-educators/eth-docker.git /home/geth_sepolia/eth-docker
                else
                    echo "Directory '/home/geth_sepolia/eth-docker' already exists."
            fi
            
            
            sudo -u geth_sepolia cp /home/geth_sepolia/eth-docker/default.env /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/COMPOSE_FILE=.*/COMPOSE_FILE=teku-cl-only.yml:geth.yml:grafana.yml:grafana-shared.yml:el-shared.yml/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/EL_P2P_PORT=.*/EL_P2P_PORT=50303/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/CL_P2P_PORT=.*/CL_P2P_PORT=59000/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/CL_QUIC_PORT=.*/CL_QUIC_PORT=59001/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/GRAFANA_PORT=.*/GRAFANA_PORT=53000/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/EL_RPC_PORT=.*/EL_RPC_PORT=58545/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/EL_WS_PORT=.*/EL_WS_PORT=58546/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/NETWORK=.*/NETWORK=sepolia/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/CHECKPOINT_SYNC_URL=.*/CHECKPOINT_SYNC_URL=\"https:\/\/checkpoint-sync.sepolia.ethpandaops.io\"/g' /home/geth_sepolia/eth-docker/.env
            sudo -u geth_sepolia sed -i 's/FEE_RECIPIENT=.*/FEE_RECIPIENT=0xd9264738573E25CB9149de0708b36527d56B59bd/g' /home/geth_sepolia/eth-docker/.env

            # >>> ДОБАВЛЕНО ДЛЯ FUSAKA (Teku supernode) <<<
            sudo -u geth_sepolia sed -i 's|^CL_EXTRAS=.*|CL_EXTRAS=--p2p-subscribe-all-custody-subnets-enabled|; t; $aCL_EXTRAS=--p2p-subscribe-all-custody-subnets-enabled' /home/geth_sepolia/eth-docker/.env
            # >>> КОНЕЦ ДОБАВЛЕНИЯ <<<
            
            export COMPOSE_PROJECT_NAME=sepolia

            # Важно: на свежей установке подтянуть последние образы перед запуском
            sudo -u geth_sepolia /home/geth_sepolia/eth-docker/ethd update
    
            # Первый запуск всего стека
            sudo -u geth_sepolia /home/geth_sepolia/eth-docker/ethd up
            ;;
            
        2)
            sudo -u geth_sepolia /home/geth_sepolia/eth-docker/ethd down -v
            rm -rf /home/geth_sepolia
            sudo deluser --remove-home geth_sepolia
            ;;


        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 2!${NC}"
            ;;
    esac
