#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Функция логирования
log() {
    echo -e "${BLUE}$1${NC}"
}

# Функция отображения успеха
success() {
    echo -e "${GREEN}$1${NC}"
}

# Функция отображения ошибки
error() {
    echo -e "${RED}$1${NC}"
    exit 1
}

# Функция отображения предупреждения
warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Функция проверки статуса выполнения команды
check_error() {
    if [ "$?" -ne 0 ]; then
        error "$1"
    fi
}

# Функция просмотра логов
show_logs() {
    sudo journalctl -u vana.service -f
}

# Функция установки базовых зависимостей
install_base_dependencies() {
    log "Обновление и установка зависимостей..."
    
    # Обновление системы
    log "Обновление системы..."
    sudo apt update && sudo apt upgrade -y
    check_error "Ошибка обновления системы"
    success "Система успешно обновлена"
    
    # Git
    sudo apt-get install git -y
    check_error "Ошибка установки Git"
    
    # Unzip
    sudo apt install unzip -y
    check_error "Ошибка установки Unzip"
    
    # Nano
    sudo apt install nano -y
    check_error "Ошибка установки Nano"
    
    # Python зависимости
    log "Установка Python..."
    sudo apt install software-properties-common -y
    check_error "Ошибка установки software-properties-common"
    
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    check_error "Ошибка добавления репозитория Python"
    
    sudo apt update
    sudo apt install python3.11 -y
    check_error "Ошибка установки Python 3.11"
    
    # Проверка версии Python
    python_version=$(python3.11 --version)
    if [[ $python_version == *"3.11"* ]]; then
        success "Python версии $python_version установлен успешно"
    else
        error "Ошибка установки Python 3.11!"
    fi
    
    # Poetry
    log "Установка Poetry..."
    sudo apt install python3-pip python3-venv curl -y
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
    sleep 5
    source ~/.bashrc
    sleep 5
    if command -v poetry &> /dev/null; then
        success "Poetry успешно установлен: $(poetry --version)"
    else
        error "Ошибка установки Poetry"
    fi
     
    # Установка NVM
    log "Установка NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Загрузка NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Установка Node.js
    nvm install 22
    nvm use 22
    check_error "Ошибка установки Node.js"
    
    if command -v node &> /dev/null; then
        success "Node.js успешно установлен: $(node -v)"
        success "NPM успешно установлен: $(npm -v)"
    else
        error "Ошибка установки Node.js"
    fi
    
    # Yarn
    log "Установка Yarn..."
    npm install -g yarn
    if command -v yarn &> /dev/null; then
        success "Yarn успешно установлен: $(yarn --version)"
    else
        error "Ошибка установки Yarn"
    fi
    
    echo -e "${GREEN}Необходимые компоненты установлены${NC}"
    exit 0
}

# Функция установки ноды
install_node() {
    clear
    log "Установка ноды Vana..."
    
    # Клонирование репозитория
    if [ -d "vana-dlp-chatgpt" ]; then
        warning "Директория vana-dlp-chatgpt уже существует"
        read -p "Хотите удалить её и склонировать заново? (y/n): " choice
        if [[ $choice == "y" ]]; then
            rm -rf vana-dlp-chatgpt
        else
            error "Невозможно продолжить без чистого репозитория"
        fi
    fi
    
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    check_error "Ошибка клонирования репозитория"
    cd vana-dlp-chatgpt
    success "Репозиторий успешно склонирован"
    
    # Создание файла .env
    log "Создание файла .env..."
    cp .env.example .env
    check_error "Ошибка создания файла .env"
    success "Файл .env создан"
    
    # Установка зависимостей
    log "Установка зависимостей проекта..."
    poetry install
    check_error "Ошибка установки зависимостей проекта"
    success "Зависимости проекта установлены"
    
    # Установка CLI
    log "Установка Vana CLI..."
    pip install vana
    check_error "Ошибка установки Vana CLI"
    success "Vana CLI установлен"
    
    # Создание кошелька
    log "Создание кошелька..."
    vanacli wallet create --wallet.name default --wallet.hotkey default
    check_error "Ошибка создания кошелька"
    
    echo -e "${GREEN}Установка ноды завершена${NC}"
    exit 0
}

