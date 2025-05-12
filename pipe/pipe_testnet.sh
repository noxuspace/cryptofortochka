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

# Меню действий
echo -e ${YELLOW}Выберите действие:${NC}
echo -e ${CYAN}1) Установка ноды Pipe (Testnet) через Docker${NC}
echo -e ${CYAN}2) Обновление ноды${NC}
echo -e ${CYAN}3) Просмотр логов${NC}
echo -e ${CYAN}4) Рестарт ноды${NC}
echo -e ${CYAN}5) Статус ноды${NC}
echo -e ${CYAN}6) Проверка здоровья ноды${NC}
echo -e ${CYAN}7) Удаление ноды${NC}

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
  1)
    echo -e "${BLUE}Установка ноды Pipe (Testnet)...${NC}"
    sudo apt-get update
    sudo apt install -y libssl-dev ca-certificates
    
    if ! command -v docker &> /dev/null; then
    sudo apt update && sudo apt install -y docker.io
    sudo usermod -aG docker "$USER"
    fi
    if ! command -v iptables &> /dev/null; then
        sudo apt update && sudo apt install -y iptables
    fi

    sudo apt update
    sudo apt install -y iptables-persistent
    
    # Создание рабочей директории
    mkdir -p "$HOME/pipe-node" && cd "$HOME/pipe-node"

    # Запрос параметров
    echo -e "${YELLOW}Введите ваш invite-код:${NC}"
    read INVITE
    
    echo -e "${YELLOW}Придумайте имя для ноды:${NC}"
    read POP_NAME
    
    echo -e "${YELLOW}Введите локацию сервера:${NC}"
    read POP_LOCATION
    
    echo -e "${YELLOW}Введите Telegram (telegram handle):${NC}"
    read TELEGRAM
    
    echo -e "${YELLOW}Введите Discord (username#0000):${NC}"
    read DISCORD
    
    echo -e "${YELLOW}Введите Email:${NC}"
    read EMAIL
    
    echo -e "${YELLOW}Введите Solana pubkey:${NC}"
    read SOLANA_PUBKEY
    
    echo -e "${YELLOW}Введите объём оперативной памяти (GB):${NC}"
    read RAM_GB
    
    echo -e "${YELLOW}Введите максимальный размер кеша на диске (GB):${NC}"
    read DISK_GB


    # Настройки ядра через sysctl
    sudo bash -c 'cat > /etc/sysctl.d/99-popcache.conf << EOL
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOL'
    sudo sysctl --system

    # Лимиты открытых файлов
    sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
*    hard nofile 65535
*    soft nofile 65535
EOL'

    # Создание папки кеша
    mkdir -p cache

    # Определение архитектуры и загрузка бинаря
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
      URL="https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz"
    else
      URL="https://download.pipe.network/static/pop-v0.3.0-linux-arm64.tar.gz"
    fi
    wget -q "$URL" -O pop.tar.gz
    tar -xzf pop.tar.gz && rm pop.tar.gz
    chmod +x pop

    # Генерация config.json
    MB=$(( RAM_GB * 1024 ))
    cat > config.json <<EOL
{
  "pop_name": "${POP_NAME}",
  "pop_location": "${POP_LOCATION}",
  "invite_code": "${INVITE}",
  "server": {"host": "0.0.0.0","port": 443,"http_port": 80,"workers": 0},
  "cache_config": {"memory_cache_size_mb": ${MB},"disk_cache_path": "./cache","disk_cache_size_gb": ${DISK_GB},"default_ttl_seconds": 86400,"respect_origin_headers": true,"max_cacheable_size_mb": 1024},
  "api_endpoints": {"base_url": "https://dataplane.pipenetwork.com"},
  "identity_config": {"node_name": "${POP_NAME}","name": "${POP_NAME}","email": "${EMAIL}","website": "","discord": "${DISCORD}","telegram": "${TELEGRAM}","solana_pubkey": "${SOLANA_PUBKEY}"}
}
EOL

    # Настройка iptables
    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 8003 -j ACCEPT
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"

    # Dockerfile
    cat > Dockerfile <<EOF
FROM ubuntu:24.04
RUN apt update && apt install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY pop /usr/local/bin/pop
COPY config.json /etc/popcache/config.json
COPY cache /data/cache
RUN mkdir -p /var/log/popcache
ENTRYPOINT ["/usr/local/bin/pop"]
CMD ["--config","/etc/popcache/config.json"]
EOF

    # Сборка и запуск контейнера
    docker build -t pipe-node-image .
    docker run -d --name pipe-node --network host pipe-node-image
    ;;
  2)
    echo -e "${GREEN}У вас актуальная версия ноды Pipe!${NC}"
    ;;
  3)
    docker logs -f pipe-node
    ;;
  4)
    docker restart pipe-node
    ;;
  5)
    docker ps --filter "name=pipe-node"
    ;;
  6)
    curl -s http://localhost/health | jq .
    ;;
  7)
    docker stop pipe-node && docker rm pipe-node
    rm -rf "$HOME/pipe-node"
    ;;
  *)
    echo -e "${RED}Неверный выбор${NC}"
    ;;
esac
