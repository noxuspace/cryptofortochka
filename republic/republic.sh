#!/usr/bin/env bash

# =========================== Цвета base ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
REPUBLIC_HOME="${REPUBLIC_HOME:-$HOME/.republicd}"
CONTAINER_NAME="republicd"
IMAGE_TAG="ghcr.io/republicai/republicd:0.1.0"
CHAIN_ID="raitestnet_77701-1"
SNAP_RPC="${SNAP_RPC:-https://statesync.republicai.io}"
PEERS_DEFAULT="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
GENESIS_URL="https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json"

# Загружаем предыдущее окружение, если было
ENV_FILE="$REPUBLIC_HOME/.env"
[ -f "$ENV_FILE" ] && . "$ENV_FILE" 2>/dev/null || true

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
  $SUDO apt-get update && $SUDO apt-get install -y curl
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# ============================== Меню =========================
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Управление контейнером Docker${NC}"
echo -e "${CYAN}3) Информация о ноде и валидатор${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"
echo -e "${CYAN}5) Обновление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in

# ===================== 1) Установка ноды ===================
1)
  echo -e "${BLUE}Установка ноды Republic...${NC}"
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")

  # Обновление пакетов
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y curl git jq lz4

  # Docker — ставим только если ещё нет
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Docker...${NC}"
    $SUDO apt-get install -y docker.io
    $SUDO systemctl enable docker 2>/dev/null || true
    $SUDO systemctl start docker 2>/dev/null || true
    [ -S /var/run/docker.sock ] && $SUDO chmod 666 /var/run/docker.sock 2>/dev/null || true
    $SUDO usermod -aG docker "$USER" 2>/dev/null || true
  else
    echo -e "${GREEN}Docker уже установлен, пропускаем.${NC}"
  fi

  mkdir -p "$REPUBLIC_HOME"

  echo -e "${BLUE}Скачиваем образ...${NC}"
  docker pull "$IMAGE_TAG"

  # Инициализация (создаём файлы от root)
  echo -e "${BLUE}Инициализация данных ноды...${NC}"
  docker run --rm \
    --user 0:0 \
    -v "$REPUBLIC_HOME:/home/republic/.republicd" \
    "$IMAGE_TAG" \
    init my-node --chain-id "$CHAIN_ID" --home /home/republic/.republicd

  # Скачиваем genesis
  echo -e "${BLUE}Загружаем genesis...${NC}"
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
  $SUDO curl -s "$GENESIS_URL" -o "$REPUBLIC_HOME/config/genesis.json"

  # State sync
  echo -e "${BLUE}Настраиваем state sync и peers...${NC}"
  LATEST_HEIGHT=$(curl -s "$SNAP_RPC/block" | jq -r .result.block.header.height)
  BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
  TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

  $SUDO sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"

  $SUDO sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS_DEFAULT\"/" "$REPUBLIC_HOME/config/config.toml"

  # Права для пользователя контейнера (UID 1001)
  $SUDO chown -R 1001:1001 "$REPUBLIC_HOME"

  # Сохраняем в .env для пункта 3
  mkdir -p "$REPUBLIC_HOME"
  cat > "$ENV_FILE" <<EOF
REPUBLIC_HOME="$REPUBLIC_HOME"
CONTAINER_NAME="$CONTAINER_NAME"
IMAGE_TAG="$IMAGE_TAG"
CHAIN_ID="$CHAIN_ID"
SNAP_RPC="$SNAP_RPC"
PEERS="$PEERS_DEFAULT"
EOF
  chmod 600 "$ENV_FILE" 2>/dev/null || true

  # Запуск контейнера
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d --name "$CONTAINER_NAME" \
    --network host \
    -v "$REPUBLIC_HOME:/home/republic/.republicd" \
    "$IMAGE_TAG" \
    start --home /home/republic/.republicd --chain-id "$CHAIN_ID"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Нода запущена. Через пару минут проверьте синхронизацию: пункт 3 → 2) Статус ноды.${NC}"
  echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"

  sleep 2
  echo -e "${PURPLE}Ctrl+C для выхода из логов${NC}"
  docker logs -f "$CONTAINER_NAME"
  ;;

