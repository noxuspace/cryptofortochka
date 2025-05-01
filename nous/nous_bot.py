import time
import requests
import logging

# Конфигурация API Nous
NOUS_API_URL = "https://inference-api.nousresearch.com/v1/chat/completions"
NOUS_API_KEY = "$API_KEY"  # Замените на ваш API-ключ
MODEL = "Hermes-3-Llama-3.1-70B"      # Или укажите нужную модель
MAX_TOKENS = 60
TEMPERATURE = 0.8
TOP_P = 0.9
DELAY_BETWEEN_QUESTIONS = 30  # задержка между вопросами в секундах

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_response(question: str) -> str:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {NOUS_API_KEY}"
    }
    data = {
        "messages": [{"role": "user", "content": question}],
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
        "top_p": TOP_P
    }
    response = requests.post(NOUS_API_URL, headers=headers, json=data, timeout=30)
    response.raise_for_status()
    json_response = response.json()
    # Предполагается, что ответ имеет структуру, аналогичную OpenAI API:
    return json_response.get("choices", [{}])[0].get("message", {}).get("content", "No answer")

def main():
    # Чтение вопросов из файла "questions.txt"
    try:
        with open("questions.txt", "r", encoding="utf-8") as f:
            questions = [line.strip() for line in f if line.strip()]
    except Exception as e:
        logger.error(f"Ошибка чтения файла questions.txt: {e}")
        return

    if not questions:
        logger.error("В файле questions.txt нет вопросов.")
        return

    index = 0
    while True:
        question = questions[index]
        logger.info(f"Вопрос #{index+1}: {question}")
        try:
            answer = get_response(question)
            logger.info(f"Ответ: {answer}")
        except Exception as e:
            logger.error(f"Ошибка при получении ответа для вопроса: {question}\n{e}")
        index = (index + 1) % len(questions)
        time.sleep(DELAY_BETWEEN_QUESTIONS)

if __name__ == "__main__":
    main()
