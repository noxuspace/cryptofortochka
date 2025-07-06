#!/bin/bash

# =============================================================================
# Boundless Prover Node Setup Script
# Description: Automated installation and configuration of Boundless prover node
# =============================================================================

set -euo pipefail

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Color variables
CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Constants
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/var/log/boundless_prover_setup.log"
ERROR_LOG="/var/log/boundless_prover_error.log"
INSTALL_DIR="$HOME/boundless"
COMPOSE_FILE="$INSTALL_DIR/compose.yml"
BROKER_CONFIG="$INSTALL_DIR/broker.toml"

# Exit codes
EXIT_SUCCESS=0
EXIT_OS_CHECK_FAILED=1
EXIT_DPKG_ERROR=2
EXIT_DEPENDENCY_FAILED=3
EXIT_GPU_ERROR=4
EXIT_NETWORK_ERROR=5
EXIT_USER_ABORT=6
EXIT_UNKNOWN=99

# Flags
ALLOW_ROOT=false
FORCE_RECLONE=false
START_IMMEDIATELY=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --allow-root)
            ALLOW_ROOT=true
            shift
            ;;
        --force-reclone)
            FORCE_RECLONE=true
            shift
            ;;
        --start-immediately)
            START_IMMEDIATELY=true
            shift
            ;;
        --help)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  --allow-root        Разрешить запуск от root без подтверждения"
            echo "  --force-reclone     Автоматически удалить и заново клонировать директорию, если она существует"
            echo "  --start-immediately Автоматически запустить управляющий скрипт"
            echo "  --help              Показать эту справку"
            exit 0
            ;;
        *)
            echo "Неизвестная опция: $1"
            exit 1
            ;;
    esac
done

# Trap function for exit logging
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Установка завершилась с кодом ошибки: $exit_code"
        echo "[EXIT] Script exited with code: $exit_code at $(date)" >> "$ERROR_LOG"
        echo "[EXIT] Last command: ${BASH_COMMAND}" >> "$ERROR_LOG"
        echo "[EXIT] Line number: ${BASH_LINENO[0]}" >> "$ERROR_LOG"
        echo "[EXIT] Function stack: ${FUNCNAME[@]}" >> "$ERROR_LOG"

        echo -e "\n${RED}${BOLD}Установка не удалась!${RESET}"
        echo -e "${YELLOW}Проверьте лог ошибок по пути: $ERROR_LOG${RESET}"
        echo -e "${YELLOW}Полный лог установки: $LOG_FILE${RESET}"

        case $exit_code in
            $EXIT_DPKG_ERROR)
                echo -e "\n${RED}Обнаружена ошибка конфигурации DPKG!${RESET}"
                echo -e "${YELLOW}Пожалуйста, выполните следующую команду вручную:${RESET}"
                echo -e "${BOLD}dpkg --configure -a${RESET}"
                echo -e "${YELLOW}Затем повторно запустите этот скрипт установки.${RESET}"
                ;;
            $EXIT_OS_CHECK_FAILED)
                echo -e "\n${RED}Ошибка проверки операционной системы!${RESET}"
                ;;
            $EXIT_DEPENDENCY_FAILED)
                echo -e "\n${RED}Не удалось установить зависимости!${RESET}"
                ;;
            $EXIT_GPU_ERROR)
                echo -e "\n${RED}Ошибка конфигурации GPU!${RESET}"
                ;;
            $EXIT_NETWORK_ERROR)
                echo -e "\n${RED}Ошибка сетевой конфигурации!${RESET}"
                ;;
            $EXIT_USER_ABORT)
                echo -e "\n${YELLOW}Установка прервана пользователем.${RESET}"
                ;;
            *)
                echo -e "\n${RED}Произошла неизвестная ошибка!${RESET}"
                ;;
        esac
    fi
}

# Set trap
trap cleanup_on_exit EXIT
trap 'echo "[SIGNAL] Caught signal ${?} at line ${LINENO}" >> "$ERROR_LOG"' ERR

# Network configurations
declare -A NETWORKS
NETWORKS["base"]="Base Mainnet|0x0b144e07a0826182b6b59788c34b32bfa86fb711|0x26759dbB201aFbA361Bec78E097Aa3942B0b4AB8|0x8C5a8b5cC272Fe2b74D18843CF9C3aCBc952a760|https://base-mainnet.beboundless.xyz"
NETWORKS["base-sepolia"]="Base Sepolia|0x0b144e07a0826182b6b59788c34b32bfa86fb711|0x6B7ABa661041164b8dB98E30AE1454d2e9D5f14b|0x8C5a8b5cC272Fe2b74D18843CF9C3aCBc952a760|https://base-sepolia.beboundless.xyz"
NETWORKS["eth-sepolia"]="Ethereum Sepolia|0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187|0x13337C76fE2d1750246B68781ecEe164643b98Ec|0x7aAB646f23D1392d4522CFaB0b7FB5eaf6821d64|https://eth-sepolia.beboundless.xyz/"

# Functions
info() {
    printf "${CYAN}[INFO]${RESET} %s\n" "$1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$1"
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$ERROR_LOG"
}

warning() {
    printf "${YELLOW}[WARNING]${RESET} %s\n" "$1"
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

prompt() {
    printf "${PURPLE}[INPUT]${RESET} %s" "$1"
}

# Check for dpkg errors
check_dpkg_status() {
    if dpkg --audit 2>&1 | grep -q "dpkg was interrupted"; then
        error "dpkg был прерван — требуется ручное вмешательство"
        return 1
    fi
    return 0
}

# Check OS compatibility
check_os() {
    info "Проверка совместимости операционной системы..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${ID,,}" != "ubuntu" ]]; then
            error "Неподдерживаемая ОС: $NAME. Этот скрипт предназначен для Ubuntu."
            exit $EXIT_OS_CHECK_FAILED
        elif [[ "${VERSION_ID,,}" != "22.04" && "${VERSION_ID,,}" != "20.04" ]]; then
            warning "Скрипт протестирован на Ubuntu 20.04/22.04. Ваша версия: $VERSION_ID"
            prompt "Продолжить в любом случае? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[yY]$ ]]; then
                exit $EXIT_USER_ABORT
            fi
        else
            info "Операционная система: $PRETTY_NAME"
        fi
    else
        error "/etc/os-release не найден. Не удалось определить ОС."
        exit $EXIT_OS_CHECK_FAILED
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed
is_package_installed() {
    dpkg -s "$1" &> /dev/null
}

# Update system
update_system() {
    info "Обновление системных пакетов..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        if ! apt update -y 2>&1; then
            error "Не удалось выполнить apt update"
            if apt update 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! apt upgrade -y 2>&1; then
            error "Не удалось выполнить apt upgrade"
            if apt upgrade 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
    } >> "$LOG_FILE" 2>&1
    success "Системные пакеты обновлены"
}

# Install basic dependencies
install_basic_deps() {
    local packages=(
        curl iptables build-essential git wget lz4 jq make gcc nano
        automake autoconf tmux htop nvme-cli libgbm1 pkg-config
        libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev
        libclang-dev ninja-build nvtop ubuntu-drivers-common
        gnupg ca-certificates lsb-release postgresql-client
    )
    info "Установка основных зависимостей..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        if ! apt install -y "${packages[@]}" 2>&1; then
            error "Не удалось установить основные зависимости"
            if apt install -y "${packages[@]}" 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
    } >> "$LOG_FILE" 2>&1
    success "Основные зависимости установлены"
}

# Install GPU drivers
install_gpu_drivers() {
    info "Установка драйверов GPU..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        if ! ubuntu-drivers install 2>&1; then
            error "Не удалось установить драйверы GPU"
            exit $EXIT_GPU_ERROR
        fi
    } >> "$LOG_FILE" 2>&1
    success "Драйверы GPU установлены"
}

