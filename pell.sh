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
echo -e "${CYAN}3) Рестарт ноды${NC}"
echo -e "${CYAN}4) Проверка логов${NC}"
echo -e "${CYAN}5) Проверка синхронизации${NC}"
echo -e "${CYAN}6) Создание кошелька${NC}"
echo -e "${CYAN}7) Создание валидатора${NC}"
echo -e "${CYAN}8) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка ноды Pell...${NC}"

        # Обновление и установка пакетов
        sudo apt update && sudo apt upgrade -y
        sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

        # Установка Go
        cd $HOME
        VER="1.22.3"
        wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
        rm "go$VER.linux-amd64.tar.gz"
        [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
        echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
        source $HOME/.bash_profile
        [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

        # Запрос имени ноды и кошелька у пользователя
        echo -e "${YELLOW}Введите имя ноды:${NC}"
        read MONIKER
        echo -e "${YELLOW}Введите имя кошелька:${NC}"
        read WALLET

        # Сохранение в .bash_profile
        echo "export WALLET=$WALLET" >> $HOME/.bash_profile
        echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
        echo "export PELL_CHAIN_ID=ignite_186-1" >> $HOME/.bash_profile
        echo "export PELL_PORT=41" >> $HOME/.bash_profile
        source $HOME/.bash_profile

        # Загрузка бинарника
        cd $HOME
        wget -O pellcored https://github.com/0xPellNetwork/network-config/releases/download/v1.1.1-ignite/pellcored-v1.1.1-linux-amd64
        chmod +x pellcored
        mv pellcored ~/go/bin/

        # Установка WASMVM
        WASMVM_VERSION=v2.1.2
        export LD_LIBRARY_PATH=~/.pellcored/lib
        mkdir -p $LD_LIBRARY_PATH
        wget "https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so" -O "$LD_LIBRARY_PATH/libwasmvm.$(uname -m).so"
        echo "export LD_LIBRARY_PATH=$HOME/.pellcored/lib:$LD_LIBRARY_PATH" >> $HOME/.bash_profile
        source ~/.bash_profile

        # Инициализация ноды
        pellcored config node tcp://localhost:${PELL_PORT}657
        pellcored config keyring-backend os
        pellcored config chain-id ignite_186-1
        pellcored init "$MONIKER" --chain-id ignite_186-1

        # Загрузка genesis и addrbook
        wget -O $HOME/.pellcored/config/genesis.json https://server-5.itrocket.net/testnet/pell/genesis.json
        wget -O $HOME/.pellcored/config/addrbook.json https://server-5.itrocket.net/testnet/pell/addrbook.json

        # Настройка сидов и пиров
        SEEDS="5f10959cc96b5b7f9e08b9720d9a8530c3d08d19@pell-testnet-seed.itrocket.net:58656"
        PEERS="d003cb808ae91bad032bb94d19c922fe094d8556@pell-testnet-peer.itrocket.net:58656"
        sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
               -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.pellcored/config/config.toml

        # Установка кастомных портов
        sed -i.bak -e "s%:1317%:${PELL_PORT}317%g; s%:8080%:${PELL_PORT}080%g; s%:9090%:${PELL_PORT}090%g; s%:9091%:${PELL_PORT}091%g; s%:8545%:${PELL_PORT}545%g; s%:26657%:${PELL_PORT}657%g" $HOME/.pellcored/config/app.toml

        # Создание и запуск сервиса
        sudo tee /etc/systemd/system/pellcored.service > /dev/null <<EOF
[Unit]
Description=Pell node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.pellcored
ExecStart=$(which pellcored) start --home $HOME/.pellcored
Environment=LD_LIBRARY_PATH=$HOME/.pellcored/lib/
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable pellcored
        cp $HOME/.pellcored/data/priv_validator_state.json $HOME/.pellcored/priv_validator_state.json.backup
        rm -rf $HOME/.pellcored/data
        curl https://server-5.itrocket.net/testnet/pell/pell_2024-12-27_307890_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.pellcored
        mv $HOME/.pellcored/priv_validator_state.json.backup $HOME/.pellcored/data/priv_validator_state.json
        sudo systemctl restart pellcored
        
        echo -e "${GREEN}Установка ноды завершена!${NC}"
        # Завершающий вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}" 
        echo "sudo journalctl -u pellcored -f --no-hostname -o cat"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        sudo journalctl -u pellcored -f --no-hostname -o cat
        ;;
    2)
        echo -e "${GREEN}У вас актуальная версия ноды!${NC}"
        ;;
    3)
        sudo systemctl restart pellcored && sudo journalctl -u pellcored -f --no-hostname -o cat
        ;;
    4)
        sudo journalctl -u pellcored -f --no-hostname -o cat
        ;;
    5)
        rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.pellcored/config/config.toml" | cut -d ':' -f 3)
        while true; do
            local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
            network_height=$(curl -s https://pell-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height')

            if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Ошибка: Некорректные данные о высоте блоков. Повтор через 5 секунд...${NC}"
                sleep 5
                continue
            fi

            blocks_left=$((network_height - local_height))
            echo -e "${YELLOW}Высота ноды:${CYAN} $local_height${NC} ${YELLOW}| Высота сети:${CYAN} $network_height${NC} ${YELLOW}| Осталось блоков:${RED} $blocks_left${NC}"
            sleep 5
        done
        ;;
    6)
        echo -e "${YELLOW}Проверка синхронизации...${NC}"
        rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.pellcored/config/config.toml" | cut -d ':' -f 3)
        local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.catching_up')
        if [ "$local_height" == "true" ]; then
            echo -e "${RED}Нода не синхронизирована. Создавать кошелек необходимо после полной синхронизации.${NC}"
            exit 1
        fi

        pellcored keys add $WALLET
        WALLET_ADDRESS=$(pellcored keys show $WALLET -a)
        VALOPER_ADDRESS=$(pellcored keys show $WALLET --bech val -a)
        echo "export WALLET_ADDRESS=$WALLET_ADDRESS" >> $HOME/.bash_profile
        echo "export VALOPER_ADDRESS=$VALOPER_ADDRESS" >> $HOME/.bash_profile
        source $HOME/.bash_profile
        ;;
    7)
        echo -e "${BLUE}Создание валидатора...${NC}"
        pellcored tx staking create-validator \
          --amount 1000000apell \
          --commission-max-change-rate "0.05" \
          --commission-max-rate "0.10" \
          --commission-rate "0.05" \
          --min-self-delegation "1" \
          --pubkey=$(pellcored tendermint show-validator) \
          --moniker "$MONIKER" \
          --chain-id ignite_186-1 \
          --node https://pell-t-rpc.noders.services:443 --fees 500000000apell \
          --from $WALLET
          --yes

        ;;
    8)
        sudo systemctl stop pellcored
        sudo systemctl disable pellcored
        sudo rm -rf /etc/systemd/system/pellcored.service
        sudo rm $(which pellcored)
        sudo rm -rf $HOME/.pellcored
        sed -i "/PELL_/d" $HOME/.bash_profile
        echo -e "${GREEN}Нода Pell успешно удалена!${NC}"
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 8.${NC}"
        ;;
esac
