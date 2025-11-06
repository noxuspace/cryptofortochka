#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
APP_NAME="Stable"
SERVICE_NAME="stabled"
BIN_PATH="/usr/bin/stabled"
HOME_DIR="$HOME/.stabled"
CHAIN_ID="stabletestnet_2201-1"

# Архивы (автоопределение архитектуры будет в пункте 2)
URL_AMD64="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-1.1.0-linux-amd64-testnet.tar.gz"
URL_ARM64="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-1.1.0-linux-arm64-testnet.tar.gz"
GENESIS_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip"
RPC_CFG_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/rpc_node_config.zip"
SNAPSHOT_URL="https://stable-snapshot.s3.eu-central-1.amazonaws.com/snapshot.tar.lz4"

# Контрольная сумма генезиса
GENESIS_SHA256_EXPECTED="66afbb6e57e6faf019b3021de299125cddab61d433f28894db751252f5b8eaf2"

# Сеть: пиры
PEERS="5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  $SUDO apt-get update -y >/dev/null 2>&1 || true
  $SUDO apt-get install -y curl >/dev/null 2>&1 || true
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# ============================== Меню =========================
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Логи ноды${NC}"
echo -e "${CYAN}3) Перезапуск ноды${NC}"
echo -e "${CYAN}4) Health check ноды${NC}"
echo -e "${CYAN}5) Удаление ноды${NC}"

echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in

# ============== 1) Установка ноды (всё в одном) ==============
1)
  echo -e "${BLUE}Подготавливаем сервер...${NC}"
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y curl wget tar unzip jq lz4 pv
  
  echo -e "${BLUE}Устанавливаем ноду ${APP_NAME}...${NC}"

  # Определяем архитектуру
  ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m || echo unknown)"
  case "$ARCH" in
    amd64|x86_64)  DL_URL="$URL_AMD64" ;;
    arm64|aarch64) DL_URL="$URL_ARM64" ;;
    *)             echo -e "${YELLOW}Неизвестная архитектура: ${ARCH}. Использую amd64-архив.${NC}"; DL_URL="$URL_AMD64" ;;
  esac
  echo -e "${PURPLE}Архитектура:${NC} ${CYAN}${ARCH}${NC}"
  echo -e "${PURPLE}Архив бинарника:${NC} ${CYAN}${DL_URL}${NC}"

  # Монникер
  echo -ne "${YELLOW}Введите моникер (имя узла)${NC} (по умолчанию: ${PURPLE}StableNode${NC}): "
  read MONIKER
  MONIKER=${MONIKER:-StableNode}

  # Скачиваем и ставим бинарь
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  echo -e "${BLUE}Скачиваем и устанавливаем бинарный файл...${NC}"
  wget -O stabled.tar.gz "$DL_URL"
  tar -xvzf stabled.tar.gz
  $SUDO mv -f stabled "$BIN_PATH"
  $SUDO chmod +x "$BIN_PATH"
  cd "$HOME"
  rm -rf "$TMPDIR"

  # Инициализация
  echo -e "${BLUE}Инициализируем ноду (chain-id ${CHAIN_ID})...${NC}"
  "$BIN_PATH" init "$MONIKER" --chain-id "$CHAIN_ID"

  # Genesis
  echo -e "${BLUE}Скачиваем genesis...${NC}"
  TMPG="$(mktemp -d)"; cd "$TMPG"
  wget -O stable_testnet_genesis.zip "$GENESIS_ZIP_URL"
  unzip -o stable_testnet_genesis.zip
  mkdir -p "$HOME_DIR/config"
  cp -f genesis.json "$HOME_DIR/config/genesis.json"
  SHA_NOW=$(sha256sum "$HOME_DIR/config/genesis.json" | awk '{print $1}')
  if [ "$SHA_NOW" = "$GENESIS_SHA256_EXPECTED" ]; then
    echo -e "${GREEN}genesis checksum ок.${NC}"
  else
    echo -e "${YELLOW}ВНИМАНИЕ: checksum genesis не совпал!${NC}"
    echo -e "${PURPLE}Ожидалось:${NC} $GENESIS_SHA256_EXPECTED"
    echo -e "${PURPLE}Получено:${NC}  $SHA_NOW"
  fi
  cd "$HOME"
  rm -rf "$TMPG"

  # Конфиги (config.toml, app.toml)
  echo -e "${BLUE}Скачиваем готовые конфигурации...${NC}"
  TMPC="$(mktemp -d)"; cd "$TMPC"
  wget -O rpc_node_config.zip "$RPC_CFG_ZIP_URL"
  unzip -o rpc_node_config.zip
  cp -f config.toml "$HOME_DIR/config/config.toml"
  cp -f app.toml    "$HOME_DIR/config/app.toml"
  cd "$HOME"
  rm -rf "$TMPC"

  # Патчи конфигов
  echo -e "${BLUE}Изменяем конфигурации (peers, RPC, CORS, лимиты, moniker)...${NC}"
  sed -i "s/^moniker = \".*\"/moniker = \"${MONIKER}\"/" "$HOME_DIR/config/config.toml"
  sed -i 's/^cors_allowed_origins = .*/cors_allowed_origins = ["*"]/' "$HOME_DIR/config/config.toml"
  sed -i "s|^persistent_peers = \".*\"|persistent_peers = \"${PEERS}\"|" "$HOME_DIR/config/config.toml"
  sed -i 's/^max_num_inbound_peers = .*/max_num_inbound_peers = 50/' "$HOME_DIR/config/config.toml"
  sed -i 's/^max_num_outbound_peers = .*/max_num_outbound_peers = 30/' "$HOME_DIR/config/config.toml"

  sed -i 's/^\(\s*enable\s*=\s*\).*/\1true/' "$HOME_DIR/config/app.toml"
  sed -i 's|^\(\s*address\s*=\s*\).*|\1"0.0.0.0:8545"|' "$HOME_DIR/config/app.toml"
  sed -i 's|^\(\s*ws-address\s*=\s*\).*|\1"0.0.0.0:8546"|' "$HOME_DIR/config/app.toml"
  sed -i 's/^\(\s*allow-unprotected-txs\s*=\s*\).*/\1true/' "$HOME_DIR/config/app.toml"

  # systemd-сервис (без User=, чтобы дефолт — root)
  echo -e "${BLUE}Создаем systemd-сервис ${SERVICE_NAME}.service...${NC}"
  TMPU="$(mktemp)"; cat > "$TMPU" <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=$USER
