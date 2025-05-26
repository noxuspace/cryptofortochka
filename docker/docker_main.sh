#!/bin/bash
set -e

# --- Проверяем и устанавливаем Docker ---
if ! command -v docker &>/dev/null; then
  echo "Docker не найден — ставим…"
  sudo apt update
  sudo apt install -y \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    lsb-release

  # Добавляем официальный GPG-ключ Docker’а, если ещё не добавлен
  if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  fi

  # Добавляем репозиторий
  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
     https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Устанавливаем Docker Engine и containerd
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io

  echo "✔ Docker установлен"
else
  echo "✔ Docker уже есть ($(docker --version))"
fi


# --- Проверяем и устанавливаем Docker Compose (CLI-плагин v2 и бинарник) ---
if ! command -v docker-compose &>/dev/null; then
  echo "Docker Compose не найден — ставим…"
  sudo apt update
  sudo apt install -y wget jq

  # Берём последнюю версию из GitHub API
  COMPOSE_VER=$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest \
    | jq -r ".tag_name")

  # Устанавливаем старый бинарник для совместимости (если нужен)
  sudo wget -O /usr/local/bin/docker-compose \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)"
  sudo chmod +x /usr/local/bin/docker-compose

  # И устанавливаем современный плагин v2
  DOCKER_CLI_PLUGINS=${DOCKER_CLI_PLUGINS:-"$HOME/.docker/cli-plugins"}
  mkdir -p "$DOCKER_CLI_PLUGINS"
  curl -fsSL \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" \
    -o "${DOCKER_CLI_PLUGINS}/docker-compose"
  chmod +x "${DOCKER_CLI_PLUGINS}/docker-compose"

  echo "✔ Docker Compose ${COMPOSE_VER} установлен"
else
  echo "✔ Docker Compose уже есть ($(docker-compose --version))"
fi
