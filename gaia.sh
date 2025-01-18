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

# Отображение логотипа
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Меню
echo -e "${YELLOW}Выберите действие:${NC}"
echo -e "${CYAN}1) Установка ноды Gaia${NC}"
echo -e "${CYAN}2) Запуск бота Gaia${NC}"
echo -e "${CYAN}3) Обновление ноды Gaia${NC}"
echo -e "${CYAN}4) Информация по ноде Gaia${NC}"
echo -e "${CYAN}5) Удаление ноды Gaia${NC}"
echo -e "${CYAN}6) Удаление бота Gaia${NC}"

read -p "Введите номер: " choice

case $choice in
    1)
        echo -e "${BLUE}Начинаем установку ноды Gaia...${NC}"

        # Обновление системы и установка зависимостей
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3-pip python3-dev python3-venv curl git
        sudo apt install -y build-essential
        pip3 install aiohttp

        # Установка Gaianet и других зависимостей
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
        sleep 5
        source ~/.bashrc

        # Инициализация ноды
        gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json  

        # Изменение порта
        sed -i 's/"llamaedge_port": "8080"/"llamaedge_port": "8781"/g' ~/gaianet/config.json

        # Запуск ноды
        gaianet start

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;

    2)
        echo -e "${BLUE}Запуск бота Gaia...${NC}"

        # Создание папки для бота
        mkdir -p ~/gaia-bot
        cd ~/gaia-bot
        
        # Добавление фраз в phrases.txt
        echo -e "\"Explain Einstein's theory of general relativity with mathematical proofs and real-world applications.\"" > phrases.txt
        echo -e "\"Describe quantum mechanics and its implications for modern technology.\"" >> phrases.txt
        echo -e "\"How does machine learning differ from traditional programming? Provide examples.\"" >> phrases.txt
        echo -e "\"What are the key challenges in building a decentralized autonomous organization (DAO)?\"" >> phrases.txt
        echo -e "\"Explain the process of photosynthesis in detail, including the chemical reactions involved.\"" >> phrases.txt
        echo -e "\"How do blockchain consensus mechanisms like Proof-of-Work and Proof-of-Stake differ?\"" >> phrases.txt
        echo -e "\"What are the primary components of a neural network, and how do they interact?\"" >> phrases.txt
        echo -e "\"Describe the history and evolution of the Internet, including key milestones.\"" >> phrases.txt
        echo -e "\"How does data encryption work, and what are the most secure algorithms available?\"" >> phrases.txt
        echo -e "\"What are the applications of Fourier transforms in signal processing and image compression?\"" >> phrases.txt
        echo -e "\"Explain the concept of entropy in thermodynamics with examples.\"" >> phrases.txt
        echo -e "\"What are the ethical implications of artificial intelligence in healthcare?\"" >> phrases.txt
        echo -e "\"How do you implement a distributed system for real-time data processing?\"" >> phrases.txt
        echo -e "\"Describe the differences between TCP and UDP protocols.\"" >> phrases.txt
        echo -e "\"What are the key differences between SQL and NoSQL databases?\"" >> phrases.txt
        echo -e "\"How does genetic engineering work, and what are its implications for society?\"" >> phrases.txt
        echo -e "\"Explain the difference between classical and quantum computing with examples.\"" >> phrases.txt
        echo -e "\"What are the challenges in creating an AI that can pass the Turing test?\"" >> phrases.txt
        echo -e "\"How does GPS technology work, and what are its limitations?\"" >> phrases.txt
        echo -e "\"What are the main challenges in developing fusion power plants?\"" >> phrases.txt
        echo -e "\"Describe the history of the Roman Empire in detail, including its rise and fall.\"" >> phrases.txt
        echo -e "\"How did the industrial revolution impact global society and economies?\"" >> phrases.txt
        echo -e "\"What are the key philosophical differences between existentialism and nihilism?\"" >> phrases.txt
        echo -e "\"Explain the causes and consequences of World War II in detail.\"" >> phrases.txt
        echo -e "\"What was the significance of the Renaissance period in European history?\"" >> phrases.txt
        echo -e "\"Describe the history of ancient Egypt, including its cultural and political achievements.\"" >> phrases.txt
        echo -e "\"What are the main ethical principles in utilitarianism and deontology?\"" >> phrases.txt
        echo -e "\"Explain the philosophy of Immanuel Kant and its influence on modern thought.\"" >> phrases.txt
        echo -e "\"How did the Cold War shape the political landscape of the 20th century?\"" >> phrases.txt
        echo -e "\"What are the origins and evolution of human rights as a concept?\"" >> phrases.txt
        echo -e "\"Write a detailed tutorial on how to create a blockchain from scratch in Python.\"" >> phrases.txt
        echo -e "\"How does garbage collection work in modern programming languages?\"" >> phrases.txt
        echo -e "\"Explain the differences between functional and object-oriented programming.\"" >> phrases.txt
        echo -e "\"What are the key principles of RESTful API design?\"" >> phrases.txt
        echo -e "\"How do you implement a graph traversal algorithm in Python?\"" >> phrases.txt
        echo -e "\"What are the best practices for securing a web application?\"" >> phrases.txt
        echo -e "\"How do neural networks use backpropagation for training?\"" >> phrases.txt
        echo -e "\"Describe the key differences between Docker and Kubernetes.\"" >> phrases.txt
        echo -e "\"What is the role of cryptography in securing blockchain networks?\"" >> phrases.txt
        echo -e "\"How do you design a scalable microservices architecture?\"" >> phrases.txt
        
        # Добавление ролей в roles.txt
        echo -e "system\nuser\nassistant\ntool" > roles.txt

        # Запрос адреса ноды
        echo -e "${YELLOW}Введите адрес вашей ноды${NC}"
        read -p "Адрес ноды: " NODE_ID

        # Создание скрипта для бота