# Install Docker
install_docker() {
    if command_exists docker; then
        info "Docker уже установлен"
        return
    fi
    info "Установка Docker..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        if ! apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common 2>&1; then
            error "Не удалось установить зависимости для Docker"
            if apt install -y apt-transport-https 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        if ! apt update -y 2>&1; then
            error "Не удалось обновить список пакетов для Docker"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>&1; then
            error "Не удалось установить Docker"
            if apt install -y docker-ce 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
        systemctl enable docker
        systemctl start docker
        usermod -aG docker $(logname 2>/dev/null || echo "$USER")
    } >> "$LOG_FILE" 2>&1
    success "Docker установлен"
}

# Install NVIDIA Container Toolkit
install_nvidia_toolkit() {
    if is_package_installed "nvidia-docker2"; then
        info "NVIDIA Container Toolkit уже установлен"
        return
    fi
    info "Установка NVIDIA Container Toolkit..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        distribution=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/"$distribution"/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
        if ! apt update -y 2>&1; then
            error "Не удалось обновить список пакетов для NVIDIA toolkit"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! apt install -y nvidia-docker2 2>&1; then
            error "Не удалось установить поддержку NVIDIA Docker"
            if apt install -y nvidia-docker2 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
        mkdir -p /etc/docker
        tee /etc/docker/daemon.json <<EOF
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
        systemctl restart docker
    } >> "$LOG_FILE" 2>&1
    success "NVIDIA Container Toolkit установлен"
}

# Install Rust
install_rust() {
    if command_exists rustc; then
        info "Rust уже установлен"
        return
    fi
    info "Установка Rust..."
    {
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        rustup update
    } >> "$LOG_FILE" 2>&1
    success "Rust установлен"
}

# Install Just
install_just() {
    if command_exists just; then
        info "Just уже установлен"
        return
    fi
    info "Установка Just command runner..."
    {
        curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
    } >> "$LOG_FILE" 2>&1
    success "Just установлен"
}

# Install CUDA Toolkit
install_cuda() {
    if is_package_installed "cuda-toolkit"; then
        info "CUDA Toolkit уже установлен"
        return
    fi
    info "Установка CUDA Toolkit..."
    if ! check_dpkg_status; then
        exit $EXIT_DPKG_ERROR
    fi
    {
        distribution=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"'| tr -d '\.')
        if ! wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/$(/usr/bin/uname -m)/cuda-keyring_1.1-1_all.deb 2>&1; then
            error "Не удалось скачать CUDA keyring"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! dpkg -i cuda-keyring_1.1-1_all.deb 2>&1; then
            error "Не удалось установить CUDA keyring"
            rm cuda-keyring_1.1-1_all.deb
            exit $EXIT_DEPENDENCY_FAILED
        fi
        rm cuda-keyring_1.1-1_all.deb
        if ! apt-get update 2>&1; then
            error "Не удалось обновить список пакетов для CUDA"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! apt-get install -y cuda-toolkit 2>&1; then
            error "Не удалось установить CUDA Toolkit"
            if apt-get install -y cuda-toolkit 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        fi
    } >> "$LOG_FILE" 2>&1
    success "CUDA Toolkit установлен"
}

# Install Rust dependencies
install_rust_deps() {
    info "Установка зависимостей Rust..."

    # Source the Rust environment
    source "$HOME/.cargo/env" || {
        error "Не удалось выполнить source $HOME/.cargo/env. Убедитесь, что Rust установлен."
        exit $EXIT_DEPENDENCY_FAILED
    }

    # Check and install cargo if not present
    if ! command_exists cargo; then
        if ! check_dpkg_status; then
            exit $EXIT_DPKG_ERROR
        fi
        info "Установка cargo..."
        apt update >> "$LOG_FILE" 2>&1 || {
            error "Не удалось обновить список пакетов для cargo"
            exit $EXIT_DEPENDENCY_FAILED
        }
        apt install -y cargo >> "$LOG_FILE" 2>&1 || {
            error "Не удалось установить cargo"
            if apt install -y cargo 2>&1 | grep -q "dpkg was interrupted"; then
                exit $EXIT_DPKG_ERROR
            fi
            exit $EXIT_DEPENDENCY_FAILED
        }
    fi

    # Always install rzup and the RISC Zero Rust toolchain
    info "Установка rzup..."
    curl -L https://risczero.com/install | bash >> "$LOG_FILE" 2>&1 || {
        error "Не удалось установить rzup"
        exit $EXIT_DEPENDENCY_FAILED
    }
    # Update PATH in the current shell
    export PATH="$PATH:/root/.risc0/bin"
    # Source bashrc to ensure environment is updated
    PS1='' source ~/.bashrc >> "$LOG_FILE" 2>&1 || {
        error "Не удалось выполнить source ~/.bashrc после установки rzup"
        exit $EXIT_DEPENDENCY_FAILED
    }
    # Install RISC Zero Rust toolchain
    rzup install rust >> "$LOG_FILE" 2>&1 || {
        error "Не удалось установить RISC Zero Rust toolchain"
        exit $EXIT_DEPENDENCY_FAILED
    }

    # Detect the RISC Zero toolchain
    TOOLCHAIN=$(rustup toolchain list | grep risc0 | head -1)
    if [ -z "$TOOLCHAIN" ]; then
        error "RISC Zero toolchain не найден после установки"
        exit $EXIT_DEPENDENCY_FAILED
    fi
    info "Используется RISC Zero toolchain: $TOOLCHAIN"

    # Install cargo-risczero
    if ! command_exists cargo-risczero; then
        info "Установка cargo-risczero..."
        cargo install cargo-risczero >> "$LOG_FILE" 2>&1 || {
            error "Не удалось установить cargo-risczero"
            exit $EXIT_DEPENDENCY_FAILED
        }
        rzup install cargo-risczero >> "$LOG_FILE" 2>&1 || {
            error "Не удалось установить cargo-risczero через rzup"
            exit $EXIT_DEPENDENCY_FAILED
        }
    fi

    # Install bento-client with the RISC Zero toolchain
    info "Установка bento-client..."
    RUSTUP_TOOLCHAIN=$TOOLCHAIN cargo install --git https://github.com/risc0/risc0 bento-client --bin bento_cli >> "$LOG_FILE" 2>&1 || {
        error "Не удалось установить bento-client"
        exit $EXIT_DEPENDENCY_FAILED
    }
    # Persist PATH for cargo binaries
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    PS1='' source ~/.bashrc >> "$LOG_FILE" 2>&1 || {
        error "Не удалось выполнить source ~/.bashrc после установки bento-client"
        exit $EXIT_DEPENDENCY_FAILED
    }

    # Install boundless-cli
    info "Установка boundless-cli..."
    cargo install --locked boundless-cli >> "$LOG_FILE" 2>&1 || {
        error "Не удалось установить boundless-cli"
        exit $EXIT_DEPENDENCY_FAILED
    }
    # Update PATH for boundless-cli
    export PATH="$PATH:/root/.cargo/bin"
    PS1='' source ~/.bashrc >> "$LOG_FILE" 2>&1 || {
        error "Не удалось выполнить source ~/.bashrc после установки boundless-cli"
        exit $EXIT_DEPENDENCY_FAILED
    }

    success "Зависимости Rust установлены"
}

# Clone Boundless repository
clone_repository() {
    info "Настройка репозитория Boundless..."
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ "$FORCE_RECLONE" == "true" ]]; then
            warning "Удаление существующей директории $INSTALL_DIR (принудительно через --force-reclone)"
            rm -rf "$INSTALL_DIR"
        else
            warning "Директория Boundless уже существует по пути $INSTALL_DIR"
            prompt "Удалить и клонировать заново? (y/N): "
            read -r response
            if [[ "$response" =~ ^[yY]$ ]]; then
                rm -rf "$INSTALL_DIR"
            else
                cd "$INSTALL_DIR"
                if ! git pull origin release-0.10 2>&1 >> "$LOG_FILE"; then
                    error "Не удалось обновить репозиторий"
                    exit $EXIT_DEPENDENCY_FAILED
                fi
                return
            fi
        fi
    fi
    {
        if ! git clone https://github.com/boundless-xyz/boundless "$INSTALL_DIR" 2>&1; then
            error "Не удалось клонировать репозиторий"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        cd "$INSTALL_DIR"
        if ! git checkout release-0.10 2>&1; then
            error "Не удалось переключиться на release-0.10"
            exit $EXIT_DEPENDENCY_FAILED
        fi
        if ! git submodule update --init --recursive 2>&1; then
            error "Не удалось инициализировать подмодули"
            exit $EXIT_DEPENDENCY_FAILED
        fi
    } >> "$LOG_FILE" 2>&1
    success "Репозиторий склонирован и инициализирован"
}

