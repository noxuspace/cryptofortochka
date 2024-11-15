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
menu() {
    echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│              Параметры Меню Скрипта                 │${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}1) Установка зависимостей${NC}"
    echo -e "${CYAN}2) Ввод необходимых данных${NC}"
    echo -e "${CYAN}3) Развертывание контракта(ов)${NC}"
    echo -e "${CYAN}4) Выход${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────┘${NC}"

    echo -e "${YELLOW}Введите номер: ${NC}"
    read CHOICE

    case $CHOICE in
        1)
            install_dependencies
            ;;
        2)
            input_required_details
            ;;
        3)
            deploy_multiple_contracts
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac
}

show() {
    case $2 in
        "error")
            echo -e "${RED}❌ $1${NC}"
            ;;
        "progress")
            echo -e "${BLUE}⏳ $1${NC}"
            ;;
        *)
            echo -e "${GREEN}✅ $1${NC}"
            ;;
    esac
}

install_dependencies() {
    CONTRACT_NAME="ZunXBT"

    if [ ! -d ".git" ]; then
        show "Инициализация Git репозитория..." "progress"
        git init
    fi

    if ! command -v forge &> /dev/null; then
        show "Foundry не установлен. Устанавливаю..." "progress"
        source <(wget -O - https://raw.githubusercontent.com/zunxbt/installation/main/foundry.sh)
    fi

    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        show "Установка OpenZeppelin Contracts..." "progress"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        show "OpenZeppelin Contracts уже установлены."
    fi
}

input_required_details() {
    echo -e "-----------------------------------"
    if [ -f "$SCRIPT_DIR/token_deployment/.env" ]; then
        rm "$SCRIPT_DIR/token_deployment/.env"
    fi

    echo -e "${YELLOW}Введите ваш приватный ключ: ${NC}"
    read PRIVATE_KEY
    echo -e "${YELLOW}Введите имя токена (например, Zun Token): ${NC}"
    read TOKEN_NAME
    echo -e "${YELLOW}Введите символ токена (например, ZUN): ${NC}"
    read TOKEN_SYMBOL
    echo -e "${YELLOW}Введите URL RPC сети: ${NC}"
    read RPC_URL

    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
EOL

    source "$SCRIPT_DIR/token_deployment/.env"
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
rpc_url = "$RPC_URL"
EOL
    show "Файлы обновлены с вашими данными"
}

deploy_contract() {
    echo -e "-----------------------------------"
    source "$SCRIPT_DIR/token_deployment/.env"

    local contract_number=$1

    mkdir -p "$SCRIPT_DIR/src"

    cat <<EOL > "$SCRIPT_DIR/src/ZunXBT.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZunXBT is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 100000 * (10 ** decimals()));
    }
}
EOL

    show "Компиляция контракта $contract_number..." "progress"
    forge build

    if [[ $? -ne 0 ]]; then
        show "Компиляция контракта $contract_number не удалась." "error"
        exit 1
    fi

    show "Развертывание контракта ERC20 $contract_number..." "progress"
    DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/ZunXBT.sol:ZunXBT" \
        --rpc-url rpc_url \
        --private-key "$PRIVATE_KEY")

    if [[ $? -ne 0 ]]; then
        show "Развертывание контракта $contract_number не удалось." "error"
        exit 1
    fi

    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
    show "Контракт $contract_number успешно развернут по адресу: $CONTRACT_ADDRESS"
}

deploy_multiple_contracts() {
    echo -e "-----------------------------------"
    echo -e "${YELLOW}Сколько контрактов вы хотите развернуть? ${NC}"
    read NUM_CONTRACTS
    if [[ $NUM_CONTRACTS -lt 1 ]]; then
        show "Неверное количество контрактов." "error"
        exit 1
    fi

    ORIGINAL_TOKEN_NAME=$TOKEN_NAME

    for (( i=1; i<=NUM_CONTRACTS; i++ ))
    do
        if [[ $i -gt 1 ]]; then
            RANDOM_SUFFIX=$(head /dev/urandom | tr -dc A-Z | head -c 2)
            TOKEN_NAME="${RANDOM_SUFFIX}${ORIGINAL_TOKEN_NAME}"
        else
            TOKEN_NAME=$ORIGINAL_TOKEN_NAME
        fi
        deploy_contract "$i"
        echo -e "-----------------------------------"
    done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

while true; do
    menu
done
