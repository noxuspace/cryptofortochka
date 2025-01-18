import aiohttp
import asyncio
import random

# URL API
url = "https://$NODE_ID.gaia.domains/v1/chat/completions"

# Заголовки запроса
headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

# Функция для чтения ролей и фраз из файлов
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
    """Создаёт сообщение, гарантируя, что одно из них имеет роль 'user'."""
    user_message = generate_random_message()
    user_message["role"] = "user"  # Гарантируем, что хотя бы одно сообщение — от 'user'
    other_message = generate_random_message()
    return [user_message, other_message]

# Отправка запроса к API
async def chat_loop():
    async with aiohttp.ClientSession() as session:
        while True:
            messages = create_message()
            user_message = next((msg["content"] for msg in messages if msg["role"] == "user"), "No user message found")
            
            # Логируем отправленный вопрос
            print(f"Отправлен вопрос: {user_message}")
            
            data = {"messages": messages}

            try:
                async with session.post(url, json=data, headers=headers, timeout=60) as response:
                    if response.status == 200:
                        result = await response.json()
                        assistant_response = result["choices"][0]["message"]["content"]
                        print(f"Получен ответ: {assistant_response}\n{'-'*50}")
                    else:
                        print(f"Ошибка: {response.status} - {await response.text()}")
            except asyncio.TimeoutError:
                print("Тайм-аут ожидания. Отправляю следующий запрос...")
            except Exception as e:
                print(f"Ошибка: {e}")

            # Небольшая задержка перед отправкой следующего сообщения
            await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(chat_loop())
