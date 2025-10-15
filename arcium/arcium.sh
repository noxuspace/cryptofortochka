#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
WORKDIR="$HOME/arcium-node-setup"
ENV_FILE="$WORKDIR/.env"
CFG_FILE="$WORKDIR/node-config.toml"
NODE_KP="$WORKDIR/node-keypair.json"
CALLBACK_KP="$WORKDIR/callback-kp.json"
IDENTITY_PEM="$WORKDIR/identity.pem"
SEED_NODE="$WORKDIR/node-keypair.seed.txt"
SEED_CALLBACK="$WORKDIR/callback-kp.seed.txt"
PUB_NODE_FILE="$WORKDIR/node-pubkey.txt"
PUB_CALLBACK_FILE="$WORKDIR/callback-pubkey.txt"
LOGS_DIR="$WORKDIR/arx-node-logs"

CONTAINER_NAME="arx-node"
IMAGE_TAG="arcium/arx-node:v0.3.0"
RPC_DEFAULT_HTTP="https://api.devnet.solana.com"
RPC_DEFAULT_WSS="wss://api.devnet.solana.com"

# Загружаем предыдущее окружение, если было
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  (command -v sudo >/dev/null 2>&1 && SUDO="sudo" || SUDO=""); $SUDO apt update && $SUDO apt install -y curl
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# ============================== Меню =========================
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Подготовка сервера${NC}"
echo -e "${CYAN}2) Установка и запуск ноды${NC}"
echo -e "${CYAN}3) Управление контейнером Docker${NC}"
echo -e "${CYAN}4) Конфигурация RPC${NC}"
echo -e "${CYAN}5) Информация о ноде${NC}"
echo -e "${CYAN}6) Удаление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in

# ===================== 1) Подготовка сервера ===================
1)
  echo -e "${BLUE}Подготавливаем сервер...${NC}"
  (command -v sudo >/dev/null 2>&1 && SUDO="sudo" || SUDO="")
  $SUDO apt-get update -y && $SUDO apt-get install -y \
    ca-certificates gnupg lsb-release apt-transport-https \
    curl wget git build-essential pkg-config libssl-dev libudev-dev openssl expect

  # Docker
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -f get-docker.sh
    $SUDO usermod -aG docker "$USER" 2>/dev/null || true
    $SUDO systemctl enable --now docker 2>/dev/null || true
    [ -S /var/run/docker.sock ] && $SUDO chmod 666 /var/run/docker.sock || true
  fi

  # Rust
  if ! command -v rustc >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
  fi

  # Solana CLI
  if ! command -v solana >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Solana CLI...${NC}"
    NONINTERACTIVE=1 bash -lc 'curl -sSfL https://solana-install.solana.workers.dev | bash'
  else
    NONINTERACTIVE=1 bash -lc 'curl -sSfL https://solana-install.solana.workers.dev | bash' || true
  fi

  # Node + Yarn
  if ! command -v node >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Node.js LTS...${NC}"
    bash -lc 'curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -'
    $SUDO apt-get install -y nodejs
  fi
  if ! command -v yarn >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Yarn...${NC}"
    $SUDO npm install -g yarn || true
  fi

  # Anchor (shim, достаточно для arcium-инструментов)
  if ! command -v anchor >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем легкий shim для Anchor 0.29.0...${NC}"
    mkdir -p "$HOME/.cargo/bin"
    cat > "$HOME/.cargo/bin/anchor" <<'EOANCH'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "anchor-cli 0.29.0"; exit 0; fi