# Detect GPU configuration
detect_gpus() {
    info "Определение конфигурации GPU..."
    if ! command_exists nvidia-smi; then
        error "nvidia-smi не найден. Возможно, драйверы GPU установлены некорректно."
        exit $EXIT_GPU_ERROR
    fi
    GPU_COUNT=$(nvidia-smi -L 2>/dev/null | wc -l)
    if [[ $GPU_COUNT -eq 0 ]]; then
        error "GPU не обнаружены"
        exit $EXIT_GPU_ERROR
    fi
    info "Найдено $GPU_COUNT GPU"
    GPU_MEMORY=()
    for i in $(seq 0 $((GPU_COUNT - 1))); do
        MEM=$(nvidia-smi -i $i --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
        if [[ -z "$MEM" ]]; then
            error "Не удалось определить объём памяти для GPU $i"
            exit $EXIT_GPU_ERROR
        fi
        GPU_MEMORY+=($MEM)
        info "GPU $i: ${MEM}MB VRAM"
    done
    MIN_VRAM=$(printf '%s\n' "${GPU_MEMORY[@]}" | sort -n | head -1)
    if [[ $MIN_VRAM -ge 40000 ]]; then
        SEGMENT_SIZE=22
    elif [[ $MIN_VRAM -ge 20000 ]]; then
        SEGMENT_SIZE=21
    elif [[ $MIN_VRAM -ge 16000 ]]; then
        SEGMENT_SIZE=20
    elif [[ $MIN_VRAM -ge 12000 ]]; then
        SEGMENT_SIZE=19
    elif [[ $MIN_VRAM -ge 8000 ]]; then
        SEGMENT_SIZE=18
    else
        SEGMENT_SIZE=17
    fi
    info "Установлен SEGMENT_SIZE=$SEGMENT_SIZE, исходя из минимального VRAM ${MIN_VRAM}MB"
}

# Configure compose.yml for multiple GPUs
configure_compose() {
    info "Настройка compose.yml для $GPU_COUNT GPU..."
    if [[ $GPU_COUNT -eq 1 ]]; then
        info "Обнаружен один GPU, используется стандартный compose.yml"
        return
    fi
    cat > "$COMPOSE_FILE" << 'EOF'
name: bento
# Anchors:
x-base-environment: &base-environment
  DATABASE_URL: postgresql://${POSTGRES_USER:-worker}:${POSTGRES_PASSWORD:-password}@${POSTGRES_HOST:-postgres}:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-taskdb}
  REDIS_URL: redis://${REDIS_HOST:-redis}:6379
  S3_URL: http://${MINIO_HOST:-minio}:9000
  S3_BUCKET: ${MINIO_BUCKET:-workflow}
  S3_ACCESS_KEY: ${MINIO_ROOT_USER:-admin}
  S3_SECRET_KEY: ${MINIO_ROOT_PASS:-password}
  RUST_LOG: ${RUST_LOG:-info}
  RUST_BACKTRACE: 1

x-agent-common: &agent-common
  image: risczero/risc0-bento-agent:stable@sha256:c6fcc92686a5d4b20da963ebba3045f09a64695c9ba9a9aa984dd98b5ddbd6f9
  restart: always
  runtime: nvidia
  depends_on:
    - postgres
    - redis
    - minio
  environment:
    <<: *base-environment

x-exec-agent-common: &exec-agent-common
  <<: *agent-common
  mem_limit: 4G
  cpus: 3
  environment:
    <<: *base-environment
    RISC0_KECCAK_PO2: ${RISC0_KECCAK_PO2:-17}
  entrypoint: /app/agent -t exec --segment-po2 ${SEGMENT_SIZE:-21}

services:
  redis:
    hostname: ${REDIS_HOST:-redis}
    image: ${REDIS_IMG:-redis:7.2.5-alpine3.19}
    restart: always
    ports:
      - 6379:6379
    volumes:
      - redis-data:/data

  postgres:
    hostname: ${POSTGRES_HOST:-postgres}
    image: ${POSTGRES_IMG:-postgres:16.3-bullseye}
    restart: always
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-taskdb}
      POSTGRES_USER: ${POSTGRES_USER:-worker}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-password}
    expose:
      - '${POSTGRES_PORT:-5432}'
    ports:
      - '${POSTGRES_PORT:-5432}:${POSTGRES_PORT:-5432}'
    volumes:
      - postgres-data:/var/lib/postgresql/data
    command: -p ${POSTGRES_PORT:-5432}

  minio:
    hostname: ${MINIO_HOST:-minio}
    image: ${MINIO_IMG:-minio/minio:RELEASE.2024-05-28T17-19-04Z}
    ports:
      - '9000:9000'
      - '9001:9001'
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=${MINIO_ROOT_USER:-admin}
      - MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASS:-password}
      - MINIO_DEFAULT_BUCKETS=${MINIO_BUCKET:-workflow}
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 5s
      timeout: 5s
      retries: 5

  grafana:
    image: ${GRAFANA_IMG:-grafana/grafana:11.0.0}
    restart: unless-stopped
    ports:
     - '3000:3000'
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_LOG_LEVEL=WARN
      - POSTGRES_HOST=${POSTGRES_HOST:-postgres}
      - POSTGRES_DB=${POSTGRES_DB:-taskdb}
      - POSTGRES_PORT=${POSTGRES_PORT:-5432}
      - POSTGRES_USER=${POSTGRES_USER:-worker}
      - POSTGRES_PASS=${POSTGRES_PASSWORD:-password}
      - GF_INSTALL_PLUGINS=frser-sqlite-datasource
    volumes:
      - ./dockerfiles/grafana:/etc/grafana/provisioning/
      - grafana-data:/var/lib/grafana
      - broker-data:/db
    depends_on:
      - postgres
      - redis
      - minio

  exec_agent0:
    <<: *exec-agent-common

  exec_agent1:
    <<: *exec-agent-common

  aux_agent:
    <<: *agent-common
    mem_limit: 256M
    cpus: 1
    entrypoint: /app/agent -t aux --monitor-requeue

EOF
    for i in $(seq 0 $((GPU_COUNT - 1))); do
        cat >> "$COMPOSE_FILE" << EOF
  gpu_prove_agent$i:
    <<: *agent-common
    mem_limit: 4G
    cpus: 4
    entrypoint: /app/agent -t prove
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['$i']
              capabilities: [gpu]

EOF
    done
    cat >> "$COMPOSE_FILE" << 'EOF'
  snark_agent:
    <<: *agent-common
    entrypoint: /app/agent -t snark
    ulimits:
      stack: 90000000

  rest_api:
    image: risczero/risc0-bento-rest-api:stable@sha256:7b5183811675d0aa3646d079dec4a7a6d47c84fab4fa33d3eb279135f2e59207
    restart: always
    depends_on:
      - postgres
      - minio
    mem_limit: 1G
    cpus: 1
    environment:
      <<: *base-environment
    ports:
      - '8081:8081'
    entrypoint: /app/rest_api --bind-addr 0.0.0.0:8081 --snark-timeout ${SNARK_TIMEOUT:-180}

  broker:
    restart: always
    depends_on:
      - rest_api
