#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Проверка запуска от root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Скрипт должен быть запущен с правами root.${NC}"
    exit 1
fi

# Проверка наличия X-сервера и настройки $DISPLAY
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
    echo -e "${YELLOW}Переменная DISPLAY установлена в :0.${NC}"
fi

# Настройка xhost для предоставления доступа
xhost +local:root &> /dev/null || echo -e "${YELLOW}Не удалось настроить xhost. Убедитесь, что X-сервер работает.${NC}"

# Создание systemd-сервиса для OpenLedger
echo -e "${YELLOW}Создаем systemd-сервис...${NC}"
cat > /etc/systemd/system/openledger.service << EOF
[Unit]
Description=OpenLedger Node
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openledger-node --no-sandbox --disable-gpu --headless
Restart=always
Environment=DISPLAY=:0
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd, запуск и включение сервиса
systemctl daemon-reload
systemctl enable openledger.service
systemctl start openledger.service

# Проверка статуса сервиса
if systemctl is-active --quiet openledger.service; then
    echo -e "${GREEN}OpenLedger успешно запущен как сервис.${NC}"
else
    echo -e "${RED}Ошибка запуска OpenLedger. Проверьте логи с помощью:${NC}"
    echo -e "journalctl -u openledger.service"
fi