echo "Anchor shim: real Anchor not installed; this is enough for Arcium installers."; exit 0
EOANCH
    chmod +x "$HOME/.cargo/bin/anchor"
    [ -e "$HOME/.avm/bin/current" ] && rm -f "$HOME/.avm/bin/current" || true
  fi

  # Arcium CLI через arcup
  if ! command -v arcium >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Arcium CLI (через arcup)...${NC}"
    mkdir -p "$HOME/.cargo/bin" "$HOME/.arcium/bin"
    target="x86_64_linux"; [[ $(uname -m) =~ (aarch64|arm64) ]] && target="aarch64_linux"
    for u in \
      "https://bin.arcium.com/download/arcup_${target}_0.3.0" \
      "https://bin.arcium.network/download/arcup_${target}_0.3.0" \
      "https://downloads.arcium.com/arcup/${target}/0.3.0/arcup"; do
      if curl -fsSL "$u" -o "$HOME/.cargo/bin/arcup"; then chmod +x "$HOME/.cargo/bin/arcup"; break; fi
    done
    if [ -x "$HOME/.cargo/bin/arcup" ]; then
      "$HOME/.cargo/bin/arcup" install || true
    fi
  fi

  # ARM64: включить эмуляцию amd64 для Docker
  ARCH=$(uname -m 2>/dev/null || echo unknown)
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo -e "${PURPLE}ARM64 обнаружен — включаем binfmt для amd64...${NC}"
    docker run --privileged --rm tonistiigi/binfmt --install amd64 || true
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
  fi

  # PATH + bashrc
  grep -q '.cargo/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
  grep -q 'solana/install/active_release/bin' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> "$HOME/.bashrc"
  grep -q '.arcium/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.arcium/bin:$PATH"' >> "$HOME/.bashrc"
  source "$HOME/.bashrc" 2>/dev/null || true

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Подготовка сервера завершена, перейдите в текстовый гайд и следуйте дальнейшим инструкциям!${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ================== 2) Установка и запуск ноды =================
2)
  echo -e "${BLUE}Устанавливаем и запускаем ноду...${NC}"
  mkdir -p "$WORKDIR" "$LOGS_DIR"

  # Сбор параметров
  : "${RPC_HTTP:=$RPC_DEFAULT_HTTP}"; : "${RPC_WSS:=$RPC_DEFAULT_WSS}"
  echo -ne "${YELLOW}Введите Solana RPC HTTP [${RPC_HTTP}]: ${NC}"; read ans; RPC_HTTP=${ans:-$RPC_HTTP}
  echo -ne "${YELLOW}Введите Solana RPC WSS [${RPC_WSS}]: ${NC}"; read ans; RPC_WSS=${ans:-$RPC_WSS}
  echo -ne "${YELLOW}Придумайте OFFSET для ноды (8–10 цифр): ${NC}"; read OFFSET
  OFFSET=$(printf '%s' "$OFFSET" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')
  if [ -z "$OFFSET" ]; then echo -e "${RED}OFFSET пустой. Отмена.${NC}"; exit 1; fi
  #[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(curl -4 -s https://ipecho.net/plain || true)
  #echo -ne "${YELLOW}Введи публичный IP [${PUBLIC_IP:-auto}]: ${NC}"; read ans; PUBLIC_IP=${ans:-$PUBLIC_IP}
  # Определяем публичный IP
  PUBLIC_IP=$(curl -4 -s https://ipecho.net/plain || true)
  if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}Не удалось определить IP, укажите вручную:${NC}"
    echo -ne "${YELLOW}Введите IP этого сервера: ${NC}"
    read -r PUBLIC_IP
  else
    echo -e "${PURPLE}Обнаружен публичный IP: ${CYAN}${PUBLIC_IP}${NC}"
  fi

  sleep 2

  # Сохраняем .env
  cat > "$ENV_FILE" <<EOF
BASE_DIR="$WORKDIR"
IMAGE="$IMAGE_TAG"
CONTAINER="$CONTAINER_NAME"
RPC_HTTP="$RPC_HTTP"
RPC_WSS="$RPC_WSS"
OFFSET="$OFFSET"
PUBLIC_IP="$PUBLIC_IP"
EOF

  # Генерация ключей (+сид-фразы в файлы)
  if [ ! -f "$NODE_KP" ]; then
    echo -e "${BLUE}Генерируем node-keypair.json...${NC}"
    (solana-keygen new --no-passphrase --force --outfile "$NODE_KP" | tee "$SEED_NODE") || true
  fi
  if [ ! -f "$CALLBACK_KP" ]; then
    echo -e "${BLUE}Генерируем callback-kp.json...${NC}"
    (solana-keygen new --no-passphrase --force --outfile "$CALLBACK_KP" | tee "$SEED_CALLBACK") || true
  fi
  [ -f "$NODE_KP" ] && chmod 600 "$NODE_KP" || true
  [ -f "$CALLBACK_KP" ] && chmod 600 "$CALLBACK_KP" || true
  [ -f "$SEED_NODE" ] && chmod 600 "$SEED_NODE" || true
  [ -f "$SEED_CALLBACK" ] && chmod 600 "$SEED_CALLBACK" || true

  # Identity PEM для p2p
  [ -f "$IDENTITY_PEM" ] || openssl genpkey -algorithm Ed25519 -out "$IDENTITY_PEM" >/dev/null 2>&1 || true

  # Пишем node-config.toml (структура по актуальным гайдам)
  cat > "$CFG_FILE" <<EOF
[node]
offset = $OFFSET
hardware_claim = 0
starting_epoch = 0
ending_epoch = 9223372036854775807

[network]
address = "0.0.0.0"

[solana]
endpoint_rpc = "$RPC_HTTP"
endpoint_wss = "$RPC_WSS"
cluster = "Devnet"
commitment.commitment = "confirmed"
EOF

  # Показ адресов + попытка airdrop
  NODE_PK=$(solana address --keypair "$NODE_KP" 2>/dev/null || echo N/A)
  CB_PK=$(solana address --keypair "$CALLBACK_KP" 2>/dev/null || echo N/A)
  echo -e "${PURPLE}Адреса:${NC}\n  Node: $NODE_PK\n  Callback: $CB_PK"
  echo -e "${BLUE}Пробуем получить Devnet токены по 2 SOL на оба адреса...${NC}"
  solana airdrop 2 "$NODE_PK" -u devnet >/dev/null 2>&1 || true
  solana airdrop 2 "$CB_PK" -u devnet >/dev/null 2>&1 || true

  # Инициализация on-chain аккаунтов ноды
  echo -e "${BLUE}Инициализируем on-chain аккаунты (arcium init-arx-accs)...${NC}"
  (cd "$WORKDIR" && arcium init-arx-accs \
    --keypair-path "$NODE_KP" \
    --callback-keypair-path "$CALLBACK_KP" \
    --peer-keypair-path "$IDENTITY_PEM" \
    --node-offset "$OFFSET" \
    --ip-address "$PUBLIC_IP" \
    --rpc-url "$RPC_HTTP") || true

  # Образ и запуск контейнера
  echo -e "${BLUE}Тяну образ и запускаю контейнер...${NC}"
  docker pull "$IMAGE_TAG"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d \
    --name "$CONTAINER_NAME" \
    -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
    -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
    -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
    -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
    -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
    -v "$CFG_FILE:/usr/arx-node/arx/node_config.toml" \
    -v "$NODE_KP:/usr/arx-node/node-keys/node_keypair.json:ro" \
    -v "$NODE_KP:/usr/arx-node/node-keys/operator_keypair.json:ro" \
    -v "$CALLBACK_KP:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
    -v "$IDENTITY_PEM:/usr/arx-node/node-keys/node_identity.pem:ro" \
    -v "$LOGS_DIR:/usr/arx-node/logs" \
    -p 8080:8080 \
    "$IMAGE_TAG"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${YELLOW}Команда для логов внутри контейнера:${NC}"
  echo "docker exec -it ${CONTAINER_NAME} sh -lc 'tail -n +1 -f \"$(ls -t /usr/arx-node/logs/arx_log_*.log 2>/dev/null | head -1)\"'"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  sleep 2
  docker exec -it ${CONTAINER_NAME} sh -lc 'tail -f /usr/arx-node/logs/arx_log_*.log'
  ;;

# ========== 3) Управление контейнером (start/restart/stop/rm/status) ==========
3)
  while true; do
    echo -e "${YELLOW}Управление контейнером:${NC}"
    echo -e "${CYAN}1) Запустить${NC}"
    echo -e "${CYAN}2) Перезапустить${NC}"
    echo -e "${CYAN}3) Остановить${NC}"
    echo -e "${CYAN}4) Удалить${NC}"
    echo -e "${CYAN}5) Статус${NC}"
    echo -e "${CYAN}0) Назад${NC}"
    echo -ne "${YELLOW}Введите номер: ${NC}"; read m
    case "$m" in
      1) 
        if docker start "$CONTAINER_NAME" >/dev/null 2>&1; then 
          echo -e "${GREEN}Запущен.${NC}"
        else
          echo -e "${BLUE}Контейнера нет — запускаем с нужными томами...${NC}"
          docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
          docker run -d \
            --name "$CONTAINER_NAME" \
            -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
            -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
            -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
            -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
            -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
            -v "$CFG_FILE:/usr/arx-node/arx/node_config.toml" \
            -v "$NODE_KP:/usr/arx-node/node-keys/node_keypair.json:ro" \
            -v "$NODE_KP:/usr/arx-node/node-keys/operator_keypair.json:ro" \
            -v "$CALLBACK_KP:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
            -v "$IDENTITY_PEM:/usr/arx-node/node-keys/node_identity.pem:ro" \
            -v "$LOGS_DIR:/usr/arx-node/logs" \
            -p 8080:8080 \
            "$IMAGE_TAG"
          echo -e "${GREEN}Запущен.${NC}"
        fi
        ;;
      2) docker restart "$CONTAINER_NAME" && echo -e "${GREEN}Перезапущен.${NC}" || echo -e "${RED}Не запущен.${NC}" ;;
      3) docker stop "$CONTAINER_NAME" && echo -e "${GREEN}Остановлен.${NC}" || true ;;
      4) docker rm -f "$CONTAINER_NAME" && echo -e "${GREEN}Удалён.${NC}" || true ;;
      5) docker ps -a --filter "name=$CONTAINER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' ;;
      0) break ;;
      *) ;;
    esac
  done
  ;;

