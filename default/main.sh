#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# ---------- Проверка окружения ----------
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "Не удалось определить дистрибутив (нет /etc/os-release)."
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Скрипт рассчитан на Ubuntu. Обнаружено: ${ID:-unknown}"
  exit 1
fi

# ---------- Базовые утилиты ----------
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  ca-certificates \
  apt-transport-https \
  gnupg \
  lsb-release \
  curl \
  wget \
  jq \
  git \
  unzip \
  tar \
  bc \
  lz4 \
  htop \
  net-tools \
  bash-completion

# ---------- Docker ----------
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker не найден — устанавливаем…"

  if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  fi

  ARCH="$(dpkg --print-architecture)"
  CODENAME="${VERSION_CODENAME}"

  echo \
"deb [arch=${ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/${ID} ${CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

  sudo systemctl enable docker
  sudo systemctl start docker

  echo "✔ Docker установлен: $(docker --version || true)"
else
  echo "✔ Docker уже установлен: $(docker --version)"
  # если не запущен — только запускаем (без рестарта)
  if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker
    echo "Docker был остановлен — запущен."
  fi
fi

# ---------- Docker Compose ----------
if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
  echo "Docker Compose не найден — устанавливаем…"

  COMPOSE_VER="$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')"
  if [[ -z "${COMPOSE_VER}" || "${COMPOSE_VER}" == "null" ]]; then
    COMPOSE_VER="v2.28.1"
  fi

  DOCKER_CLI_PLUGINS="${DOCKER_CLI_PLUGINS:-$HOME/.docker/cli-plugins}"
  mkdir -p "${DOCKER_CLI_PLUGINS}"

  PLUGIN_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)"
  curl -fsSL "${PLUGIN_URL}" -o "${DOCKER_CLI_PLUGINS}/docker-compose"
  chmod +x "${DOCKER_CLI_PLUGINS}/docker-compose"

  # «Шим» для совместимости со старой командой
  if ! command -v docker-compose >/dev/null 2>&1; then
    sudo tee /usr/local/bin/docker-compose >/dev/null <<'EOF'
#!/usr/bin/env bash
exec docker compose "$@"
EOF
    sudo chmod +x /usr/local/bin/docker-compose
  fi

  echo "✔ Docker Compose установлен: $(docker compose version 2>/dev/null || docker-compose --version)"
else
  if docker compose version >/dev/null 2>&1; then
    echo "✔ Docker Compose уже есть (плагин v2): $(docker compose version)"
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "✔ Совместимость: docker-compose → $(docker-compose --version)"
  fi
fi

# ---------- Чистка ----------
sudo apt-get autoremove -y
sudo apt-get clean

echo "-----------------------------------------------------------------------"
echo "Готово! Docker и Compose установлены."
