#!/bin/bash

# ===========================
# Mawari Node by CRYPTO FORTOCHKA (без функций)
# ===========================

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Базовые переменные
WORKDIR="$HOME/mawari"
ENV_FILE="$WORKDIR/.env"
CONTAINER_NAME="mawari"
DEFAULT_IMAGE="us-east4-docker.pkg.dev/mawarinetwork-dev/mwr-net-d-car-uses4-public-docker-registry-e62e/mawari-node:latest"

# Проверка curl (без лишних сообщений)
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install -y curl
fi
sleep 1

# Лого
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Обновление ноды${NC}"
echo -e "${CYAN}3) Просмотр логов${NC}"
echo -e "${CYAN}4) Рестарт ноды${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"
read choice

case $choice in
  1)
    echo -e "${BLUE}Установка зависимостей...${NC}"
    sudo apt-get update -y && sudo apt-get upgrade -y
    sudo apt-get install -y apt-transport-https ca-certificates gnupg lsb-release

    # Docker
    if ! command -v docker &> /dev/null; then
      echo -e "${BLUE}Устанавливаю Docker...${NC}"
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      sudo usermod -aG docker "$USER"
      rm -f get-docker.sh
      sudo systemctl enable docker >/dev/null 2>&1 || true
      sudo systemctl start docker
      if [ -S /var/run/docker.sock ]; then
        sudo chmod 666 /var/run/docker.sock
      fi
    fi

    # Папка и .env
    mkdir -p "$WORKDIR"

    if [ ! -f "$ENV_FILE" ]; then
cat > "$ENV_FILE" <<EOF
# === Mawari Node Env ===
MNTESTNET_IMAGE=${DEFAULT_IMAGE}
OWNER_ADDRESS=
EOF
      echo -e "${BLUE}Создан файл окружения: ${ENV_FILE}${NC}"
    fi

    # Подтянем переменные из .env
    # shellcheck disable=SC1090
    source "$ENV_FILE"

    # OWNER_ADDRESS если пуст — попросим
    if [ -z "$OWNER_ADDRESS" ]; then
      echo -ne "${YELLOW}Вставьте адрес кошелька (0x…): ${NC}"
      read OWNER_ADDRESS
      if [[ ! "$OWNER_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        echo -e "${RED}Неверный формат адреса. Ожидается 0x + 40 hex-символов.${NC}"
        exit 1
      fi
      sed -i "s|^OWNER_ADDRESS=.*|OWNER_ADDRESS=${OWNER_ADDRESS}|g" "$ENV_FILE"
    fi

    # MNTESTNET_IMAGE если пуст — дефолт
    if [ -z "$MNTESTNET_IMAGE" ]; then
      MNTESTNET_IMAGE="$DEFAULT_IMAGE"
      sed -i "s|^MNTESTNET_IMAGE=.*|MNTESTNET_IMAGE=${MNTESTNET_IMAGE}|g" "$ENV_FILE"
    fi

    # Запуск контейнера
    echo -e "${BLUE}Запуск Mawari ноды...${NC}"
    docker pull "$MNTESTNET_IMAGE"

    # Если контейнер уже существует — остановим и удалим
    if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
      docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
      docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    docker run -d \
      --name "$CONTAINER_NAME" \
      --pull always \
      --restart unless-stopped \
      -v "$WORKDIR:/app/cache" \
      -e OWNERS_ALLOWLIST="$OWNER_ADDRESS" \
      "$MNTESTNET_IMAGE"

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Контейнер ${CONTAINER_NAME} запущен!${NC}"
    else
      echo -e "${RED}Ошибка запуска контейнера.${NC}"
      exit 1
    fi

    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Команда для проверки логов:${NC}"
    echo "docker logs --tail 100 -f ${CONTAINER_NAME}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    sleep 2
    docker logs --tail 100 -f "${CONTAINER_NAME}"
    ;;

  2)
    # Обновление образа и рестарт
    if [ -f "$ENV_FILE" ]; then
      # shellcheck disable=SC1090
      source "$ENV_FILE"
    else
      MNTESTNET_IMAGE="$DEFAULT_IMAGE"
    fi

    echo -e "${BLUE}Обновление Mawari ноды...${NC}"
    docker pull "$MNTESTNET_IMAGE"
    docker restart "$CONTAINER_NAME"

    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Команда для проверки логов:${NC}"
    echo "docker logs --tail 100 -f ${CONTAINER_NAME}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    sleep 2
    docker logs --tail 100 -f "${CONTAINER_NAME}"
    ;;

  3)
    docker logs --tail 100 -f "${CONTAINER_NAME}"
    ;;

  4)
    docker restart "${CONTAINER_NAME}"
    sleep 2
    docker logs --tail 100 -f "${CONTAINER_NAME}"
    ;;

  5)
    echo -e "${BLUE}Остановка и удаление Mawari ноды...${NC}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true

    echo -ne "${YELLOW}Удалить данные кэша (${WORKDIR})? (y/N): ${NC}"
    read ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
      rm -rf "$WORKDIR"
      echo -e "${GREEN}Данные удалены.${NC}"
    else
      echo -e "${PURPLE}Данные оставлены по пути ${WORKDIR}.${NC}"
    fi

    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    sleep 1
    ;;

  *)
    echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
    ;;
esac
