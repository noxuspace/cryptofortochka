#!/bin/bash
set -euo pipefail

USER_NAME="geth_sepolia"
STACK_DIR="/home/${USER_NAME}/eth-docker"
ENV_FILE="${STACK_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Не найден ${ENV_FILE}. Проверь пользователя и путь." >&2
  exit 1
fi

# Бэкап .env
cp -a "${ENV_FILE}" "${ENV_FILE}.bak.$(date +%F_%H-%M-%S)"

# Добавляем/обновляем CL_EXTRAS для Teku: supernode (под PeerDAS)
# Документация eth-docker про CL_EXTRAS: https://ethdocker.com/Support/SwitchClient/
# Документация Teku про флаг: https://docs.teku.consensys.io/reference/cli
if grep -q '^CL_EXTRAS=' "${ENV_FILE}"; then
  sed -i 's|^CL_EXTRAS=.*|CL_EXTRAS=--p2p-subscribe-all-custody-subnets-enabled|' "${ENV_FILE}"
else
  printf "\nCL_EXTRAS=--p2p-subscribe-all-custody-subnets-enabled\n" >> "${ENV_FILE}"
fi

# Обновляем образы и рестартим только консенсус
sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" update
sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" restart consensus

# Быстрая проверка логов
echo "------ Последние строки из консенсуса (ищем subnet/custody) ------"
sudo -u "${USER_NAME}" "${STACK_DIR}/ethd" logs -f consensus | sed -n '1,80p'