EOF
    for i in $(seq 0 $((GPU_COUNT - 1))); do
        echo "      - gpu_prove_agent$i" >> "$COMPOSE_FILE"
    done
    cat >> "$COMPOSE_FILE" << 'EOF'
      - exec_agent0
      - exec_agent1
      - aux_agent
      - snark_agent
      - redis
      - postgres
    profiles: [broker]
    build:
      context: .
      dockerfile: dockerfiles/broker.dockerfile
    mem_limit: 2G
    cpus: 2
    stop_grace_period: 3h
    volumes:
      - type: bind
        source: ./broker.toml
        target: /app/broker.toml
      - broker-data:/db/
    network_mode: host
    environment:
      RUST_LOG: ${RUST_LOG:-info,broker=debug,boundless_market=debug}
      PRIVATE_KEY: ${PRIVATE_KEY}
      RPC_URL: ${RPC_URL}
      ORDER_STREAM_URL:
      POSTGRES_HOST:
      POSTGRES_DB:
      POSTGRES_PORT:
      POSTGRES_USER:
      POSTGRES_PASS:
    entrypoint: /app/broker --db-url 'sqlite:///db/broker.db' --set-verifier-address ${SET_VERIFIER_ADDRESS} --boundless-market-address ${BOUNDLESS_MARKET_ADDRESS} --config-file /app/broker.toml --bento-api-url http://localhost:8081

volumes:
  redis-data:
  postgres-data:
  minio-data:
  grafana-data:
  broker-data:
EOF
    success "compose.yml сконфигурирован для $GPU_COUNT GPU"
}

# Configure network
configure_network() {
    info "Настройка сетевых параметров..."
    echo -e "\n${BOLD}Доступные сети:${RESET}"
    echo "1) Base Mainnet"
    echo "2) Base Sepolia (Тестнет)"
    echo "3) Ethereum Sepolia (Тестнет)"
    prompt "Выберите сеть (1-3): "
    read -r network_choice
    case $network_choice in
        1) NETWORK="base" ;;
        2) NETWORK="base-sepolia" ;;
        3) NETWORK="eth-sepolia" ;;
        *)
            error "Неверный выбор сети"
            exit $EXIT_NETWORK_ERROR
            ;;
    esac
    IFS='|' read -r NETWORK_NAME VERIFIER_ADDRESS BOUNDLESS_MARKET_ADDRESS SET_VERIFIER_ADDRESS ORDER_STREAM_URL <<< "${NETWORKS[$NETWORK]}"
    info "Выбрано: $NETWORK_NAME"
    echo -e "\n${BOLD}Настройка RPC:${RESET}"
    echo "RPC должен поддерживать eth_newBlockFilter. Рекомендуемые провайдеры:"
    echo "- Alchemy (установите lookback_block=<120>)"
    echo "- BlockPi (бесплатно для сетей Base)"
    echo "- Chainstack (установите lookback_blocks=0)"
    echo "- Ваш собственный RPC узел"
    prompt "Введите RPC URL: "
    read -r RPC_URL
    if [[ -z "$RPC_URL" ]]; then
        error "RPC URL не может быть пустым"
        exit $EXIT_NETWORK_ERROR
    fi
    prompt "Введите приватный ключ кошелька (без префикса 0x): "
    read -rs PRIVATE_KEY
    echo
    if [[ -z "$PRIVATE_KEY" ]]; then
        error "Приватный ключ не может быть пустым"
        exit $EXIT_NETWORK_ERROR
    fi
    cat > "$INSTALL_DIR/.env.broker" << EOF
# Network: $NETWORK_NAME
export VERIFIER_ADDRESS=$VERIFIER_ADDRESS
export BOUNDLESS_MARKET_ADDRESS=$BOUNDLESS_MARKET_ADDRESS
export SET_VERIFIER_ADDRESS=$SET_VERIFIER_ADDRESS
export ORDER_STREAM_URL="$ORDER_STREAM_URL"
export RPC_URL="$RPC_URL"
export PRIVATE_KEY=$PRIVATE_KEY
export SEGMENT_SIZE=$SEGMENT_SIZE

# Prover node configs
RUST_LOG=info
REDIS_HOST=redis
REDIS_IMG=redis:7.2.5-alpine3.19
POSTGRES_HOST=postgres
POSTGRES_IMG=postgres:16.3-bullseye
POSTGRES_DB=taskdb
POSTGRES_PORT=5432
POSTGRES_USER=worker
POSTGRES_PASSWORD=password
MINIO_HOST=minio
MINIO_IMG=minio/minio:RELEASE.2024-05-28T17-19-04Z
MINIO_ROOT_USER=admin
MINIO_ROOT_PASS=password
MINIO_BUCKET=workflow
GRAFANA_IMG=grafana/grafana:11.0.0
RISC0_KECCAK_PO2=17
EOF
    cat > "$INSTALL_DIR/.env.base" << EOF
export VERIFIER_ADDRESS=0x0b144e07a0826182b6b59788c34b32bfa86fb711
export BOUNDLESS_MARKET_ADDRESS=0x26759dbB201aFbA361Bec78E097Aa3942B0b4AB8
export SET_VERIFIER_ADDRESS=0x8C5a8b5cC272Fe2b74D18843CF9C3aCBc952a760
export ORDER_STREAM_URL="https://base-mainnet.beboundless.xyz"
export RPC_URL="$RPC_URL"
export PRIVATE_KEY=$PRIVATE_KEY
export SEGMENT_SIZE=$SEGMENT_SIZE
EOF
    cat > "$INSTALL_DIR/.env.base-sepolia" << EOF
export VERIFIER_ADDRESS=0x0b144e07a0826182b6b59788c34b32bfa86fb711
export BOUNDLESS_MARKET_ADDRESS=0x6B7ABa661041164b8dB98E30AE1454d2e9D5f14b
export SET_VERIFIER_ADDRESS=0x8C5a8b5cC272Fe2b74D18843CF9C3aCBc952a760
export ORDER_STREAM_URL="https://base-sepolia.beboundless.xyz"
export RPC_URL="$RPC_URL"
export PRIVATE_KEY=$PRIVATE_KEY
export SEGMENT_SIZE=$SEGMENT_SIZE
EOF
    cat > "$INSTALL_DIR/.env.eth-sepolia" << EOF
export VERIFIER_ADDRESS=0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187
export BOUNDLESS_MARKET_ADDRESS=0x13337C76fE2d1750246B68781ecEe164643b98Ec
export SET_VERIFIER_ADDRESS=0x7aAB646f23D1392d4522CFaB0b7FB5eaf6821d64
export ORDER_STREAM_URL="https://eth-sepolia.beboundless.xyz/"
export RPC_URL="$RPC_URL"
export PRIVATE_KEY=$PRIVATE_KEY
export SEGMENT_SIZE=$SEGMENT_SIZE
EOF
    chmod 600 "$INSTALL_DIR/.env.broker"
    chmod 600 "$INSTALL_DIR/.env.base"
    chmod 600 "$INSTALL_DIR/.env.base-sepolia"
    chmod 600 "$INSTALL_DIR/.env.eth-sepolia"
    success "Сетевая конфигурация сохранена"
}

