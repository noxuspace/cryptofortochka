#!/bin/bash

# Цвета текста
WHITE='\033[1;37m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Выводим заголовок FORTOCHKA белым цветом
echo -e "${WHITE}FORTOCHKA${NC}"

# Обновляем систему и пакеты
sudo apt update && sudo apt upgrade -y

# Проверка, установлен ли Docker
if ! command -v docker &> /dev/null; then
    echo "Docker не установлен. Устанавливаем Docker..."
    sudo apt install docker.io -y
else
    echo "Docker уже установлен. Пропускаем установку."
fi

# Проверка, установлен ли Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не установлен. Устанавливаем Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose уже установлен. Пропускаем установку."
fi

# Клонируем репозиторий Uniswap Unichain Node
if [ ! -d "unichain-node" ]; then
    echo "Клонируем репозиторий Uniswap Unichain Node..."
    git clone https://github.com/Uniswap/unichain-node
else
    echo "Папка unichain-node уже существует. Пропускаем клонирование."
fi

# Переходим в директорию unichain-node
cd unichain-node || { echo "Не удалось войти в директорию unichain-node. Выход."; exit 1; }

# Проверяем, существует ли файл .env.sepolia
if [ -f ".env.sepolia" ]; then
    echo "Редактируем файл .env.sepolia..."
    
    # Меняем значение OP_NODE_L1_ETH_RPC
    sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
    
    # Меняем значение OP_NODE_L1_BEACON
    sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
    
    echo "Файл .env.sepolia успешно обновлен."
else
    echo "Файл .env.sepolia не найден. Выход."
    exit 1
fi

# Запуск контейнеров в фоновом режиме
echo "Запускаем контейнеры с помощью docker-compose..."
docker-compose up -d

# Команды для проверки после запуска
echo "-----------------------------------------------------------------------"
echo "Пробуем curl нашей ноды:"
echo 'curl -d '"'"'{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}'"'"' \'
echo '  -H "Content-Type: application/json" http://localhost:8545'
echo "-----------------------------------------------------------------------"

echo "Проверяем логи unichain-node-op-node-1:"
echo "docker logs unichain-node-op-node-1"
echo "-----------------------------------------------------------------------"

echo "Проверяем логи unichain-node-execution-client-1:"
echo "docker logs unichain-node-execution-client-1"
echo "-----------------------------------------------------------------------"

echo "Остановить ноду:"
echo "docker-compose down"
echo "-----------------------------------------------------------------------"

echo "Сделать рестарт:"
echo "docker-compose down"
echo "docker-compose up -d"
echo "-----------------------------------------------------------------------"

echo "Удалить ноду:"
echo "cd unichain-node"
echo "docker-compose down"
echo "sudo rm -r unichain-node"
echo "-----------------------------------------------------------------------"

# Заключительное сообщение
echo -e "${WHITE}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