# =================== 4) Конфигурация RPC (sed) ==================
4)
  [ -f "$ENV_FILE" ] && . "$ENV_FILE"
  : "${RPC_HTTP:=$RPC_DEFAULT_HTTP}"; : "${RPC_WSS:=$RPC_DEFAULT_WSS}"
  echo -ne "${YELLOW}Новый RPC_HTTP [${RPC_HTTP}]: ${NC}"; read x; RPC_HTTP=${x:-$RPC_HTTP}
  echo -ne "${YELLOW}Новый RPC_WSS  [${RPC_WSS}]: ${NC}"; read y; RPC_WSS=${y:-$RPC_WSS}
  if [ ! -f "$CFG_FILE" ]; then echo -e "${RED}Файл конфигурации не найден: $CFG_FILE${NC}"; exit 1; fi
  sed -i -E \
    -e 's|^([[:space:]]*endpoint_rpc[[:space:]]*=[[:space:]]*").*(")|\1'"$RPC_HTTP"'\2|g' \
    -e 's|^([[:space:]]*endpoint_wss[[:space:]]*=[[:space:]]*").*(")|\1'"$RPC_WSS"'\2|g' \
    "$CFG_FILE"
  # Обновим .env
  grep -q '^RPC_HTTP=' "$ENV_FILE" 2>/dev/null && sed -i "s|^RPC_HTTP=.*|RPC_HTTP=\"$RPC_HTTP\"|" "$ENV_FILE" || echo "RPC_HTTP=\"$RPC_HTTP\"" >> "$ENV_FILE"
  grep -q '^RPC_WSS=' "$ENV_FILE" 2>/dev/null && sed -i "s|^RPC_WSS=.*|RPC_WSS=\"$RPC_WSS\"|" "$ENV_FILE" || echo "RPC_WSS=\"$RPC_WSS\"" >> "$ENV_FILE"
  echo -e "${GREEN}RPC обновлены. Перезапустить контейнер сейчас? (y/N)${NC}"; read z
  [[ "$z" =~ ^[Yy]$ ]] && docker restart "$CONTAINER_NAME" || true

  docker exec -it ${CONTAINER_NAME} sh -lc 'tail -f /usr/arx-node/logs/arx_log_*.log'
  ;;

