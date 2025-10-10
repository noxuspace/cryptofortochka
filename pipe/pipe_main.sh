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
echo -e "${CYAN}5) Удаление ноды${NC}"

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
      echo -e "${RED}Введите только число (МБ).${NC}"
    done
    
    # Дисковый кеш в ГБ (только число)
    while true; do
      echo -e "${YELLOW}Введите максимальный размер кеша на диске (в ГБ, напр. 100 или 250):${NC}"
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
    echo -e "${RED}Вернитесь в текстовый гайд и выполните обновление вручную!${NC}"
    ;;
  3)
    docker logs --tail 100 -f popnode
    ;;
  4)
    docker restart popnode && docker logs --tail 100 -f popnode
    ;;
  5)
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