# Функция создания и развертывания DLP
create_and_deploy_dlp() {
    # Генерация ключей
    log "Генерация ключей..."
    cd $HOME/vana-dlp-chatgpt || error "Нет доступа к директории ноды"
    
    if [ ! -f "keygen.sh" ]; then
        error "keygen.sh не найден. Содержимое директории некорректно"
    fi
    
    chmod +x keygen.sh
    ./keygen.sh
    check_error "Ошибка генерации ключей"
    success "Ключи успешно сгенерированы"
    warning "Обязательно сохраните все 4 ключа:"
    echo "- public_key.asc и public_key_base64.asc"
    echo "- private_key.asc и private_key_base64.asc"

    # Остановка сервиса ноды если запущен
    log "Остановка сервиса vana..."
    if systemctl is-active --quiet vana.service; then
        sudo systemctl stop vana.service
        success "Сервис остановлен"
    else
        log "Активный сервис не найден, продолжаем..."
    fi

    # Настройка развертывания смарт-контракта
    log "Настройка развертывания смарт-контракта..."
    cd $HOME
    if [ -d "vana-dlp-smart-contracts" ]; then
        rm -rf vana-dlp-smart-contracts
    fi
    git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
    cd vana-dlp-smart-contracts || error "Нет доступа к директории смарт-контрактов"
    yarn install
    check_error "Ошибка установки зависимостей смарт-контракта"
    success "Зависимости смарт-контракта установлены"

    # Настройка окружения
    log "Настройка окружения..."
    cp .env.example .env
    check_error "Ошибка создания файла .env"
    
    echo -e "${YELLOW}Пожалуйста, предоставьте следующую информацию:${NC}"
    read -p "Введите приватный ключ coldkey (с префиксом 0x): " private_key
    read -p "Введите адрес кошелька coldkey (с префиксом 0x): " owner_address
    read -p "Введите название DLP (что-то придумайте): " dlp_name
    read -p "Введите название токена DLP (что-то придумайте): " token_name
    read -p "Введите символ токена DLP (что-то придумайте): " token_symbol

    # Обновление файла .env
    sed -i "s/^DEPLOYER_PRIVATE_KEY=.*/DEPLOYER_PRIVATE_KEY=$private_key/" .env
    sed -i "s/^OWNER_ADDRESS=.*/OWNER_ADDRESS=$owner_address/" .env
    sed -i "s/^DLP_NAME=.*/DLP_NAME=$dlp_name/" .env
    sed -i "s/^DLP_TOKEN_NAME=.*/DLP_TOKEN_NAME=$token_name/" .env
    sed -i "s/^DLP_TOKEN_SYMBOL=.*/DLP_TOKEN_SYMBOL=$token_symbol/" .env
    
    success "Окружение настроено"

    # Развертывание контракта
    log "Развертывание смарт-контракта..."
    warning "Убедитесь, что у вас есть тестовые токены в кошельках Coldkey и Hotkey перед продолжением"
    read -p "У вас есть тестовые токены и вы хотите продолжить развертывание? (y/n): " proceed
    
    if [[ $proceed == "y" ]]; then
        npx hardhat deploy --network moksha --tags DLPDeploy
        check_error "Ошибка развертывания контракта"
        success "Контракт успешно развернут"
        warning "ВАЖНО: Сохраните адреса DataLiquidityPoolToken и DataLiquidityPool из вывода выше!"
    else
        warning "Развертывание пропущено. Получите тестовые токены и запустите развертывание позже."
    fi
    
    echo -e "${GREEN}Процесс создания и развертывания DLP завершен!${NC}"
    exit 0
}