# ========== 2) Управление контейнером (start/restart/stop/rm/status) ==========
2)
  echo -e "${YELLOW}Управление контейнером:${NC}"
  echo -e "${CYAN}1) Запустить${NC}"
  echo -e "${CYAN}2) Перезапустить${NC}"
  echo -e "${CYAN}3) Остановить${NC}"
  echo -e "${CYAN}4) Удалить контейнер${NC}"
  echo -e "${CYAN}5) Статус${NC}"
  echo -ne "${YELLOW}Введите номер: ${NC}"; read -r m
  case "$m" in
    1)
      if docker start "$CONTAINER_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}Запущен.${NC}"
      else
        echo -e "${RED}Контейнер не найден. Выполните пункт 1) Установка ноды.${NC}"
      fi
      ;;
    2)
      docker restart "$CONTAINER_NAME" && echo -e "${GREEN}Перезапущен.${NC}" || echo -e "${RED}Не удалось.${NC}"
      ;;
    3)
      docker stop "$CONTAINER_NAME" && echo -e "${GREEN}Остановлен.${NC}" || true
      ;;
    4)
      docker rm -f "$CONTAINER_NAME" && echo -e "${GREEN}Контейнер удалён. Данные в $REPUBLIC_HOME сохранены.${NC}" || true
      ;;
    5)
      docker ps -a --filter "name=$CONTAINER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
      ;;
    *) ;;
  esac
  ;;