# Configure broker.toml
configure_broker() {
    info "Настройка параметров брокера..."
    cp "$INSTALL_DIR/broker-template.toml" "$BROKER_CONFIG"
    echo -e "\n${BOLD}Конфигурация брокера:${RESET}"
    echo "Настройте ключевые параметры (нажмите Enter, чтобы оставить значение по умолчанию):"
    echo -e "\n${CYAN}mcycle_price${RESET}: Цена за миллион циклов в нативном токене"
    echo "Меньше = выше конкурентность, но меньше прибыль"
    prompt "mcycle_price [по умолчанию: 0.0000005]: "
    read -r mcycle_price
    mcycle_price=${mcycle_price:-0.0000005}
    echo -e "\n${CYAN}peak_prove_khz${RESET}: Максимальная скорость proving в kHz"
    echo "Позже проведите бенчмарк GPU через управляющий скрипт и установите это значение по результату"
    prompt "peak_prove_khz [по умолчанию: 100]: "
    read -r peak_prove_khz
    peak_prove_khz=${peak_prove_khz:-100}
    echo -e "\n${CYAN}max_mcycle_limit${RESET}: Максимальное количество циклов (в миллионах)"
    echo "Больше = принимаются более крупные proofs"
    prompt "max_mcycle_limit [по умолчанию: 8000]: "
    read -r max_mcycle_limit
    max_mcycle_limit=${max_mcycle_limit:-8000}
    echo -e "\n${CYAN}min_deadline${RESET}: Минимальное количество секунд до дедлайна"
    echo "Больше = безопаснее, но могут быть пропущены заявки с меньшим дедлайном"
    prompt "min_deadline [по умолчанию: 300]: "
    read -r min_deadline
    min_deadline=${min_deadline:-300}
    echo -e "\n${CYAN}max_concurrent_proofs${RESET}: Максимальное количество параллельных proofs"
    echo "Больше = выше пропускная способность, но есть риск не уложиться в дедлайн"
    prompt "max_concurrent_proofs [по умолчанию: 2]: "
    read -r max_concurrent_proofs
    max_concurrent_proofs=${max_concurrent_proofs:-2}
    echo -e "\n${CYAN}lockin_priority_gas${RESET}: Дополнительный gas для lock-транзакций (Gwei)"
    echo "Важный параметр для победы в заявках на выполнение proofs"
    echo "Больше = выше шанс выиграть заявку"
    prompt "lockin_priority_gas [по умолчанию: 0]: "
    read -r lockin_priority_gas
    sed -i "s/mcycle_price = \"[^\"]*\"/mcycle_price = \"$mcycle_price\"/" "$BROKER_CONFIG"
    sed -i "s/peak_prove_khz = [0-9]*/peak_prove_khz = $peak_prove_khz/" "$BROKER_CONFIG"
    sed -i "s/max_mcycle_limit = [0-9]*/max_mcycle_limit = $max_mcycle_limit/" "$BROKER_CONFIG"
    sed -i "s/min_deadline = [0-9]*/min_deadline = $min_deadline/" "$BROKER_CONFIG"
    sed -i "s/max_concurrent_proofs = [0-9]*/max_concurrent_proofs = $max_concurrent_proofs/" "$BROKER_CONFIG"
    if [[ -n "$lockin_priority_gas" ]]; then
        sed -i "s/#lockin_priority_gas = [0-9]*/lockin_priority_gas = $lockin_priority_gas/" "$BROKER_CONFIG"
    fi
    success "Конфигурация брокера сохранена"
}

# Create management script
create_management_script() {
    info "Создание управляющего скрипта..."
    cat > "$INSTALL_DIR/prover.sh" << 'EOF'
#!/bin/bash

export PATH="$HOME/.cargo/bin:$PATH"

INSTALL_DIR="$(dirname "$0")"
cd "$INSTALL_DIR"

# Color variables
CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'
GRAY='\033[0;90m'

# Menu options with categories
declare -a menu_items=(
    "SERVICE:Управление сервисами"
    "Запустить брокер"
    "Запустить Bento (только для тестирования)"
    "Остановить сервисы"
    "Просмотреть логи"
    "Проверка состояния"
    "SEPARATOR:"
    "CONFIG:Конфигурация"
    "Сменить сеть"
    "Сменить приватный ключ"
    "Редактировать конфиг брокера"
    "SEPARATOR:"
    "STAKE:Управление стейком"
    "Внести стейк"
    "Проверить баланс стейка"
    "SEPARATOR:"
    "BENCH:Тест производительности"
    "Запустить бенчмарк (Order IDs)"
    "SEPARATOR:"
    "MONITOR:Мониторинг"
    "Мониторинг GPU"
    "SEPARATOR:"
    "Выход"
)

# Function to draw menu
draw_menu() {
    local current=$1
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║      Boundless Prover Management         ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
    echo

    local index=0
    for item in "${menu_items[@]}"; do
        if [[ $item == *":"* ]]; then
            if [[ $item == "SEPARATOR:" ]]; then
                echo -e "${GRAY}──────────────────────────────────────────${RESET}"
            else
                local category=$(echo $item | cut -d: -f1)
                local desc=$(echo $item | cut -d: -f2)
                case $category in
                    "SERVICE")
                        echo -e "\n${BOLD}${GREEN}▶ $desc${RESET}"
                        ;;
                    "CONFIG")
                        echo -e "\n${BOLD}${YELLOW}▶ $desc${RESET}"
                        ;;
                    "STAKE")
                        echo -e "\n${BOLD}${PURPLE}▶ $desc${RESET}"
                        ;;
                    "BENCH")
                        echo -e "\n${BOLD}${ORANGE}▶ $desc${RESET}"
                        ;;
                    "MONITOR")
                        echo -e "\n${BOLD}${LIGHTBLUE}▶ $desc${RESET}"
                        ;;
                esac
            fi
        else
            if [ $index -eq $current ]; then
                echo -e "  ${BOLD}${CYAN}→ $item${RESET}"
            else
                echo -e "    $item"
            fi
            ((index++))
        fi
    done
    echo
    echo -e "${GRAY}Используйте стрелки ↑/↓ для навигации, Enter для выбора, q — выход${RESET}"
}

# Function to get actual menu items (excluding categories and separators)
get_menu_item() {
    local current=$1
    local index=0
    for item in "${menu_items[@]}"; do
        if [[ ! $item == *":"* ]]; then
            if [ $index -eq $current ]; then
                echo "$item"
                return
            fi
            ((index++))
        fi
    done
}

