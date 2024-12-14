# Проверка наличия Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker не установлен. Устанавливаем Docker...${NC}"
            sudo apt install docker.io -y
            echo -e "${GREEN}Docker успешно установлен!${NC}"
        else
            DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
            MIN_DOCKER_VERSION="27.2.0"
            if [[ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]]; then
                echo -e "${YELLOW}Docker версии $DOCKER_VERSION ниже необходимой $MIN_DOCKER_VERSION. Обновляем Docker...${NC}"
                sudo apt install --only-upgrade docker.io -y
                echo -e "${GREEN}Docker обновлен до версии $(docker --version | grep -oP '\d+\.\d+\.\d+')!${NC}"
            fi
        fi

        # Проверка наличия Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${YELLOW}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            echo -e "${GREEN}Docker Compose успешно установлен!${NC}"
        fi