# ======= 5) Инструменты: логи, статус, активность, кластеры, ключи =======
5)
  while true; do
    echo -e "${YELLOW}Инструменты:${NC}"
    echo -e "${CYAN}1) Логи (онлайн)${NC}"
    echo -e "${CYAN}2) Статус ноды (arx-info)${NC}"
    echo -e "${CYAN}3) Проверить активность ноды (arx-active)${NC}"
    echo -e "${CYAN}4) Отправить приглашение в кластер (propose-join-cluster)${NC}"
    echo -e "${CYAN}5) Вступить в кластер (join-cluster)${NC}"
    echo -e "${CYAN}6) Проверить членство ноды в кластере${NC}"
    echo -e "${CYAN}7) Показать адреса и балансы${NC}"
    echo -e "${CYAN}8) Devnet Airdrop (2 SOL на каждый адрес)${NC}"
    echo -e "${CYAN}9) Показать сид-фразы (с маской)${NC}"
    echo -e "${CYAN}0) Назад${NC}"
    echo -ne "${YELLOW}Введите номер: ${NC}"; read t
    case "$t" in
      1)
        echo -e "${PURPLE}Ctrl+C для выхода из логов${NC}"
        sleep 2
        docker exec -it "$CONTAINER_NAME" sh -lc 'tail -n +1 -f "$(ls -t /usr/arx-node/logs/arx_log_*.log 2>/dev/null | head -1)"' || true
        ;;
      2)
        [ -f "$ENV_FILE" ] && . "$ENV_FILE"; : "${RPC_HTTP:=$RPC_DEFAULT_HTTP}"; : "${OFFSET:=$OFFSET}"
        if [ -z "$OFFSET" ]; then echo -ne "${YELLOW}OFFSET ноды: ${NC}"; read OFFSET; fi
        arcium arx-info "$OFFSET" --rpc-url "$RPC_HTTP" || true
        ;;
      3)
        [ -f "$ENV_FILE" ] && . "$ENV_FILE"; : "${RPC_HTTP:=$RPC_DEFAULT_HTTP}"; : "${OFFSET:=$OFFSET}"
        if [ -z "$OFFSET" ]; then echo -ne "${YELLOW}OFFSET ноды: ${NC}"; read OFFSET; fi
        arcium arx-active "$OFFSET" --rpc-url "$RPC_HTTP" || true
        ;;
      4)
        [ -f "$ENV_FILE" ] && . "$ENV_FILE"
        echo -ne "${YELLOW}CLUSTER OFFSET (пусто = 10102025): ${NC}"; read COFF; [ -z "$COFF" ] && COFF=10102025
        echo -ne "${YELLOW}Какой NODE OFFSET приглашаем (пусто = ваш из .env)? ${NC}"; read NOFF
        [ -z "$NOFF" ] && NOFF="$OFFSET"
        (cd "$WORKDIR" && arcium propose-join-cluster \
          --keypair-path "$NODE_KP" \
          --node-offset "$NOFF" \
          --cluster-offset "$COFF" \
          --rpc-url "$RPC_HTTP") || true
        ;;
      5)
        [ -f "$ENV_FILE" ] && . "$ENV_FILE"
        echo -ne "${YELLOW}CLUSTER OFFSET: ${NC}"; read COFF
        if [ -z "$COFF" ]; then echo -e "${RED}Пусто — отмена.${NC}"; else
          (cd "$WORKDIR" && arcium join-cluster true \
            --keypair-path "$NODE_KP" \
            --node-offset "$OFFSET" \
            --cluster-offset "$COFF" \
            --rpc-url "$RPC_HTTP") || true
        fi
        ;;
      6)
        [ -f "$ENV_FILE" ] && . "$ENV_FILE"
        echo -ne "${YELLOW}CLUSTER OFFSET: ${NC}"; read COFF
        echo -ne "${YELLOW}NODE OFFSET: ${NC}"; read NOFF
        if [ -z "$COFF" ] || [ -z "$NOFF" ]; then echo -e "${RED}Пустые значения.${NC}"; else
          if arcium arx-info "$NOFF" --rpc-url "$RPC_HTTP" | awk -v c="$COFF" ' /^Cluster memberships:/ { inlist=1; next } inlist { if ($0 ~ /^[[:space:]]*$/) { inlist=0; next } if (index($0, c)) { found=1 } } END { exit(found?0:1) }'; then
            echo -e "${GREEN}Нода $NOFF В КЛАСТЕРЕ $COFF${NC}"
          else
            echo -e "${PURPLE}Нода $NOFF НЕ найдена в кластере $COFF${NC}"
          fi
        fi
        ;;
      7)
        NODE_PK=$(solana address --keypair "$NODE_KP" 2>/dev/null || echo N/A)
        CB_PK=$(solana address --keypair "$CALLBACK_KP" 2>/dev/null || echo N/A)
        echo -e "${PURPLE}Адреса:${NC}\n  Node: $NODE_PK\n  Callback: $CB_PK"
        echo -e "${PURPLE}Балансы (devnet):${NC}"
        NB=$(solana balance -u devnet --keypair "$NODE_KP" 2>/dev/null | awk '{print $1+0}' 2>/dev/null || echo 0)
        CB=$(solana balance -u devnet --keypair "$CALLBACK_KP" 2>/dev/null | awk '{print $1+0}' 2>/dev/null || echo 0)
        echo "  Node: ${NB} SOL"
        echo "  Callback: ${CB} SOL"
        ;;
      8)
        NODE_PK=$(solana address --keypair "$NODE_KP"); CB_PK=$(solana address --keypair "$CALLBACK_KP")
        solana airdrop 2 "$NODE_PK" -u devnet >/dev/null 2>&1 || true
        solana airdrop 2 "$CB_PK" -u devnet >/dev/null 2>&1 || true
        echo -e "${GREEN}Готово. Посмотрите п.7 для балансов.${NC}"
        ;;
      9)
        if [ -f "$SEED_NODE" ]; then
          masked=$(awk '{ n=split($0,w," "); if(n==0){print ""; exit} for(i=1;i<=n;i++){ if(i<=4 || i>n-4){printf "%s ", w[i]} else{printf "••• "} } printf "(%d words)
", n }' "$SEED_NODE")
          echo "Node seed: $masked"
          echo -ne "Показать полностью? Напишите YES: "; read zz; [ "$zz" = "YES" ] && echo "FULL: $(cat "$SEED_NODE")"
        else
          echo "Node seed: файл не найден ($SEED_NODE)"
        fi
        if [ -f "$SEED_CALLBACK" ]; then
          masked=$(awk '{ n=split($0,w," "); if(n==0){print ""; exit} for(i=1;i<=n;i++){ if(i<=4 || i>n-4){printf "%s ", w[i]} else{printf "••• "} } printf "(%d words)
", n }' "$SEED_CALLBACK")
          echo "Callback seed: $masked"
          echo -ne "Показать полностью? Напишите YES: "; read zz; [ "$zz" = "YES" ] && echo "FULL: $(cat "$SEED_CALLBACK")"
        else
          echo "Callback seed: файл не найден ($SEED_CALLBACK)"
        fi
        ;;
      0) break ;;
      *) ;;
    esac
  done
  ;;

# =============================== 6) Выход ==============================
6)
  echo -e "${RED}Полное удаление ноды...${NC}"
  docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker rmi -f "$IMAGE_TAG" >/dev/null 2>&1 || true
  rm -rf "$WORKDIR" "$HOME/.arcium" "$HOME/.cargo/bin/arcium" "$HOME/.cargo/bin/arcup"
  echo -e "${GREEN}Все контейнеры, образы и файлы Arcium удалены.${NC}"
  ;;

# ============================ Неверный ввод ===========================
*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}" ;;

esac