echo -e "
import aiohttp
import asyncio
import random

# URL API
url = \"https://$NODE_ID.gaia.domains/v1/chat/completions\"

# Заголовки запроса
headers = {
    \"accept\": \"application/json\",
    \"Content-Type\": \"application/json\"
}

# Функция для чтения ролей и фраз из файлов
def load_from_file(file_name):
    with open(file_name, \"r\") as file:
        return [line.strip() for line in file.readlines()]

# Загрузка ролей и фраз
roles = load_from_file(\"roles.txt\")
phrases = load_from_file(\"phrases.txt\")

# Генерация случайного сообщения
def generate_random_message():
    role = random.choice(roles)
    content = random.choice(phrases)
    return {\"role\": role, \"content\": content}

# Создание сообщения
def create_message():
    user_message = generate_random_message()
    user_message[\"role\"] = \"user\"  # Гарантируем, что хотя бы одно сообщение — от 'user'
    other_message = generate_random_message()
    return [user_message, other_message]

# Отправка запроса к API
async def chat_loop():
    async with aiohttp.ClientSession() as session:
        while True:
            messages = create_message()
            user_message = next((msg[\"content\"] for msg in messages if msg[\"role\"] == \"user\"), \"No user message found\")
            
            # Логируем отправленный вопрос
            print(f\"Отправлен вопрос: {user_message}\")
            
            data = {\"messages\": messages}

            try:
                async with session.post(url, json=data, headers=headers, timeout=60) as response:
                    if response.status == 200:
                        result = await response.json()
                        assistant_response = result[\"choices\"][0][\"message\"][\"content\"]
                        print(f\"Получен ответ: {assistant_response}\n{'-'*50}\")
                    else:
                        print(f\"Ошибка: {response.status} - {await response.text()}\")
            except asyncio.TimeoutError:
                print(\"Тайм-аут ожидания. Отправляю следующий запрос...\")
            except Exception as e:
                print(f\"Ошибка: {e}\")

            # Небольшая задержка перед отправкой следующего сообщения
            await asyncio.sleep(1)

if __name__ == \"__main__\":
    asyncio.run(chat_loop())
" > gaia_bot.py

        # Определяем имя текущего пользователя и его домашнюю директорию
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

# Сервис для запуска бота
echo -e "[Unit]
Description=Gaia Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 $HOME_DIR/gaia-bot/gaia_bot.py
Restart=always
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$HOME_DIR/gaia-bot

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gaia-bot.service

        # Запуск бота
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable gaia-bot.service
        sudo systemctl start gaia-bot.service

        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "gaianet logs -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2

        # Проверка логов
        sudo journalctl -u gaia-bot -f
        ;;

    3)
        echo -e "${GREEN}У вас актуальная версия ноды Gaia.${NC}"
        ;;

    4)
        echo -e "${BLUE}Информация по ноде Gaia...${NC}"
        gaianet info
        ;;

    5)
        echo -e "${RED}Удаляем ноду Gaia...${NC}"
        gaianet stop
        rm -rf ~/gaianet
        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;

    6)
        echo -e "${RED}Удаляем бота Gaia...${NC}"
        sudo systemctl stop gaia-bot.service
        sudo systemctl disable gaia-bot.service
        sudo rm /etc/systemd/system/gaia-bot.service
        sudo systemctl daemon-reload
        sleep 1
        rm -rf ~/gaia-bot
        # Заключительный вывод
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — вся крипта в одном месте!${NC}"
        echo -e "${CYAN}Наш Telegram https://t.me/cryptoforto${NC}"
        sleep 2
        ;;

    *)
        echo -e "${RED}Неверный выбор!${NC}"
        ;;
esac
