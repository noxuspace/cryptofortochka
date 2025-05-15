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
    echo -e "${BLUE}Установка ноды Pipe (Testnet)...${NC}"
    sudo apt-get update
    sudo apt install -y libssl-dev ca-certificates jq
    
    if ! command -v iptables &> /dev/null; then
        sudo apt update && sudo apt install -y iptables
    fi

    sudo apt update
    sudo apt install -y iptables-persistent
    
    # Создание рабочей директории
    sudo mkdir -p /opt/popcache && cd /opt/popcache

    # Запрос параметров    
    echo -e "${YELLOW}Придумайте имя для ноды:${NC}"
    read POP_NODE
    
    echo -e "${YELLOW}Введите объём оперативной памяти (только цифра или число в GB, например, 6 или 8 и т.п.):${NC}"
    read RAM_GB
    
    echo -e "${YELLOW}Введите максимальный размер кеша на диске (только число в GB, например, 250):${NC}"
    read DISK_GB

    # Получаем данные с ip-api.com
    response=$(curl -s http://ip-api.com/json)
    
    # Извлекаем страну и город
    country=$(echo "$response" | jq -r '.country')
    city=$(echo "$response" | jq -r '.city')
    
    # Формируем переменную
    POP_LOCATION="$city, $country"

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
    sudo sysctl -p /etc/sysctl.d/99-popcache.conf

    # Лимиты открытых файлов
    sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
*    hard nofile 65535
*    soft nofile 65535
EOL'

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
    chmod 755 /opt/popcache/pop

    # Генерация config.json
    MB=$(( RAM_GB * 1024 ))
    cat > config.json <<EOL
{
  "pop_name": "${POP_NODE}",
  "pop_location": "${POP_LOCATION}",
  "invite_code": "f5pio4Ehesp1",
  "server": {"host": "0.0.0.0","port": 443,"http_port": 80,"workers": 0},
  "cache_config": {"memory_cache_size_mb": ${MB},"disk_cache_path": "./cache","disk_cache_size_gb": ${DISK_GB},"default_ttl_seconds": 86400,"respect_origin_headers": true,"max_cacheable_size_mb": 1024},
  "api_endpoints": {"base_url": "https://dataplane.pipenetwork.com"},
  "identity_config": {"node_name": "${POP_NODE}","name": "locizard","email": "rynnallet@gmail.com","website": "https://noxu.webflow.io","discord": "cloverx","telegram": "locizard","solana_pubkey": "GUejGPgmLtKMWKAZ3hpaGuTNTqaLv7ezvn6J5LJsAzAn"}
}
EOL

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

    # Dockerfile
    cat > Dockerfile << EOL
FROM ubuntu:24.04

# Install dependensi dasar
RUN apt update && apt install -y \\
    ca-certificates \\
    curl \\
    libssl-dev \\
    && rm -rf /var/lib/apt/lists/*

# Buat direktori untuk pop
WORKDIR /opt/popcache

# Salin file konfigurasi & binary dari host
COPY pop .
COPY config.json .

# Berikan izin eksekusi
RUN chmod +x ./pop

# Jalankan node
CMD ["./pop", "--config", "config.json"]
EOL

    # Сборка и запуск контейнера
    docker build -t popnode .
    cd ~

    docker run -d \
      --name popnode \
      -p 80:80 \
      -p 443:443 \
      --restart unless-stopped \
      popnode
    
    # Завершающий вывод
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Команда для проверки логов:${NC}" 
    echo "docker logs --tail 100 -f popnode"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    sleep 2
    docker logs --tail 100 -f popnode
    ;;
  2)
    echo -e "${GREEN}У вас актуальная версия ноды Pipe!${NC}"
    ;;
  3)
    docker logs --tail 100 -f popnode
    ;;
  4)
    docker restart popnode && docker logs --tail 100 -f popnode
    ;;
  5)
    curl -sk https://localhost/health | jq
    ;;
  6)
    curl -sk https://localhost/state | jq
    ;;
  7)
    docker stop popnode && docker rm popnode
    sudo rm -rf /opt/popcache

    docker rmi popnode:latest

    # Удаляем sysctl-конфигурацию и применяем изменения
    sudo rm -f /etc/sysctl.d/99-popcache.conf
    sudo sysctl --system

    # Удаляем limits-конфиг
    sudo rm -f /etc/security/limits.d/popcache.conf
    ;;
  *)
    echo -e "${RED}Неверный выбор${NC}"
    ;;
esac
