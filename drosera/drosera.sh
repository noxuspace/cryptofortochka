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
echo -e "${CYAN}1) Установка зависимостей${NC}"
echo -e "${CYAN}2) Деплой Trap${NC}"
echo -e "${CYAN}3) Установка ноды${NC}"
echo -e "${CYAN}4) Запуск ноды${NC}"
echo -e "${CYAN}5) Обновление ноды${NC}"
echo -e "${CYAN}6) Просмотр логов ноды${NC}"
echo -e "${CYAN}7) Перезапуск ноды${NC}"
echo -e "${CYAN}8) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка зависимостей...${NC}"
        sudo apt-get update && sudo apt-get upgrade -y
        sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev  -y

        curl -L https://app.drosera.io/install | bash
        curl -L https://foundry.paradigm.xyz | bash
        curl -fsSL https://bun.sh/install | bash
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2      
        ;;
    2)
        echo -e "${BLUE}Деплой Trap...${NC}"
        droseraup
        foundryup

        mkdir my-drosera-trap
        cd my-drosera-trap

        # Запрос Email
        read -p "${YELLOW}Введите вашу Github почту:${NC}" GITHUB_EMAIL
        # Запрос Username
        read -p "${YELLOW}Введите ваш Github юзернейм:${NC}" GITHUB_USERNAME
        
        # Применяем настройки git
        git config --global user.email "$GITHUB_EMAIL"
        git config --global user.name "$GITHUB_USERNAME"

        forge init -t drosera-network/trap-foundry-template

        bun install
        forge build

        # Запрос приватного ключа от EVM-кошелька
        read -p "${YELLOW}Введите ваш приватный ключ от EVM кошелька: ${NC}" PRIV_KEY
        
        # Устанавливаем переменную окружения
        export DROSERA_PRIVATE_KEY="$PRIV_KEY"
        
        # Выполняем команду drosera apply с подставленным ключом
        drosera apply
      
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        ;;
    3)
        echo -e "${BLUE}Установка ноды...${NC}"
        # Путь к файлу drosera.toml
        TARGET_FILE="$HOME/my-drosera-trap/drosera.toml"
        
        # Запрос адреса EVM кошелька у пользователя
        read -p "${YELLOW}Введите адрес вашего EVM кошелька:${NC}" WALLET_ADDRESS
        
        # Добавление строк в конец файла
        echo "private_trap = true" >> "$TARGET_FILE"
        echo "whitelist = [\"$WALLET_ADDRESS\"]" >> "$TARGET_FILE"


        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        ;;
    4)
        echo -e "${BLUE}Запуск ноды...${NC}"
        cd ~

        curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
        tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
               
        sudo cp drosera-operator /usr/bin

        drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $DROSERA_PRIVATE_KEY

        SERVER_IP=$(curl -s https://api.ipify.org)

        # Создаем сервисный файл, подставляя SERVER_IP и DROSERA_PRIVATE_KEY
        sudo bash -c "cat <<EOF > /etc/systemd/system/drosera.service
        [Unit]
        Description=drosera node service
        After=network-online.target
        
        [Service]
        User=$USER
        Restart=always
        RestartSec=15
        LimitNOFILE=65535
        ExecStart=$(which drosera-operator) node --db-file-path \$HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \\
            --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \\
            --eth-backup-rpc-url https://1rpc.io/holesky \\
            --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \\
            --eth-private-key $DROSERA_PRIVATE_KEY \\
            --listen-address 0.0.0.0 \\
            --network-external-p2p-address $SERVER_IP \\
            --disable-dnr-confirmation true
        
        [Install]
        WantedBy=multi-user.target
        EOF"

        sudo systemctl daemon-reload
        sudo systemctl enable drosera
        sudo systemctl start drosera
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "journalctl -u drosera.service -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        journalctl -u drosera.service -f
        ;;
    5)
        echo -e "${GREEN}У вас актуальная версия ноды Drosera!${NC}"
        ;;
    6)
        journalctl -u drosera.service -f
        ;;
    7)
        sudo systemctl restart drosera && journalctl -u drosera.service -f
        ;;
    8)
        echo -e "${BLUE}Удаление ноды Drosera...${NC}"

        # Остановка и удаление сервиса Hemi
        sudo systemctl stop drosera.service
        sudo systemctl disable drosera.service
        sudo rm /etc/systemd/system/drosera.service
        sudo systemctl daemon-reload
        sleep 1

        # Удаление папки с названием, содержащим "hemi"
        echo -e "${BLUE}Удаляем файлы ноды Drosera...${NC}"
        rm -rf my-drosera-trap
        
        echo -e "${GREEN}Нода Drosera успешно удалена!${NC}"
        
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


       