# ======= 3) Информация о ноде и валидатор =======
3)
  [ -f "$ENV_FILE" ] && . "$ENV_FILE"
  echo -e "${YELLOW}Инструменты:${NC}"
  echo -e "${CYAN}1) Логи (онлайн)${NC}"
  echo -e "${CYAN}2) Статус ноды (sync_info)${NC}"
  echo -e "${CYAN}3) Последний блок${NC}"
  echo -e "${CYAN}4) Создать кошелёк валидатора${NC}"
  echo -e "${CYAN}5) Показать адрес валидатора${NC}"
  echo -e "${CYAN}6) Создать валидатора (create-validator)${NC}"
  echo -e "${CYAN}7) Делегировать себе токены${NC}"
  echo -e "${CYAN}8) Забрать награду${NC}"
  echo -ne "${YELLOW}Введите номер: ${NC}"; read -r t
  case "$t" in
    1)
      echo -e "${PURPLE}Ctrl+C для выхода из логов${NC}"
      docker logs -f "$CONTAINER_NAME"
      ;;
    2)
      docker exec "$CONTAINER_NAME" republicd status 2>/dev/null | jq '.sync_info' || docker exec -it "$CONTAINER_NAME" republicd status
      ;;
    3)
      docker exec "$CONTAINER_NAME" republicd status 2>/dev/null | jq -r '.sync_info.latest_block_height // "n/a"'
      ;;
    4)
      echo -e "${YELLOW}Придумайте пароль и сохраните мнемонику и адрес.${NC}"
      docker exec -it "$CONTAINER_NAME" republicd keys add validator --home /home/republic/.republicd
      ;;
    5)
      # -it нужен для ввода пароля keyring; без TTY команда не выводит адрес
      echo -e "${YELLOW}Введите пароль ключа validator, если запросит.${NC}"
      docker exec -it "$CONTAINER_NAME" republicd keys show validator -a --home /home/republic/.republicd 2>&1 | tr -d '\r'
      ;;
    6)
      echo -ne "${YELLOW}Введите MONIKER (имя валидатора): ${NC}"; read -r MONIKER
      PUBKEY=$(docker exec "$CONTAINER_NAME" republicd comet show-validator --home /home/republic/.republicd 2>/dev/null | tr -d '\r')
      if [ -z "$PUBKEY" ]; then
        echo -e "${RED}Не удалось получить pubkey. Нода запущена?${NC}"
        exit 1
      fi
      cat > /tmp/validator.json <<EOF
{
  "pubkey": $PUBKEY,
  "amount": "1000000000000000000arai",
  "moniker": "${MONIKER:-my-validator}",
  "identity": "",
  "website": "",
  "details": "Republic AI Validator",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
      docker cp /tmp/validator.json "$CONTAINER_NAME:/tmp/validator.json"
      echo -e "${YELLOW}Введите пароль ключа validator, если запросит.${NC}"
      docker exec -it "$CONTAINER_NAME" republicd tx staking create-validator /tmp/validator.json \
        --home /home/republic/.republicd \
        --chain-id "$CHAIN_ID" \
        --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai \
        --from validator -y
      ;;
    7)
      # Адреса и баланс: keys show без -it не выводит ничего (запрос пароля)
      echo -e "${YELLOW}Введите пароль ключа validator (первый раз — для адреса).${NC}"
      VALADDR=$(docker exec -it "$CONTAINER_NAME" republicd keys show validator -a --home /home/republic/.republicd 2>&1 | tr -d '\r' | grep -oE 'rai1[a-z0-9]+' | head -1)
      echo -e "${YELLOW}Пароль принят. Введите пароль ещё раз (для VALOPER).${NC}"
      VALOPER=$(docker exec -it "$CONTAINER_NAME" republicd keys show validator -a --bech val --home /home/republic/.republicd 2>&1 | tr -d '\r' | grep -oE 'raivaloper1[a-z0-9]+' | head -1)
      if [ -z "$VALOPER" ]; then
        echo -e "${YELLOW}Введите VALOPER адрес вручную: ${NC}"; read -r VALOPER
      fi
      if [ -z "$VALADDR" ]; then
        echo -e "${RED}Не удалось получить адрес validator. Проверьте пароль.${NC}"
      else
      BALANCE_JSON=$(docker exec "$CONTAINER_NAME" republicd query bank balances "$VALADDR" --home /home/republic/.republicd --output json 2>/dev/null)
      BALANCE=$(echo "$BALANCE_JSON" | jq -r '.balances[] | select(.denom=="arai" or .denom=="urai") | .amount // empty' | head -1)
      BALANCE=${BALANCE:-0}
      LEAVE_ONE=50000000000000000
      DELEGATE_RESULT=$(python3 -c "
b = int('$BALANCE')
leave = int('$LEAVE_ONE')
d = b - leave
if d > 0:
    print(d)
else:
    print('0')
" 2>/dev/null)
      DELEGATE_AMOUNT=${DELEGATE_RESULT:-0}
      BALANCE_HUMAN=$(python3 -c "print(round(int('$BALANCE')/1e18, 2))" 2>/dev/null || echo "0")
      DELEGATE_HUMAN=$(python3 -c "print(round(int('${DELEGATE_AMOUNT:-0}')/1e18, 2))" 2>/dev/null || echo "0")
      if [ -z "$DELEGATE_AMOUNT" ] || [ "$DELEGATE_AMOUNT" = "0" ]; then
        echo -e "${RED}Недостаточно токенов для делегирования (баланс: ${BALANCE_HUMAN} arai, нужно больше 0.05 arai для комиссии).${NC}"
      else
        echo -e "${CYAN}Баланс: ${BALANCE_HUMAN} arai. Делегируем всё кроме 0.05 arai (${DELEGATE_HUMAN} arai) на $VALOPER${NC}"
        echo -e "${YELLOW}Введите пароль ключа validator для подтверждения транзакции.${NC}"
        docker exec -it "$CONTAINER_NAME" republicd tx staking delegate \
          "$VALOPER" \
          "${DELEGATE_AMOUNT}arai" \
          --from validator \
          --home /home/republic/.republicd \
          --chain-id "$CHAIN_ID" \
          --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai -y
      fi
      fi
      ;;
    8)
      VALOPER=$(docker exec "$CONTAINER_NAME" republicd keys show validator -a --bech val --home /home/republic/.republicd 2>/dev/null | tr -d '\r')
      if [ -z "$VALOPER" ]; then
        echo -e "${YELLOW}Введите VALOPER адрес: ${NC}"; read -r VALOPER
      fi
      echo -e "${YELLOW}Введите пароль ключа validator, если запросит.${NC}"
      docker exec -it "$CONTAINER_NAME" republicd tx distribution withdraw-rewards \
        "$VALOPER" \
        --from validator --commission \
        --home /home/republic/.republicd \
        --chain-id "$CHAIN_ID" \
        --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai -y
      ;;
    *) ;;
  esac
  ;;

# =============================== 4) Удаление ==============================
4)
  echo -e "${RED}Полностью удалить ноду Republic (контейнер + данные в $REPUBLIC_HOME)? (YES/NO)${NC}"
  read -r CONFIRM
  if [ "$CONFIRM" = "YES" ]; then
    echo -e "${RED}Удаляю...${NC}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rmi -f "$IMAGE_TAG" >/dev/null 2>&1 || true
    rm -rf "$REPUBLIC_HOME"
    echo -e "${GREEN}Контейнер, образ и каталог $REPUBLIC_HOME удалены.${NC}"
  else
    echo -e "${PURPLE}Отмена. Ничего не изменено.${NC}"
  fi
  ;;
