#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды${NC}"
echo -e "${CYAN}2) Получение роли${NC}"
echo -e "${CYAN}3) Регистрация валидатора${NC}"
echo -e "${CYAN}4) Обновление ноды${NC}"
echo -e "${CYAN}5) Просмотр логов${NC}"
echo -e "${CYAN}6) Рестарт ноды${NC}"
echo -e "${CYAN}7) Удаление ноды${NC}"

echo -e "${YELLOW}Введите номер:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Установка зависимостей...${NC}"
        sudo apt-get update && sudo apt-get upgrade -y
        
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2      
        ;;
    2)
        
      
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        ;;
    3)
        


        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Вернитесь к текстовому гайду!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        cd
        ;;
    4)
        echo -e "${GREEN}У вас актуальная версия ноды Aztec!${NC}"
        ;;
    5)
        
        ;;
    6)
        
        ;;
    7)
        echo -e "${BLUE}Удаление ноды Drosera...${NC}"

        
        
        # Заключительное сообщение
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 1
        ;;
    *)
        echo -e "${RED}Неверный выбор. Пожалуйста, выберите пункт из меню.${NC}"
        ;;
esac


       