# Get key press
get_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null >&2
    if [[ $key = "" ]]; then echo enter; fi
    if [[ $key = $'\x1b' ]]; then
        read -rsn2 key
        if [[ $key = [A ]]; then echo up; fi
        if [[ $key = [B ]]; then echo down; fi
    fi
    if [[ $key = "q" ]] || [[ $key = "Q" ]]; then echo quit; fi
}

# Validate configuration
validate_config() {
    local errors=0
    
    if [[ ! -f .env.broker ]]; then
        echo -e "${RED}✗ Файл конфигурации .env.broker не найден${RESET}"
        ((errors++))
    else
        source .env.broker
        
        # Check private key
        if [[ ! "$PRIVATE_KEY" =~ ^[0-9a-fA-F]{64}$ ]]; then
            echo -e "${RED}✗ Неверный формат приватного ключа${RESET}"
            ((errors++))
        fi
        
        # Check RPC URL
        if [[ -z "$RPC_URL" ]]; then
            echo -e "${RED}✗ RPC URL не настроен${RESET}"
            ((errors++))
        fi
        
        # Check required addresses
        if [[ -z "$BOUNDLESS_MARKET_ADDRESS" ]] || [[ -z "$SET_VERIFIER_ADDRESS" ]]; then
            echo -e "${RED}✗ Не заданы необходимые адреса контрактов${RESET}"
            ((errors++))
        fi
    fi
    
    return $errors
}

# Arrow navigation for sub-menus
arrow_menu() {
    local -a options=("$@")
    local current=0
    local key

    while true; do
        clear
        for i in "${!options[@]}"; do
            if [ $i -eq $current ]; then
                echo -e "${BOLD}${CYAN}→ ${options[$i]}${RESET}"
            else
                echo -e "  ${options[$i]}"
            fi
        done
        echo
        echo -e "${GRAY}Используйте стрелки ↑/↓ для навигации, Enter для выбора, q — назад${RESET}"

        key=$(get_key)
        case $key in
            up)
                ((current--))
                if [ $current -lt 0 ]; then current=$((${#options[@]}-1)); fi
                ;;
            down)
                ((current++))
                if [ $current -ge ${#options[@]} ]; then current=0; fi
                ;;
            enter)
                return $current
                ;;
            quit)
                return 255
                ;;
        esac
    done
}

# Check if specific container is running
is_container_running() {
    local container=$1
    local status=$(docker compose ps -q $container 2>/dev/null)
    if [[ -n "$status" ]]; then
        # Check if container is actually running (not exiting/restarting)
        docker compose ps $container 2>/dev/null | grep -q "Up" && return 0
    fi
    return 1
}

# Get container exit status
get_container_exit_code() {
    local container=$1
    docker compose ps $container 2>/dev/null | grep -oP 'Exit \K\d+' || echo "N/A"
}

# Check all container statuses
check_container_status() {
    local containers=("broker" "rest_api" "postgres" "redis" "minio" "gpu_prove_agent0" "exec_agent0" "exec_agent1" "aux_agent" "snark_agent")
    local statuses=$(docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null)
    local has_issues=false

    for container in "${containers[@]}"; do
        if ! echo "$statuses" | grep -q "^$container.*Up"; then
            has_issues=true
            break
        fi
    done

    if [[ "$has_issues" == true ]]; then
        echo -e "${RED}${BOLD}⚠ Внимание: Некоторые контейнеры работают некорректно${RESET}"
        echo -e "${YELLOW}Выберите 'Статус контейнеров' для подробностей${RESET}\n"
    fi
}

# Show detailed container status
show_container_status() {
    clear
    echo -e "${BOLD}${CYAN}Обзор статусов контейнеров${RESET}"
    echo -e "${GRAY}════════════════════════════════════════${RESET}\n"

    # Get all containers from compose
    local containers=$(docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}" 2>/dev/null | tail -n +2)

    if [[ -z "$containers" ]]; then
        echo -e "${RED}Контейнеры не найдены. Сервисы, возможно, не запущены.${RESET}"
    else
        # Header
        printf "%-30s %-20s %s\n" "КОНТЕЙНЕР" "СТАТУС" "СЕРВИС"
        echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"

        # Process each container
        while IFS= read -r line; do
            local name=$(echo "$line" | awk '{print $1}')
            local status=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
            local service=$(echo "$line" | awk '{print $NF}')

            # Color based on status
            if echo "$status" | grep -q "Up"; then
                printf "${GREEN}%-30s${RESET} %-20s %s\n" "$name" "✓ Запущен" "$service"
            elif echo "$status" | grep -q "Exit"; then
                printf "${RED}%-30s${RESET} ${RED}%-20s${RESET} %s\n" "$name" "✗ Остановлен" "$service"
                # Show last error for exited containers
                if [[ "$service" == "broker" ]]; then
                    echo -e "${YELLOW}  └─ Последняя ошибка: $(docker compose logs --tail=1 broker 2>&1 | grep -oE 'error:.*' | head -1)${RESET}"
                fi
            elif echo "$status" | grep -q "Restarting"; then
                printf "${YELLOW}%-30s${RESET} ${YELLOW}%-20s${RESET} %s\n" "$name" "↻ Перезапуск" "$service"
            else
                printf "%-30s %-20s %s\n" "$name" "$status" "$service"
            fi
        done <<< "$containers"
    fi

    echo -e "\n${GRAY}Нажмите любую клавишу для продолжения...${RESET}"
    read -n 1
}

# Analyze common broker errors
analyze_broker_errors() {
    local last_errors=$(docker compose logs --tail=100 broker 2>&1 | grep -i "error" | tail -5)

    if [[ -z "$last_errors" ]]; then
        return
    fi

    echo -e "\n${BOLD}${YELLOW}Обнаружены проблемы:${RESET}"

    # Check each error pattern
    if echo "$last_errors" | grep -q "odd number of digits"; then
        echo -e "${RED}✗ Неверный формат приватного ключа${RESET}"
        echo -e "  ${YELLOW}→ Приватный ключ должен содержать 64 шестнадцатеричных символа (без префикса 0x)${RESET}"
        echo -e "  ${YELLOW}→ Используйте опцию 'Сменить приватный ключ' для исправления${RESET}"
    fi

    if echo "$last_errors" | grep -q "connection refused"; then
        echo -e "${RED}✗ Отказано в соединении${RESET}"
        echo -е "  ${YELLOW}→ Проверьте, что все необходимые сервисы запущены${RESET}"
        echo -е "  ${YELLOW}→ Убедитесь, что RPC URL доступен${RESET}"
    fi

    if echo "$last_errors" | grep -q "insufficient funds"; then
        echo -e "${RED}✗ Недостаточно средств${RESET}"
        echo -e "  ${YELLOW}→ Проверьте баланс кошелька для газа${RESET}"
        echo -e "  ${YELLOW}→ Убедитесь, что внесён стейк USDC${RESET}"
    fi

    if echo "$last_errors" | grep -q "RPC.*error\|eth_.*not supported"; then
        echo -e "${RED}✗ Проблема с соединением RPC${RESET}"
        echo -e "  ${YELLOW}→ Убедитесь, что RPC URL указан верно и доступен${RESET}"
        echo -e "  ${YELLOW}→ Проверьте, поддерживает ли RPC eth_newBlockFilter${RESET}"
        echo -e "  ${YELLOW}→ Рекомендуется использовать BlockPi, Alchemy или свой нод${RESET}"
    fi

    if echo "$last_errors" | grep -q "database.*connection\|postgres"; then
        echo -e "${RED}✗ Проблема с подключением к базе данных${RESET}"
        echo -e "  ${YELLOW}→ Проверьте, что контейнер postgres запущен${RESET}"
        echo -e "  ${YELLOW}→ Попробуйте перезапустить все сервисы${RESET}"
    fi

    if echo "$last_errors" | grep -q "stake.*required\|minimum.*stake"; then
        echo -e "${RED}✗ Недостаточный стейк${RESET}"
        echo -e "  ${YELLOW}→ Используйте опцию 'Внести стейк' для пополнения USDC стейка${RESET}"
        echo -e "  ${YELLOW}→ Проверьте минимальные требования к стейку${RESET}"
    fi

    if echo "$last_errors" | grep -q "invalid.*address\|checksum"; then
        echo -e "${RED}✗ Неверный адрес контракта${RESET}"
        echo -e "  ${YELLOW}→ Конфигурация сети может быть повреждена${RESET}"
        echo -e "  ${YELLOW}→ Попробуйте переключиться на другую сеть и обратно${RESET}"
    fi

    # Show the actual error lines for debugging
    echo -e "\n${GRAY}Последние сообщения об ошибках:${RESET}"
    echo "$last_errors" | while IFS= read -r line; do
        echo -e "${GRAY}  $line${RESET}"
    done
}

# View broker logs with proper handling
view_broker_logs() {
    clear
    echo -e "${CYAN}${BOLD}Логи брокера${RESET}"
    echo -e "${GRAY}════════════════════════════════════════${RESET}\n"

    if is_container_running "broker"; then
        echo -e "${GREEN}Брокер запущен. Показ live-логов (нажмите Ctrl+C для выхода)...${RESET}\n"
        docker compose logs -f broker
    else
        echo -e "${RED}${BOLD}⚠ Контейнер брокера не запущен!${RESET}"
        echo -e "${YELLOW}Показ доступных логов...${RESET}\n"

        # Show historical logs
        docker compose logs broker 2>&1 || echo -e "${RED}Логи брокера недоступны${RESET}"

        # Analyze errors
        echo -e "\n${GRAY}────────────────────────────────────────${RESET}"
        analyze_broker_errors
    fi
}

# View last 100 broker logs with proper handling
view_broker_logs_tail() {
    clear
    echo -e "${CYAN}${BOLD}Последние 100 логов брокера${RESET}"
    echo -e "${GRAY}════════════════════════════════════════${RESET}\n"

    if is_container_running "broker"; then
        echo -e "${GREEN}Брокер запущен. Показ последних 100 строк и live-логов (нажмите Ctrl+C для выхода)...${RESET}\n"
        docker compose logs --tail=100 -f broker
    else
        echo -e "${RED}${BOLD}⚠ Контейнер брокера не запущен!${RESET}"
        echo -e "${YELLOW}Показ последних 100 строк логов...${RESET}\n"

        # Show last 100 lines of historical logs
        docker compose logs --tail=100 broker 2>&1 || echo -e "${RED}Логи брокера недоступны${RESET}"

        # Analyze errors
        echo -e "\n${GRAY}────────────────────────────────────────${RESET}"
        analyze_broker_errors
    fi
}

# Enhanced view_logs function with better container status handling
view_logs() {
    echo -e "${BOLD}${CYAN}Просмотр логов${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"

    # Check container statuses first
    check_container_status

    local options=("Все логи" "Только логи брокера" "Последние 100 логов брокера" "Статус контейнеров" "Назад в меню")
    arrow_menu "${options[@]}"
    local choice=$?

    case $choice in
        0) # All logs
            clear
            echo -e "${CYAN}${BOLD}Показ всех логов (нажмите Ctrl+C для выхода)...${RESET}\n"
            just broker logs
            ;;
        1) # Broker logs only
            view_broker_logs
            ;;
        2) # Last 100 broker logs
            view_broker_logs_tail
            ;;
        3) # Container status
            show_container_status
            ;;
        4|255) return ;;
    esac
}

