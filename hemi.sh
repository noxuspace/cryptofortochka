#!/bin/bash

# Вставляем наш шаблон start_bash
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_forto.sh | bash

if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Меню
echo -e "${GREEN}Выберите действие:${NC}"
echo -e "${GREEN}1) Установка ноды${NC}"
echo -e "${GREEN}2) Обновление ноды${NC}"
echo -e "${GREEN}3) Изменение комиссии${NC}"
echo -e "${GREEN}4) Удаление ноды${NC}"
echo -e "${GREEN}5) Полезные команды${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${GREEN}Устанавливаем ноду Hemi...${NC}"

        # Обновляем и устанавливаем необходимые пакеты
        sudo apt update && sudo apt upgrade -y

        # Проверка и установка tar, если его нет
        if ! command -v tar &> /dev/null; then
            echo -e "${GREEN}tar не установлен, выполняем установку...${NC}"
            sudo apt install tar -y
        else
            echo -e "${GREEN}tar уже установлен.${NC}"
        fi

        # Установка бинарника
        echo -e "${GREEN}Загружаем бинарник Hemi...${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.4.5/heminetwork_v0.4.5_linux_amd64.tar.gz

        # Создание директории и извлечение бинарника
        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.4.5_linux_amd64.tar.gz -C hemi
        cd hemi

        # Создание tBTC кошелька
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

        # Вывод содержимого файла popm-address.json
        echo -e "${GREEN}Сохраните эти данные в надежное место:${NC}"
        cat ~/popm-address.json
        echo -e "${GREEN}Ваш pubkey_hash — это ваш tBTC адрес, на который нужно запросить тестовые токены в Discord проекта.${NC}"

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

        echo -e "${GREEN}Установка завершена и нода запущена!${NC}"
        ;;
    *)
        echo -e "${GREEN}Неверный выбор, попробуйте снова.${NC}"
        ;;
esac
