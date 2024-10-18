#!/bin/bash

# Вставляем наш шаблон start_bash
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

if ! command -v curl &> /dev/null; then
    echo "curl не установлен, выполняем установку..."
    sudo apt update
    sudo apt install curl -y
else
    echo "curl уже установлен."
fi

# Меню
echo "Выберите действие:"
echo "1) Установка ноды"
echo "2) Обновление ноды"
echo "3) Изменение комиссии"
echo "4) Удаление ноды"
echo "5) Полезные команды"

read -p "Введите номер: " choice

case $choice in
    1)
        echo "Устанавливаем ноду Hemi..."

        # Обновляем и устанавливаем необходимые пакеты
        sudo apt update && sudo apt upgrade -y

        # Проверка и установка tar, если его нет
        if ! command -v tar &> /dev/null; then
            echo "tar не установлен, выполняем установку..."
            sudo apt install tar -y
        else
            echo "tar уже установлен."
        fi

        # Установка бинарника
        echo "Загружаем бинарник Hemi..."
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.4.5/heminetwork_v0.4.5_linux_amd64.tar.gz

        # Создание директории и извлечение бинарника
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.4.5_linux_amd64.tar.gz -C hemi
        cd hemi

        # Создание tBTC кошелька
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

        # Вывод содержимого файла popm-address.json
        echo "Сохраните эти данные в надежное место:"
        cat ~/popm-address.json
        echo "Ваш pubkey_hash — это ваш tBTC адрес, на который нужно запросить тестовые токены в Discord проекта."

        # Создание файла popmd.env
        read -p "Введите ваш приватный ключ от кошелька: " PRIV_KEY
        read -p "Укажите желаемый размер комиссии (минимум 50): " FEE

        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env

        # Создание сервисного файла hemi.service
        sudo bash -c 'cat <<EOT > /etc/systemd/system/hemi.service
[Unit]
Description=PopMD Service
After=network.target

[Service]
EnvironmentFile=/root/hemi/popmd.env
ExecStart=/root/hemi/popmd
WorkingDirectory=/root/hemi/
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOT'

        # Обновление сервисов и включение hemi
        sudo systemctl daemon-reload
        sudo systemctl enable hemi

        # Запуск ноды
        sudo systemctl start hemi

        echo "Установка завершена и нода запущена!"
        ;;
    *)
        echo "Неверный выбор, попробуйте снова."
        ;;
esac
