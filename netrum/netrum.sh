#!/usr/bin/env bash

# =========================== Цвета ===========================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# ======================= Базовые переменные ==================
APP_DIR="$HOME/netrum-lite-node"
SUDO=$(command -v sudo >/dev/null 2>&1 && echo sudo || echo "")

# ===================== Проверка curl + лого ===================
if ! command -v curl >/dev/null 2>&1; then
  $SUDO apt-get update -y && $SUDO apt-get install -y curl
fi
sleep 1
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# ============================== Меню =========================
echo
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Подготовка сервера${NC}"
echo -e "${CYAN}2) Установка ноды Netrum${NC}"
echo -e "${CYAN}3) Управление нодой${NC}"
echo -e "${CYAN}4) Удаление ноды${NC}"
echo -ne "${YELLOW}Введите номер: ${NC}"; read choice

case "$choice" in

# ===================== 1) Подготовка сервера ===================
1)
  echo -e "${YELLOW}Подготавливаем сервер...${NC}"
  $SUDO apt-get update -y && $SUDO apt-get upgrade -y
  $SUDO apt-get install -y curl git jq build-essential python3 make g++ wget

  $SUDO apt-get purge -y nodejs npm || true
  $SUDO apt-get autoremove -y
  $SUDO rm -f /usr/bin/node /usr/local/bin/node /usr/bin/npm /usr/local/bin/npm

  curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash -
  $SUDO apt-get install -y nodejs

  echo -e "${GREEN}✅ Node.js: $(node -v)${NC}"
  echo -e "${GREEN}✅ npm:     $(npm -v)${NC}"

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Подготовка сервера завершена, перейдите в текстовый гайд и следуйте дальнейшим инструкциям!${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ============== 2) Клонирование/обновление, npm i, link ==============
2)
  echo -e "${BLUE}Клонирую/обновляю репозиторий...${NC}"
  if [ -d "$APP_DIR" ]; then
    echo -e "${BLUE}Каталог уже существует: ${CYAN}$APP_DIR${PURPLE} — обновляю (git pull).${NC}"
    (cd "$APP_DIR" && git pull)
  else
    git clone https://github.com/NetrumLabs/netrum-lite-node.git "$APP_DIR"
  fi

  cd "$APP_DIR" || { echo -e "${RED}Не удалось войти в $APP_DIR${NC}"; exit 1; }

  echo -e "${BLUE}npm install...${NC}"
  npm install

  echo -e "${BLUE}npm link...${NC}"
  npm link

  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Установка завершена, перейдите в текстовый гайд и следуйте дальнейшим инструкциям!${NC}"
  echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
  ;;

# ============== 3) Управление нодой (вложенное меню, как у тебя) ==============
3)
  if ! command -v netrum >/dev/null 2>&1; then
    echo -e "${RED}CLI 'netrum' не найден. Сначала выполните пункт 2).${NC}"
    exit 1
  fi

  echo
  echo -e "${YELLOW}Управление нодой:${NC}"
  echo -e "${CYAN}1)  Проверка системы${NC}"
  echo -e "${CYAN}2)  Создать новый кошелёк${NC}"
  echo -e "${CYAN}3)  Импорт кошелька по приватному ключу${NC}"
  echo -e "${CYAN}4)  Показать баланс${NC}"
  echo -e "${CYAN}5)  Экспорт приватного ключа${NC}"
  echo -e "${CYAN}6)  Удалить кошелёк с сервера${NC}"
  echo -e "${CYAN}7)  Проверить наличие Base-name${NC}"
  echo -e "${CYAN}8)  Показать Node ID${NC}"
  echo -e "${CYAN}9)  Очистить Node ID${NC}"
  echo -e "${CYAN}10) Подписать сообщение ключом ноды${NC}"
  echo -e "${CYAN}11) Зарегистрировать ноду${NC}"
  echo -e "${CYAN}12) Запустить синхронизацию${NC}"
  echo -e "${CYAN}13) Логи синхронизации${NC}"
  echo -e "${CYAN}14) Запустить майнинг${NC}"
  echo -e "${CYAN}15) Логи майнинга${NC}"
  echo -e "${CYAN}16) Клейм наград${NC}"
  echo -e "${CYAN}17) Обновить CLI${NC}"
  echo -ne "${YELLOW}Введите номер: ${NC}"; read -r t

  case "$t" in
    1)  netrum-system ;;
    2)  netrum-new-wallet ;;
    3)  netrum-import-wallet ;;
    4)  netrum-wallet ;;
    5)  netrum-wallet-key ;;
    6)  netrum-wallet-remove ;;
    7)  netrum-check-basename ;;
    8)  netrum-node-id ;;
    9)  netrum-node-id-remove ;;
    10) netrum-node-sign ;;
    11) netrum-node-register ;;
    12) netrum-sync ;;
    13) netrum-sync-log ;;
    14) netrum-mining ;;
    15) netrum-mining-log ;;
    16) netrum-claim ;;
    17) netrum-update ;;
    *)  : ;;
  esac
  ;;

# =============================== 4) Удаление ==============================
4)
  if [ ! -d "$APP_DIR" ]; then
    echo -e "${PURPLE}Каталог ${CYAN}$APP_DIR${PURPLE} не найден. Нечего удалять.${NC}"
    exit 0
  fi
  echo -ne "${RED}Вы действительно хотите полностью удалить Netrum Lite Node? (YES/NO): ${NC}"
  read -r CONFIRM
  if [ "$CONFIRM" = "YES" ]; then
    echo -e "${RED}Удаляю...${NC}"
    rm -rf "$APP_DIR"
    if command -v netrum >/dev/null 2>&1; then
      echo -e "${BLUE}Удаляю глобальную ссылку CLI (npm unlink -g netrum-lite-node)...${NC}"
      npm unlink -g netrum-lite-node >/dev/null 2>&1 || true
    fi
    echo -e "${GREEN}Все файлы Netrum удалены.${NC}"
  else
    echo -e "${PURPLE}Отмена удаления. Ничего не изменено.${NC}"
  fi
  ;;

# ============================ Неверный ввод ===========================
*)
  echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}" ;;

esac