ExecStart=${BIN_PATH} start --chain-id ${CHAIN_ID}
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF
  $SUDO mv "$TMPU" "/etc/systemd/system/${SERVICE_NAME}.service"
  $SUDO systemctl daemon-reload
  $SUDO systemctl enable "${SERVICE_NAME}"

  # Снапшот (по желанию)
  echo -ne "${YELLOW}Подтянуть снапшот сейчас? [y/N]: ${NC}"; read use_snap
  if [[ "${use_snap,,}" =~ ^y ]]; then
    echo -e "${BLUE}Скачиваем снапшот...${NC}"
    mkdir -p "$HOME/snapshot" "$HOME/stable-backup" "$HOME_DIR"
    cp -r "$HOME_DIR/data" "$HOME/stable-backup/" 2>/dev/null || true
    cd "$HOME/snapshot"
    wget -c "$SNAPSHOT_URL" -O snapshot.tar.lz4
    rm -rf "$HOME_DIR/data"/* 2>/dev/null || true
    pv snapshot.tar.lz4 | tar -I lz4 -xf - -C "$HOME_DIR/"
    rm -f snapshot.tar.lz4
    echo -e "${GREEN}Снапшот применён.${NC}"
  fi

  $SUDO systemctl start "${SERVICE_NAME}" && echo -e "${GREEN}Нода запущена.${NC}" || echo -e "${RED}Ошибка запуска.${NC}"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${YELLOW}Команда для проверки логов:${NC}" 
  echo "journalctl -u stabled.service -f -n 200"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  sleep 2
  journalctl -u stabled.service -f -n 200
  ;;

# ==================== 2) Логи (онлайн) =======================
2)
  echo -e "${PURPLE}Ctrl+C для выхода из логов${NC}"
  sleep 1
  journalctl -u stabled.service -f -n 200
  ;;

# ===================== 3) Перезапуск ноды ====================
3)
  $SUDO systemctl restart stabled.service && echo -e "${GREEN}Нода перезапущена.${NC}" || echo -e "${RED}Не удалось перезапустить.${NC}"
  ;;
  
# =================== 4) Health check ноды ====================
4)
  # Сервис
  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo -e "${GREEN}✓ Сервис запущен${NC}"
  else
    echo -e "${RED}✗ Сервис не запущен${NC}"
    echo
    echo -e "${PURPLE}systemctl status ${SERVICE_NAME}${NC}"
    systemctl status "${SERVICE_NAME}" --no-pager || true
    echo
    echo -e "${PURPLE}journalctl -u ${SERVICE_NAME} -n 200 --no-pager${NC}"
    journalctl -u "${SERVICE_NAME}" -n 200 --no-pager || true
    exit 0
  fi

  # Синхронизация
  SYNC_STATUS=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up' 2>/dev/null || echo "unknown")
  if [[ "$SYNC_STATUS" == "false" ]]; then
    echo -e "${GREEN}✓ Нода синхронизирована${NC}"
  elif [[ "$SYNC_STATUS" == "true" ]]; then
    echo -e "${YELLOW}⚠ Нода синхронизируется${NC}"
  else
    echo -e "${YELLOW}⚠ Статус синхронизации: неизвестно${NC}"
  fi

  # Пиры
  PEER_CNT=$(curl -s localhost:26657/net_info | jq -r '.result.n_peers' 2>/dev/null || echo 0)
  if [[ "${PEER_CNT:-0}" -ge 3 ]]; then
    echo -e "${GREEN}✓ Подключённых пиров:${NC} ${PEER_CNT}"
  else
    echo -e "${YELLOW}⚠ Мало пиров:${NC} ${PEER_CNT}"
  fi

  # Диск
  DISK_USAGE=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')
  if [[ "${DISK_USAGE:-0}" -lt 80 ]]; then
    echo -e "${GREEN}✓ Диск занят на:${NC} ${DISK_USAGE}%"
  else
    echo -e "${YELLOW}⚠ Высокая загрузка диска:${NC} ${DISK_USAGE}%"
  fi

  # Память
  MEM_AVAILABLE=$(free -m | awk 'NR==2 {print $7}')
  MEM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
  if [[ -n "${MEM_AVAILABLE}" && -n "${MEM_TOTAL}" && "${MEM_TOTAL}" -gt 0 ]]; then
    MEM_PERCENT=$((100 - (MEM_AVAILABLE * 100 / MEM_TOTAL)))
  else
    MEM_PERCENT=0
  fi
  if [[ "${MEM_PERCENT:-0}" -lt 80 ]]; then
    echo -e "${GREEN}✓ Память занята на:${NC} ${MEM_PERCENT}%"
  else
    echo -e "${YELLOW}⚠ Высокая загрузка памяти:${NC} ${MEM_PERCENT}%"
  fi

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Проверка завершена${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ==================== 5) Полное удаление =====================
5)
  echo -ne "${RED}Удалить ВСЕ данные ноды? (YES/NO) ${NC}"; read CONFIRM
  if [ "$CONFIRM" = "YES" ]; then
    echo -e "${RED}Удаляем...${NC}"
    for UNIT in stabled stable; do
      $SUDO systemctl stop "$UNIT" 2>/dev/null || true
      $SUDO systemctl disable "$UNIT" 2>/dev/null || true
      $SUDO rm -f "/etc/systemd/system/${UNIT}.service" 2>/dev/null || true
    done
    $SUDO systemctl daemon-reload

    pkill -f "[s]tabled" 2>/dev/null || true
    sleep 1
    pkill -9 -f "[s]tabled" 2>/dev/null || true

    rm -f "$HOME_DIR/data/LOCK" "$HOME_DIR/data/application.db/LOCK" "$HOME_DIR/data/snapshots/LOCK" 2>/dev/null || true

    rm -rf "$HOME_DIR" "$HOME/snapshot" "$HOME/stable-backup" /tmp/stable_genesis /tmp/rpc_cfg 2>/dev/null || true
    $SUDO rm -f "$BIN_PATH" 2>/dev/null || true
    rm -rf /var/log/stabled 2>/dev/null || true

    echo -e "${GREEN}Нода и её логи удалены.${NC}"
  else
    echo -e "${PURPLE}Отмена удаления. Ничего не изменено.${NC}"
  fi
  ;;

# ============================ Неверный ввод ===========================
*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}" ;;

esac
