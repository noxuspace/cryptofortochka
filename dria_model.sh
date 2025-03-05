#!/bin/bash

# Путь к файлу .env
ENV_FILE="$HOME/.dria/dkn-compute-launcher/.env"

# Новое значение для DKN_MODELS
NEW_MODELS="DKN_MODELS=,gemini-1.5-flash,gemini-1.5-pro,gemini-2.0-flash"

# Проверяем, существует ли файл
if [[ -f "$ENV_FILE" ]]; then
    # Создаём резервную копию перед изменениями
    cp "$ENV_FILE" "$ENV_FILE.bak"

    # Заменяем строку с DKN_MODELS= на новую
    sed -i "/^DKN_MODELS=/c\\$NEW_MODELS" "$ENV_FILE"

    echo "✅ Файл .env обновлён."
else
    echo "❌ Файл .env не найден: $ENV_FILE"
    exit 1
fi

# Перезапуск сервиса dria и показ логов
echo "🔄 Перезапуск сервиса dria..."
sudo systemctl restart dria && sudo journalctl -u dria -f --no-hostname -o cat
