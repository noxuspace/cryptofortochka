#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
CLI_BINARY="/usr/local/bin/optimai-cli"
CLI_DOWNLOAD_URL="https://optimai.network/download/cli-node/linux"

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
  $SUDO apt-get update && $SUDO apt-get install -y curl
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh 2>/dev/null | bash || true

# ============================== Меню =========================
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды OptimAI${NC}"
echo -e "${CYAN}2) Управление нодой${NC}"
echo -e "${CYAN}3) Информация о ноде и аккаунте${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in

# ===================== 1) Установка ноды OptimAI ===================
1)
  echo -e "${BLUE}Установка ноды OptimAI...${NC}"
  SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")

  # Обновление пакетов
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y curl

  # Docker — ставим только если ещё нет
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${BLUE}Устанавливаем Docker...${NC}"
    $SUDO apt-get install -y docker.io
    $SUDO systemctl enable docker 2>/dev/null || true
    $SUDO systemctl start docker 2>/dev/null || true
    [ -S /var/run/docker.sock ] && $SUDO chmod 666 /var/run/docker.sock 2>/dev/null || true
    $SUDO usermod -aG docker "$USER" 2>/dev/null || true
    echo -e "${YELLOW}Возможно, потребуется выйти и войти снова, чтобы docker работал без sudo.${NC}"
  else
    echo -e "${GREEN}Docker уже установлен.${NC}"
  fi

  # Проверка, запущен ли Docker
  if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}Запускаем Docker...${NC}"
    $SUDO systemctl start docker 2>/dev/null || true
    sleep 2
  fi

  # Загрузка OptimAI CLI
  echo -e "${BLUE}Загружаем OptimAI CLI...${NC}"
  cd /tmp
  curl -L "$CLI_DOWNLOAD_URL" -o optimai-cli
  chmod +x optimai-cli
  $SUDO mv optimai-cli "$CLI_BINARY"

  echo -e "${GREEN}OptimAI CLI установлен в $CLI_BINARY${NC}"

  # Вход в аккаунт
  echo -e "${BLUE}Войдите в свой аккаунт OptimAI (email и пароль):${NC}"
  $CLI_BINARY auth login

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Установка завершена!${NC}"
  echo -e "${GREEN}Перейдите к пункту 2 для запуска ноды: optimai-cli node start${NC}"
  echo -e "${CYAN}Документация: https://github.com/OptimaiNetwork/OptimAI-CLI-Node${NC}"
  echo -e "${CYAN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
  echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ========== 2) Управление нодой (start/stop/status) ==========
2)
  if [ ! -f "$CLI_BINARY" ]; then
    echo -e "${RED}OptimAI CLI не найден. Выполните пункт 1) Установка ноды.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Управление нодой OptimAI:${NC}"
  echo -e "${CYAN}1) Запустить ноду (foreground)${NC}"
  echo -e "${CYAN}2) Запустить ноду в фоне (screen)${NC}"
  echo -e "${CYAN}3) Остановить ноду${NC}"
  echo -e "${CYAN}4) Статус ноды${NC}"
  echo -ne "${YELLOW}Введите номер: ${NC}"; read -r m

  case "$m" in
    1)
      echo -e "${PURPLE}Ctrl+C для остановки ноды и выхода из логов${NC}"
      $CLI_BINARY node start
      ;;
    2)
      if command -v screen >/dev/null 2>&1; then
        if screen -list | grep -q "optimai"; then
          echo -e "${YELLOW}Сессия optimai уже существует. Подключиться: screen -r optimai${NC}"
        else
          screen -dmS optimai $CLI_BINARY node start
          echo -e "${GREEN}Нода запущена в фоне. Подключиться: screen -r optimai${NC}"
          echo -e "${YELLOW}Отсоединиться: Ctrl+A затем D${NC}"
        fi
      else
        echo -e "${YELLOW}screen не установлен. Устанавливаем...${NC}"
        SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
        $SUDO apt-get install -y screen
        screen -dmS optimai $CLI_BINARY node start
        echo -e "${GREEN}Нода запущена в фоне. Подключиться: screen -r optimai${NC}"
      fi
      ;;
    3)
      PIDS=$(pgrep -f "optimai-cli" 2>/dev/null || true)
      if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs kill 2>/dev/null && echo -e "${GREEN}Нода остановлена (PID: $PIDS).${NC}" || {
          echo -e "${YELLOW}Попытка принудительной остановки...${NC}"
          echo "$PIDS" | xargs kill -9 2>/dev/null && echo -e "${GREEN}Нода остановлена.${NC}" || echo -e "${RED}Не удалось остановить. Попробуйте вручную: kill -9 $PIDS${NC}"
        }
      else
        echo -e "${YELLOW}Активный процесс ноды не найден. Возможно, нода уже остановлена.${NC}"
        $CLI_BINARY node status
      fi
      ;;
    4)
      $CLI_BINARY node status
      ;;
    *)
      echo -e "${RED}Неверный выбор.${NC}"
      ;;
  esac
  ;;

# ======= 3) Информация о ноде и аккаунте =======
3)
  if [ ! -f "$CLI_BINARY" ]; then
    echo -e "${RED}OptimAI CLI не найден. Выполните пункт 1) Установка ноды.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Инструменты:${NC}"
  echo -e "${CYAN}1) Статус ноды${NC}"
  echo -e "${CYAN}2) Информация об аккаунте${NC}"
  echo -e "${CYAN}3) Баланс наград${NC}"
  echo -e "${CYAN}4) Обновить CLI${NC}"
  echo -ne "${YELLOW}Введите номер: ${NC}"; read -r t

  case "$t" in
    1)
      $CLI_BINARY node status
      ;;
    2)
      $CLI_BINARY auth status
      echo ""
      $CLI_BINARY auth me
      ;;
    3)
      $CLI_BINARY rewards balance
      ;;
    4)
      $CLI_BINARY update
      echo -e "${GREEN}CLI обновлён.${NC}"
      ;;
    *)
      echo -e "${RED}Неверный выбор.${NC}"
      ;;
  esac
  ;;

# =============================== 4) Удаление ==============================
4)
  echo -e "${RED}Полностью удалить OptimAI CLI и остановить ноду? (YES/NO)${NC}"
  read -r CONFIRM
  if [ "$CONFIRM" = "YES" ]; then
    echo -e "${RED}Удаляю...${NC}"

    # Остановить ноду, если запущена
    PIDS=$(pgrep -f "optimai-cli" 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
      echo "$PIDS" | xargs kill 2>/dev/null || true
      echo -e "${GREEN}Процессы ноды остановлены.${NC}"
    fi

    # Удалить CLI
    SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")
    $SUDO rm -f "$CLI_BINARY" 2>/dev/null || true

    echo -e "${GREEN}OptimAI CLI удалён.${NC}"
    echo -e "${YELLOW}Docker оставлен (можно удалить вручную, если не нужен).${NC}"
  else
    echo -e "${PURPLE}Отмена. Ничего не изменено.${NC}"
  fi
  ;;

*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
  ;;
esac