# ===================== 5) Обновление ноды ===================
5)
  echo -e "${BLUE}Обновление ноды Republic до v0.2.1 (через свой Docker image)...${NC}"
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || "")

  # Проверки
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Docker не найден. Сначала выполните пункт 1) Установка ноды.${NC}"
    exit 1
  fi

  if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}Базовый образ $IMAGE_TAG не найден локально — скачиваю...${NC}"
    docker pull "$IMAGE_TAG" || { echo -e "${RED}Не удалось скачать $IMAGE_TAG${NC}"; exit 1; }
  fi

  # Определяем архитектуру
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64) BIN_NAME="republicd-linux-amd64" ;;
    aarch64|arm64) BIN_NAME="republicd-linux-arm64" ;;
    *)
      echo -e "${RED}Неизвестная архитектура: $ARCH${NC}"
      exit 1
      ;;
  esac

  VERSION_TAG="v0.2.1"
  DL_URL="https://github.com/RepublicAI/networks/releases/download/${VERSION_TAG}/${BIN_NAME}"
  NEW_IMAGE_TAG="republicd:0.2.1"

  echo -e "${BLUE}1) Останавливаю контейнер...${NC}"
  docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true

  echo -e "${BLUE}2) Скачиваю новый бинарник: ${BIN_NAME}${NC}"
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR" || exit 1

  # Качаем
  curl -LfsS "$DL_URL" -o republicd || { echo -e "${RED}Не удалось скачать: $DL_URL${NC}"; rm -rf "$TMPDIR"; exit 1; }
  chmod +x republicd

  echo -e "${BLUE}3) Собираю свой образ ${NEW_IMAGE_TAG} (base: ${IMAGE_TAG})...${NC}"
  cat > Dockerfile <<EOF
FROM ${IMAGE_TAG}
USER root
COPY republicd /usr/local/bin/republicd
RUN chmod 755 /usr/local/bin/republicd && chown root:root /usr/local/bin/republicd
USER republic
WORKDIR /home/republic
ENTRYPOINT ["republicd"]
EOF

  docker build -t "$NEW_IMAGE_TAG" . || { echo -e "${RED}Сборка образа не удалась${NC}"; rm -rf "$TMPDIR"; exit 1; }

  echo -e "${BLUE}4) Проверяю версию в новом образе...${NC}"
  docker run --rm --entrypoint sh "$NEW_IMAGE_TAG" -lc 'republicd version 2>/dev/null || true'

  echo -e "${BLUE}5) Перезапускаю контейнер на новом образе...${NC}"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d --name "$CONTAINER_NAME" \
    --network host \
    -v "$REPUBLIC_HOME:/home/republic/.republicd" \
    "$NEW_IMAGE_TAG" \
    start --home /home/republic/.republicd --chain-id "$CHAIN_ID" || { echo -e "${RED}Не удалось запустить контейнер${NC}"; rm -rf "$TMPDIR"; exit 1; }

  # Обновляем .env, чтобы дальше в скрипте использовался новый образ
  echo -e "${BLUE}6) Обновляю $ENV_FILE (IMAGE_TAG -> $NEW_IMAGE_TAG)...${NC}"
  mkdir -p "$REPUBLIC_HOME"
  cat > "$ENV_FILE" <<EOF
REPUBLIC_HOME="$REPUBLIC_HOME"
CONTAINER_NAME="$CONTAINER_NAME"
IMAGE_TAG="$NEW_IMAGE_TAG"
CHAIN_ID="$CHAIN_ID"
SNAP_RPC="$SNAP_RPC"
PEERS="$PEERS_DEFAULT"
EOF
  chmod 600 "$ENV_FILE" 2>/dev/null || true

  rm -rf "$TMPDIR"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Готово. Нода запущена на образе: $NEW_IMAGE_TAG${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"

  sleep 5
  echo -e "${PURPLE}Ctrl+C для выхода из логов${NC}"
  docker logs -f "$CONTAINER_NAME"
  ;;

*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}" ;;

esac