# Updated start_broker with better error handling
start_broker() {
    clear

    # Validate configuration first
    echo -e "${CYAN}${BOLD}Проверка конфигурации...${RESET}"
    if ! validate_config; then
        echo -e "\n${RED}Проверка конфигурации не пройдена!${RESET}"
        echo -e "${YELLOW}Пожалуйста, исправьте ошибки выше перед запуском брокера.${RESET}"
        echo -e "\nНажмите любую клавишу для возврата в меню..."
        read -n 1
        return
    fi

    source .env.broker

    echo -e "${GREEN}✓ Конфигурация проверена${RESET}"
    echo -e "\n${GREEN}${BOLD}Запуск брокера...${RESET}"

    # Start services
    just broker

    # Give containers time to start
    sleep 3

    # Check if broker started successfully
    if ! is_container_running "broker"; then
        echo -e "\n${RED}${BOLD}⚠ Брокер не удалось запустить!${RESET}"
        echo -e "${YELLOW}Проверяем логи на наличие ошибок...${RESET}\n"
        docker compose logs --tail=20 broker
        analyze_broker_errors
        echo -e "\nНажмите любую клавишу для возврата в меню..."
        read -n 1
    fi
}

start_bento() {
    clear
    echo -e "${GREEN}${BOLD}Запуск bento для тестирования...${RESET}"
    just bento
}

stop_services() {
    clear
    echo -е "${YELLOW}${BOLD}Остановка сервисов...${RESET}"
    just broker down
    echo -e "\n${GREEN}Сервисы остановлены. Нажмите любую клавишу для продолжения...${RESET}"
    read -n 1
}

change_network() {
    echo -e "${BOLD}${YELLOW}Выбор сети${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"

    local options=("Base Mainnet" "Base Sepolia" "Ethereum Sepolia" "Назад в меню")
    arrow_menu "${options[@]}"
    local choice=$?

    # Get current SEGMENT_SIZE before changing network
    if [[ -f .env.broker ]]; then
        source .env.broker
        CURRENT_SEGMENT_SIZE=$SEGMENT_SIZE
    fi

    case $choice in
        0)
            cp .env.base .env.broker
            echo -e "${GREEN}Сеть изменена на Base Mainnet.${RESET}"
            local selected_network="base"
            ;;
        1)
            cp .env.base-sepolia .env.broker
            echo -e "${GREEN}Сеть изменена на Base Sepolia.${RESET}"
            local selected_network="base-sepolia"
            ;;
        2)
            cp .env.eth-sepolia .env.broker
            echo -e "${GREEN}Сеть изменена на Ethereum Sepolia.${RESET}"
            local selected_network="eth-sepolia"
            ;;
        3|255) return ;;
    esac

    if [[ $choice -le 2 ]]; then
        # Preserve SEGMENT_SIZE in the new configuration
        if [[ -n "$CURRENT_SEGMENT_SIZE" ]]; then
            sed -i "s/export SEGMENT_SIZE=.*/export SEGMENT_SIZE=$CURRENT_SEGMENT_SIZE/" .env.broker
            sed -i "s/export SEGMENT_SIZE=.*/export SEGMENT_SIZE=$CURRENT_SEGMENT_SIZE/" .env.$selected_network
        fi

        # Ask for new RPC URL
        echo -e "\n${BOLD}Настройка RPC для новой сети:${RESET}"
        echo "RPC должен поддерживать eth_newBlockFilter. Рекомендуемые провайдеры:"
        echo "- BlockPi (бесплатно для Base)"
        echo "- Alchemy"
        echo "- Chainstack (установите lookback_blocks=0)"
        echo "- Ваш собственный RPC"
        read -p "Введите RPC URL: " new_rpc

        if [[ -n "$new_rpc" ]]; then
            # Update RPC URL in both files
            sed -i "s|export RPC_URL=.*|export RPC_URL=\"$new_rpc\"|" .env.broker
            sed -i "s|export RPC_URL=.*|export RPC_URL=\"$new_rpc\"|" .env.$selected_network
            echo -e "${GREEN}RPC URL обновлен.${RESET}"
        fi

        echo -e "${YELLOW}Не забудьте перезапустить брокер для применения изменений.${RESET}"
        echo -e "\nНажмите любую клавишу для продолжения..."
        read -n 1
    fi
}

