#!/bin/bash

# Цвета текста
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Отображение логотипа
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

SWAPFILE="/swapfile"

# Выводим меню (пункты в CYAN)
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Добавление файла подкачки${NC}"
echo -e "${CYAN}2) Изменение размера файла подкачки${NC}"
echo -e "${CYAN}3) Удаление файла подкачки${NC}"

# Запрос ввода у пользователя (в желтом)
read -p "Введите номер: " option

case $option in
  1)
    # Добавление файла подкачки
    if [ -e "$SWAPFILE" ]; then
      echo -e "${RED}Файл подкачки уже существует. Если нужно изменить его размер, выберите опцию 2.${NC}"
      exit 1
    fi
    read -p $'\033[0;33mВведите размер файла подкачки в ГБ: \033[0m' size
    echo -e "${BLUE}Создаётся файл подкачки размером ${size}G...${NC}"
    # Пытаемся создать файл с помощью fallocate, если не получится – используем dd
    if ! sudo fallocate -l "${size}G" $SWAPFILE; then
      sudo dd if=/dev/zero of=$SWAPFILE bs=1G count=$size
    fi
    sudo chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
    sudo swapon $SWAPFILE
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
    echo -e "${GREEN}Файл подкачки размером ${size}G успешно создан и активирован.${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    ;;
  2)
    # Изменение размера файла подкачки
    if [ ! -e "$SWAPFILE" ]; then
      echo -e "${RED}Файл подкачки не существует. Сначала создайте его, выбрав опцию 1.${NC}"
      exit 1
    fi
    read -p $'\033[0;33mВведите новый размер файла подкачки в ГБ: \033[0m' size
    echo -e "${BLUE}Изменяем размер файла подкачки на ${size}G...${NC}"
    sudo swapoff $SWAPFILE
    sudo rm -f $SWAPFILE
    if ! sudo fallocate -l "${size}G" $SWAPFILE; then
      sudo dd if=/dev/zero of=$SWAPFILE bs=1G count=$size
    fi
    sudo chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
    sudo swapon $SWAPFILE
    # Обновляем запись в /etc/fstab: удаляем старую и добавляем новую
    sudo sed -i "\|$SWAPFILE|d" /etc/fstab
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
    echo -e "${GREEN}Файл подкачки изменён: новый размер ${size}G.${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    ;;
  3)
    # Удаление файла подкачки
    if [ ! -e "$SWAPFILE" ]; then
      echo -e "${RED}Файл подкачки не существует.${NC}"
      exit 1
    fi
    echo -e "${BLUE}Удаляем файл подкачки...${NC}"
    sudo swapoff $SWAPFILE
    sudo rm -f $SWAPFILE
    sudo sed -i "\|$SWAPFILE|d" /etc/fstab
    echo -e "${GREEN}Файл подкачки удалён.${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
    echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
    ;;
  *)
    echo -e "${RED}Неверная опция. Выход.${NC}"
    exit 1
    ;;
esac
