#!/bin/bash

BLUE='\033[0;34m'  # Синий цвет
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Без цвета

while true
do
    printf "${BLUE}Проверяем логи ноды...${NC}\n"
    
    logs=$(journalctl -n 10 -u aios)

    # Search the logs for the specific pattern and save the result
    search_result=$(echo "$logs" | grep "Last pong received.*Sending reconnect signal..")

    # Use the search result in an if statement
    if [ -n "$search_result" ]; then
        echo -e "${RED}Нода не подключена, перезапускаем...${NC}"
        # Restart the application service
        systemctl restart aios
    else
        echo -e "${GREEN}Нет необходимсоти для перезапуска. Похоже, что нода работает нормально!${NC}"
    fi

    sleep 15m
done
