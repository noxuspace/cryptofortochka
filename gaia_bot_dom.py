import aiohttp
import asyncio
import random
import os

# URL API Gaia
API_URL = "https://вашеимя.gaia.domains/v1/chat/completions"
GAIA_API_KEY = os.getenv("$GAIA_API_KEY")

# Заголовки запроса
HEADERS = {
    "Authorization": f"Bearer {$GAIA_API_KEY}",
    "Accept": "application/json",
    "Content-Type": "application/json"
}

# Функция для чтения фраз и ролей из файлов
def load_from_file(file_name):
    with open(file_name, "r") as file:
        return [line.strip() for line in file.readlines()]

# Загрузка ролей и фраз
roles = load_from_file("roles.txt")
phrases = load_from_file("phrases.txt")

# Генерация случайного сообщения
def generate_random_message():
    role = random.choice(roles)
    content = random.choice(phrases)
    return {"role": role, "content": content}

# Создание сообщения
def create_message():
    user_message = generate_random_message()
    user_message["role"] = "user"
    other_message = generate_random_message()
    return [user_message, other_message]

# Функция для одного потока общения с API
async def chat_worker(worker_id):
    async with aiohttp.ClientSession() as session:
        while True:
            messages = create_message()
            user_message = next((msg["content"] for msg in messages if msg["role"] == "user"), "No user message found")
            print(f"[Worker {worker_id}] Отправлен вопрос: {user_message}")

            data = {"messages": messages}
            try:
                async with session.post(API_URL, json=data, headers=HEADERS, timeout=300) as response:
                    if response.status == 200:
                        result = await response.json()
                        assistant_response = result["choices"][0]["message"]["content"]
                        print(f"[Worker {worker_id}] Получен ответ: {assistant_response}\n{'-'*50}")
                    else:
                        print(f"[Worker {worker_id}] Ошибка: {response.status} {await response.text()}")
            except asyncio.TimeoutError:
                print(f"[Worker {worker_id}] Тайм-аут ожидания. Отправляю следующий запрос...")
            except Exception as e:
                print(f"[Worker {worker_id}] Ошибка: {e}")

            await asyncio.sleep(3)

# Главная функция: запускает несколько потоков
async def main(num_workers):
    tasks = [chat_worker(i) for i in range(num_workers)]
    await asyncio.gather(*tasks)

# Запрос количества потоков у пользователя
if __name__ == "__main__":
    while True:
        try:
            num_threads = int(input("Введите количество потоков (сколько нод подключено): ").strip())
            if num_threads > 0:
                break
            else:
                print("Число потоков должно быть больше 0!")
        except ValueError:
            print("Ошибка! Введите число.")

    print(f"Запускаем {num_threads} потоков...")
    asyncio.run(main(num_threads))