change_private_key() {
    clear
    echo -e "${BOLD}${YELLOW}Смена приватного ключа${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"
    echo -e "${RED}ВНИМАНИЕ: Это действие обновит приватный ключ во всех сетевых файлах.${RESET}"
    echo
    read -sp "Введите новый приватный ключ (без префикса 0x): " new_key
    echo

    if [[ -z "$new_key" ]]; then
        echo -e "${RED}Приватный ключ не может быть пустым. Операция отменена.${RESET}"
        echo -e "\nНажмите любую клавишу для продолжения..."
        read -n 1
        return
    fi

    # Validate private key format
    if [[ ! "$new_key" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo -e "${RED}Неверный формат приватного ключа!${RESET}"
        echo -e "${YELLOW}Приватный ключ должен состоять ровно из 64 шестнадцатеричных символов (без префикса 0x)${RESET}"
        echo -e "${YELLOW}Вы ввели: ${#new_key} символов${RESET}"
        echo -e "\nНажмите любую клавишу для продолжения..."
        read -n 1
        return
    fi

    # Update all env files
    for env_file in .env.broker .env.base .env.base-sepolia .env.eth-sepolia; do
        if [[ -f "$env_file" ]]; then
            sed -i "s/export PRIVATE_KEY=.*/export PRIVATE_KEY=$new_key/" "$env_file"
        fi
    done

    echo -e "\n${GREEN}Приватный ключ успешно обновлен во всех сетевых файлах.${RESET}"
    echo -e "${YELLOW}Не забудьте перезапустить сервисы, чтобы изменения вступили в силу.${RESET}"
    echo -e "\nНажмите любую клавишу для продолжения..."
    read -n 1
}

edit_broker_config() {
    clear
    nano broker.toml
}

deposit_stake() {
    clear
    source .env.broker
    echo -e "${BOLD}${PURPLE}Внести USDC стейк${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"
    read -p "Введите сумму стейка в USDC: " amount
    if [[ -n "$amount" ]]; then
        boundless account deposit-stake "$amount"
        echo -e "\nНажмите любую клавишу для продолжения..."
        read -n 1
    fi
}

check_balance() {
    clear
    source .env.broker
    echo -e "${BOLD}${PURPLE}Баланс стейка${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"
    boundless account stake-balance
    echo -e "\nНажмите любую клавишу для продолжения..."
    read -n 1
}

run_benchmark_orders() {
    clear
    source .env.broker
    echo -e "${BOLD}${ORANGE}Бенчмарк по Order ID${RESET}"
    echo -e "${GRAY}──────────────────${RESET}"
    echo "Введите order ID с https://explorer.beboundless.xyz/orders"
    read -p "Order ID (через запятую): " ids
    if [[ -n "$ids" ]]; then
        boundless proving benchmark --request-ids "$ids"
        echo -e "\nНажмите любую клавишу для продолжения..."
        read -n 1
    fi
}

monitor_gpus() {
    clear
    nvtop
}

# Comprehensive health check
health_check() {
    clear
    echo -e "${BOLD}${CYAN}Проверка состояния системы${RESET}"
    echo -e "${GRAY}════════════════════════════════════════${RESET}\n"

    # 1. Configuration check
    echo -e "${BOLD}1. Статус конфигурации:${RESET}"
    if validate_config > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Конфигурация валидна${RESET}"
        source .env.broker
        echo -e "   ${GRAY}Сеть: $(grep ORDER_STREAM_URL .env.broker | cut -d'/' -f3 | cut -d'.' -f1)${RESET}"
        echo -e "   ${GRAY}Кошелек: ${PRIVATE_KEY:0:6}...${PRIVATE_KEY: -4}${RESET}"
    else
        echo -e "   ${RED}✗ Обнаружены проблемы с конфигурацией${RESET}"
        validate_config
    fi

    # 2. Container status
    echo -e "\n${BOLD}2. Статус сервисов:${RESET}"
    local critical_services=("broker" "rest_api" "postgres" "redis" "minio")
    local all_healthy=true

    for service in "${critical_services[@]}"; do
        if is_container_running "$service"; then
            echo -e "   ${GREEN}✓ $service${RESET}"
        else
            echo -e "   ${RED}✗ $service${RESET}"
            all_healthy=false
        fi
    done

    # 3. GPU status
    echo -e "\n${BOLD}3. Статус GPU:${RESET}"
    if command -v nvidia-smi > /dev/null 2>&1; then
        local gpu_count=$(nvidia-smi -L 2>/dev/null | wc -l)
        if [[ $gpu_count -gt 0 ]]; then
            echo -e "   ${GREEN}✓ Обнаружено GPU: $gpu_count${RESET}"
            # Show GPU utilization
            nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | while IFS=',' read -r idx name util mem_used mem_total; do
                echo -e "   ${GRAY}GPU $idx: $name — ${util}% используется, ${mem_used}MB/${mem_total}MB${RESET}"
            done
        else
            echo -e "   ${RED}✗ GPU не обнаружены${RESET}"
        fi
    else
        echo -e "   ${RED}✗ nvidia-smi не найден${RESET}"
    fi

    # 4. Network connectivity
    echo -e "\n${BOLD}4. Сетевой статус:${RESET}"
    if [[ -n "$RPC_URL" ]]; then
        echo -e "   ${GRAY}Тестируем подключение к RPC...${RESET}"
        if curl -s -X POST "$RPC_URL" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            --connect-timeout 5 > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓ RPC подключение успешно${RESET}"
        else
            echo -e "   ${RED}✗ Ошибка подключения к RPC${RESET}"
        fi
    else
        echo -e "   ${RED}✗ RPC URL не настроен${RESET}"
    fi

    # 5. Overall status
    echo -e "\n${BOLD}5. Итоговый статус:${RESET}"
    if [[ "$all_healthy" == true ]] && validate_config > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Система здорова и готова к работе${RESET}"
    else
        echo -e "   ${YELLOW}⚠ Обнаружены проблемы — см. детали выше${RESET}"
    fi

    echo -e "\n${GRAY}Нажмите любую клавишу для продолжения...${RESET}"
    read -n 1
}

# Initial container status check on startup
echo -e "${CYAN}Проверка состояния сервисов...${RESET}"
if docker compose ps 2>/dev/null | grep -q "broker"; then
    if ! is_container_running "broker"; then
        echo -e "\n${RED}${BOLD}⚠ Контейнер брокера работает некорректно!${RESET}"
        echo -e "${YELLOW}Проверьте логи, чтобы узнать причину ошибки.${RESET}"
        sleep 2
    fi
fi

# Main menu loop
current=0
menu_count=0

# Count actual menu items
for item in "${menu_items[@]}"; do
    if [[ ! $item == *":"* ]]; then
        ((menu_count++))
    fi
done

while true; do
    draw_menu $current
    key=$(get_key)

    case $key in
        up)
            ((current--))
            if [ $current -lt 0 ]; then current=$((menu_count-1)); fi
            ;;
        down)
            ((current++))
            if [ $current -ge $menu_count ]; then current=0; fi
            ;;
        enter)
            selected=$(get_menu_item $current)
            case "$selected" in
                "Запустить брокер") start_broker ;;
                "Запустить Bento (только для тестирования)") start_bento ;;
                "Остановить сервисы") stop_services ;;
                "Просмотреть логи") view_logs ;;
                "Проверка состояния") health_check ;;
                "Сменить сеть") change_network ;;
                "Сменить приватный ключ") change_private_key ;;
                "Редактировать конфиг брокера") edit_broker_config ;;
                "Внести стейк") deposit_stake ;;
                "Проверить баланс стейка") check_balance ;;
                "Запустить бенчмарк (Order IDs)") run_benchmark_orders ;;
                "Мониторинг GPU") monitor_gpus ;;
                "Выход")
                    clear
                    echo -e "${GREEN}До свидания!${RESET}"
                    exit 0
                    ;;
            esac
            ;;
        quit)
            clear
            echo -e "${GREEN}До свидания!${RESET}"
            exit 0
            ;;
    esac
done
EOF
    chmod +x "$INSTALL_DIR/prover.sh"
    success "Управляющий скрипт создан в $INSTALL_DIR/prover.sh"
}

# Main installation flow
main() {
    echo -e "${BOLD}${CYAN}Установка Boundless Prover Node от 0xMoei${RESET}"
    echo "========================================"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    touch "$ERROR_LOG"
    echo "[START] Установка начата $(date)" >> "$LOG_FILE"
    echo "[START] Установка начата $(date)" >> "$ERROR_LOG"
    info "Логи будут сохранены в:"
    info "  - Полный лог: cat $LOG_FILE"
    info "  - Лог ошибок: cat $ERROR_LOG"
    echo
    if [[ $EUID -eq 0 ]]; then
        if [[ "$ALLOW_ROOT" == "true" ]]; then
            warning "Запуск от root (разрешено через --allow-root)"
        else
            warning "Скрипт запущен от root пользователя"
            prompt "Продолжить? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[yY]$ ]]; then
                exit $EXIT_USER_ABORT
            fi
        fi
    else
        warning "Для работы скрипта требуются root-права или пользователь с соответствующими правами"
        info "Убедитесь, что у вас есть права на установку пакетов и изменение системных настроек"
    fi
    check_os
    update_system
    info "Устанавливаем все зависимости..."
    install_basic_deps
    # install_gpu_drivers
    install_docker
    install_nvidia_toolkit
    install_rust
    install_just
    # install_cuda
    install_rust_deps
    clone_repository
    detect_gpus
    configure_compose
    configure_network
    configure_broker
    create_management_script
    echo -e "\n${GREEN}${BOLD}Установка завершена!${RESET}"
    echo "[SUCCESS] Установка завершена успешно $(date)" >> "$LOG_FILE"
    echo -e "\n${BOLD}Дальнейшие действия:${RESET}"
    echo "1. Теперь вы можете управлять нодой Prover через скрипт"
    echo "2. Перейдите в директорию: cd $INSTALL_DIR"
    echo "3. Запустите управляющий скрипт: ./prover.sh"
    echo "4. Убедитесь, что вы внесли USDC стейк через управляющий скрипт"
    echo -e "\n${YELLOW}Важно:${RESET} Всегда проверяйте логи при запуске!"
    echo "Мониторинг GPU: nvtop"
    echo "Мониторинг системы: htop"
    echo -e "\n${CYAN}Логи установки скрипта сохранены в:${RESET}"
    echo "  - $LOG_FILE"
    echo "  - $ERROR_LOG"
    echo -e "\n${YELLOW}Внимание по безопасности:${RESET}"
    echo "Ваш приватный ключ хранится в файлах $INSTALL_DIR/.env.*."
    echo "Убедитесь, что эти файлы недоступны для посторонних."
    echo "Текущие права: 600 (только владелец может читать и писать)."
    if [[ "$START_IMMEDIATELY" == "true" ]]; then
        cd "$INSTALL_DIR"
        ./prover.sh
    else
        prompt "Перейти к управляющему скрипту сейчас? (y/N): "
        read -r start_now
        if [[ "$start_now" =~ ^[yY]$ ]]; then
            cd "$INSTALL_DIR"
            ./prover.sh
        fi
    fi
}

# Run main
main