# Функция установки валидатора
install_validator() {
    
    log "Начало установки валидатора..."

    # Получение OpenAI API Key
    log "Настройка OpenAI API..."
    echo -e "${YELLOW}Введите ваш OpenAI API ключ:${NC}"
    read openai_key

    # Получение публичного ключа
    log "Получение публичного ключа..."
    if [ -f "/root/vana-dlp-chatgpt/public_key_base64.asc" ]; then
        public_key=$(cat /root/vana-dlp-chatgpt/public_key_base64.asc)
        success "Публичный ключ успешно получен"
        warning "Обязательно сохраните этот публичный ключ в надежном месте:"
        echo -e "${CYAN}$public_key${NC}"
        echo -e "${YELLOW}Нажмите Enter после сохранения публичного ключа...${NC}"
        read
    else
        error "Файл public_key_base64.asc не найден. Вы выполнили этап создания DLP?"
    fi

    # Настройка окружения
    log "Настройка окружения..."
    cd /root/vana-dlp-chatgpt || error "Директория vana-dlp-chatgpt не найдена"

    # Создание нового содержимого .env
    log "Создание файла конфигурации .env..."
    
    echo "# Используемая сеть, сейчас тестнет Vana Moksha" > .env
    echo "OD_CHAIN_NETWORK=moksha" >> .env
    echo "OD_CHAIN_NETWORK_ENDPOINT=https://rpc.moksha.vana.org" >> .env
    echo "" >> .env
    echo "# OpenAI API ключ для дополнительной проверки качества данных" >> .env
    echo "OPENAI_API_KEY=\"$openai_key\"" >> .env
    echo "" >> .env
    echo "# Адрес вашего DLP смарт-контракта" >> .env
    
    echo -e "${YELLOW}Введите адрес DataLiquidityPool:${NC}"
    read dlp_address
    echo "DLP_MOKSHA_CONTRACT=$dlp_address" >> .env
    echo "" >> .env
    
    echo -e "${YELLOW}Введите адрес DataLiquidityPoolToken:${NC}"
    read dlp_token_address
    echo "DLP_TOKEN_MOKSHA_CONTRACT=$dlp_token_address" >> .env
    echo "" >> .env
    
    echo "# Приватный ключ для DLP" >> .env
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=\"$public_key\"" >> .env

    success "Файл конфигурации успешно создан"    
    echo -e "${YELLOW}Установка валидатора успешно завершена!${NC}"
}

# Функция регистрации и запуска валидатора
register_and_start_validator() {
    
    log "Начало регистрации и настройки сервиса валидатора..."

    # Регистрация валидатора
    log "Регистрация валидатора..."
    cd /root/vana-dlp-chatgpt || error "Директория vana-dlp-chatgpt не найдена"
    
    ./vanacli dlp register_validator --stake_amount 10
    check_error "Ошибка регистрации валидатора"
    success "Регистрация валидатора успешно завершена"

    # Подтверждение валидатора
    log "Подтверждение валидатора..."
    echo -e "${YELLOW}Введите адрес вашего Hotkey кошелька:${NC}"
    read hotkey_address
    
    ./vanacli dlp approve_validator --validator_address="$hotkey_address"
    check_error "Ошибка подтверждения валидатора"
    success "Валидатор успешно подтвержден"

    # Тестирование валидатора
    log "Тестирование валидатора..."
    poetry run python -m chatgpt.nodes.validator
    success "Тестирование валидатора завершено"
    
    # Создание и запуск сервиса
    log "Настройка сервиса валидатора..."
    
    # Поиск пути к poetry
    log "Поиск пути к Poetry..."
    poetry_path=$(which poetry)
    if [ -z "$poetry_path" ]; then
        error "Poetry не найден в PATH"
    fi
    success "Poetry найден: $poetry_path"

    # Создание файла сервиса
    log "Создание файла сервиса..."
    sudo tee /etc/systemd/system/vana.service << EOF
[Unit]
Description=Сервис Vana Validator
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/vana-dlp-chatgpt
ExecStart=$poetry_path run python -m chatgpt.nodes.validator
Restart=on-failure
RestartSec=10
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin
Environment=PYTHONPATH=/root/vana-dlp-chatgpt

[Install]
WantedBy=multi-user.target
EOF
    check_error "Ошибка создания файла сервиса"
    success "Файл сервиса успешно создан"

    # Запуск сервиса
    log "Запуск сервиса валидатора..."
    sudo systemctl daemon-reload
    sudo systemctl enable vana.service
    sudo systemctl start vana.service
    
    # Проверка статуса сервиса
    service_status=$(sudo systemctl status vana.service)
    if [[ $service_status == *"active (running)"* ]]; then
        success "Сервис валидатора успешно запущен"
    else
        error "Ошибка запуска сервиса валидатора. Проверьте статус командой: sudo systemctl status vana.service"
    fi

    echo -e "${GREEN}Настройка валидатора успешно завершена!${NC}"
}

