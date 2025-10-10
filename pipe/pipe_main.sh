#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'  # Сброс цвета

set -euo pipefail

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Проверка версии Ubuntu
echo -e "${BLUE}Проверяем версию вашей OS...${NC}"

# Проверка наличия bc и установка при необходимости
if ! command -v bc &> /dev/null; then
    echo -e "${BLUE}Устанавливаем bc...${NC}"
    sudo apt update && sudo apt install -y bc
fi
sleep 1

UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=24.04

# Сравнение версий
if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}Для этой ноды требуется Ubuntu ${REQUIRED_VERSION} или выше!${NC}"
    echo -e "${PURPLE}У вас установлена версия: ${UBUNTU_VERSION}${NC}"
    exit 1
else
    echo -e "${GREEN}Версия Ubuntu подходит: ${UBUNTU_VERSION}${NC}"
fi

# Меню действий
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Просмотр логов${NC}"
echo -e "${CYAN}4) Рестарт ноды${NC}"
echo -e "${CYAN}5) Проверка здоровья ноды${NC}"
echo -e "${CYAN}6) Информация о ноде${NC}"
echo -e "${CYAN}7) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
  1)
    echo -e "${BLUE}Установка ноды Pipe (Mainnet)...${NC}"
    sudo apt-get update
    sudo apt install -y libssl-dev ca-certificates jq

    sudo apt update
    sudo apt install -y iptables-persistent
    
    # Создание рабочей директории
    cd /opt
    mkdir pipe && cd pipe

    curl -L https://pipe.network/p1-cdn/releases/latest/download/pop -o pop
    chmod +x pop

    # Требуется jq для парсинга JSON
    if ! command -v jq &>/dev/null; then
      echo -e "${BLUE}Устанавливаем jq...${NC}"
      sudo apt update && sudo apt install -y jq
    fi
    
    # ── Запрос параметров ───────────────────────────────────────────────────────────
    echo -e "${YELLOW}Введите адрес от кошелька Solana:${NC}"
    read -r SOLANA_PUBKEY
    
    echo -e "${YELLOW}Придумайте имя для ноды:${NC}"
    read -r POP_NODE
    
    echo -e "${YELLOW}Введите ваш email:${NC}"
    read -r EMAIL
    
    # RAM в МБ (только число)
    while true; do
      echo -e "${YELLOW}Введите объём оперативной памяти (только число в Mb, например, 512 или 1024 и т.п.):${NC}"
      read -r RAM_MB
      [[ "$RAM_MB" =~ ^[0-9]+$ ]] && break
      echo -e "${RED}Введите только число (МБ)!${NC}"
    done
    
    # Дисковый кеш в ГБ (только число)
    while true; do
      echo -e "${YELLOW}Введите максимальный размер кеша на диске (в Gb, например, 100 или 250):${NC}"
      read -r DISK_GB
      [[ "$DISK_GB" =~ ^[0-9]+$ ]] && break
      echo -e "${RED}Введите только число (ГБ).${NC}"
    done
    
    # ── Определение локации по IP ──────────────────────────────────────────────────
    response=$(curl -s http://ip-api.com/json || true)
    country=$(echo "$response" | jq -r '.country // empty')
    city=$(echo "$response" | jq -r '.city // empty')
    
    if [[ -n "$city" && -n "$country" ]]; then
      POP_LOCATION="$city, $country"
    else
      POP_LOCATION="Unknown"
    fi

    # Экранируем кавычки в строковых значениях для .env
    ESC_EMAIL=$(printf '%s' "$EMAIL" | sed 's/"/\\"/g')
    ESC_LOCATION=$(printf '%s' "$POP_LOCATION" | sed 's/"/\\"/g')
    
    # ── Запись .env (VPS: UPNP отключён) ───────────────────────────────────────────
    cat > /opt/pipe/.env <<EOF
    # Wallet for earnings
    NODE_SOLANA_PUBLIC_KEY=${SOLANA_PUBKEY}
    
    # Node identity
    NODE_NAME=${POP_NODE}
    NODE_EMAIL="${ESC_EMAIL}"
    NODE_LOCATION="${ESC_LOCATION}"
    
    # Cache configuration
    MEMORY_CACHE_SIZE_MB=${RAM_MB}
    DISK_CACHE_SIZE_GB=${DISK_GB}
    DISK_CACHE_PATH=./cache
    
    # Network ports
    HTTP_PORT=80
    HTTPS_PORT=443
    
    # Home network auto port forwarding (disable on VPS/servers)
    UPNP_ENABLED=false
EOF

    # Определяем имя текущего пользователя и его домашнюю директорию
    USERNAME=$(whoami)
    
    if [ "$USERNAME" == "root" ]; then
        HOME_DIR="/root"
    else
        HOME_DIR="/home/$USERNAME"
    fi

    sudo tee /etc/systemd/system/pipe.service > /dev/null <<EOF
[Unit]
Description=Pipe Network POP Node
After=network-online.target
Wants=network-online.target

[Service]
User=$USERNAME
WorkingDirectory=/opt/pipe
ExecStart=/bin/bash -c 'source /opt/pipe/.env && /opt/pipe/pop'
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF


    # Освобождение портов 80 и 443, если они заняты
    for PORT in 80 443; do
      if sudo ss -tulpen | awk '{print $5}' | grep -q ":$PORT\$"; then
        echo -e "${BLUE}🔒 Порт $PORT занят. Завершаем процесс...${NC}"
        sudo fuser -k ${PORT}/tcp
        sleep 2  # Дать ядру время отпустить сокет
        echo -e "${GREEN}✅ Порт $PORT должен быть освобождён.${NC}"
      else
        echo -e "${GREEN}✅ Порт $PORT уже свободен.${NC}"
      fi
    done

    # Проверяем, что unit-файл apache2.service есть в системе
    if systemctl list-unit-files --type=service | grep -q '^apache2\.service'; then
    
      # Если apache2 сейчас активен (запущен) — останавливаем его
      if systemctl is-active --quiet apache2; then
        sudo systemctl stop apache2
      fi
    
      # Если apache2 включён на автозапуск — отключаем его
      if systemctl is-enabled --quiet apache2; then
        sudo systemctl disable apache2
      fi
    
    fi
    
    # Настройка iptables
    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"

    sudo systemctl daemon-reload
    sudo systemctl enable pipe
    sudo systemctl start pipe
    cd $HOME
    
    # Завершающий вывод
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Команда для проверки логов:${NC}" 
    echo "sudo journalctl -u pipe -f"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    sleep 2
    sudo journalctl -u pipe -f
    ;;
  2)
    echo -e "${GREEN}У вас актуальная версия ноды!${NC}"
    ;;
  3)
    sudo journalctl -u pipe -f
    ;;
  4)
    sudo systemctl restart pipe && sudo journalctl -u pipe -f
    ;;
  5)
    curl http://localhost:8081/health
    ;;
  6)
    cd /opt/pipe
    ./pop status
    ./pop earnings
    cd $HOME
    ;;
  7)
    sudo systemctl stop pipe
    sudo systemctl disable pipe
    sudo rm /etc/systemd/system/pipe.service
    sudo systemctl daemon-reload
    sudo rm -rf /opt/pipe
    ;;
  *)
    echo -e "${RED}Неверный выбор${NC}"
    ;;
esac
