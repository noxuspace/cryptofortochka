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
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

# скачиваем node_exporter, разархивируем, прописываем права, удаляем лищнее
cd $HOME && \
wget https://github.com/prometheus/node_exporter/releases/download/v1.2.0/node_exporter-1.2.0.linux-amd64.tar.gz
tar xvf node_exporter-1.2.0.linux-amd64.tar.gz
rm node_exporter-1.2.0.linux-amd64.tar.gz
sudo mv node_exporter-1.2.0.linux-amd64 node_exporter
chmod +x $HOME/node_exporter/node_exporter
mv $HOME/node_exporter/node_exporter /usr/bin
rm -Rvf $HOME/node_exporter/
# создаём файл сервиса exporterd
sudo tee /etc/systemd/system/exporterd.service > /dev/null <<EOF
[Unit]
Description=node_exporter
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
# запускаем сервис exporterd
sudo systemctl daemon-reload
sudo systemctl enable exporterd
sudo systemctl restart exporterd
# Открываем порт 9100
sudo ufw allow 9100 