# Функция удаления ноды
remove_node() {
    log "Начало процесса удаления ноды..."

    # Остановка сервиса
    log "Остановка сервиса валидатора..."
    if systemctl is-active --quiet vana.service; then
        sudo systemctl stop vana.service
        sudo systemctl disable vana.service
        success "Сервис валидатора остановлен и отключен"
    else
        warning "Сервис валидатора не был запущен"
    fi

    # Удаление файла сервиса
    log "Удаление файла сервиса..."
    if [ -f "/etc/systemd/system/vana.service" ]; then
        sudo rm /etc/systemd/system/vana.service
        sudo systemctl daemon-reload
        success "Файл сервиса удален"
    else
        warning "Файл сервиса не найден"
    fi

    # Удаление директории ноды
    log "Удаление директорий ноды..."
    cd $HOME
    
    if [ -d "vana-dlp-chatgpt" ]; then
        rm -rf vana-dlp-chatgpt
        success "Директория vana-dlp-chatgpt удалена"
    else
        warning "Директория vana-dlp-chatgpt не найдена"
    fi
    
    if [ -d "vana-dlp-smart-contracts" ]; then
        rm -rf vana-dlp-smart-contracts
        success "Директория vana-dlp-smart-contracts удалена"
    else
        warning "Директория vana-dlp-smart-contracts не найдена"
    fi

    # Удаление директории .vana с конфигурацией
    log "Удаление файлов конфигурации..."
    if [ -d "$HOME/.vana" ]; then
        rm -rf $HOME/.vana
        success "Директория конфигурации .vana удалена"
    else
        warning "Директория конфигурации .vana не найдена"
    fi

    log "Удаление ноды завершено!"
}

# Функция отображения логотипа
show_logo() {
    # Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash
}

# Функция главного меню
show_menu() {
    show_logo
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo -e "${CYAN}1) Установка зависимостей${NC}"
    echo -e "${CYAN}2) Установка ноды${NC}"
    echo -e "${CYAN}3) Создание DLP${NC}"
    echo -e "${CYAN}4) Установка валидатора${NC}"
    echo -e "${CYAN}5) Запуск валидатора${NC}"
    echo -e "${CYAN}6) Просмотр логов валидатора${NC}"
    echo -e "${CYAN}7) Удаление ноды${NC}"
    
    read -p "Введите номер: " choice
    
    case $choice in
        1)
            install_base_dependencies
            show_menu
            ;;
        2)
            install_node
            show_menu
            ;;
        3)
            create_and_deploy_dlp
            show_menu
            ;;
        4)
            install_validator
            show_menu
            ;;
        5)
            register_and_start_validator
            show_menu
            ;;
        6)
            show_logs
            show_menu
            ;;
        7)
            remove_node
            show_menu
            ;;
        *)
            warning "Неверный выбор. Пожалуйста, выберите 1-7"
            ;;
    esac
}

# Запуск скрипта с отображения меню
show_menu
