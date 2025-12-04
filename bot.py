import logging
import re
import asyncio
import requests
from telegram import Update, InputMediaPhoto
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)
from config import TELEGRAM_TOKEN, WB_TOKEN_1, WB_TOKEN_2

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat = update.effective_chat
    await chat.send_message(
        "Привет! Пришли один или много артикулов WB — я пришлю фото и итоговый отчёт.\n"
        "В группах и каналах бот отвечает только на сообщения с цифрами."
    )


def wb_request(token: str, nm: str):
    url = "https://content-api.wildberries.ru/content/v2/get/cards/list"
    headers = {"Authorization": token, "Content-Type": "application/json"}
    payload = {
        "settings": {
            "filter": {"textSearch": nm, "withPhoto": 1},
            "sort": {"ascending": False},
            "cursor": {"limit": 1},
        }
    }

    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=10)
    except Exception:
        return None

    if resp.status_code != 200:
        return None

    try:
        return resp.json()
    except:
        return None


def get_photo(nm: str):
    tokens = [WB_TOKEN_1, WB_TOKEN_2]

    for token in tokens:
        if not token:
            continue

        data = wb_request(token, nm)
        if not data:
            continue

        cards = data.get("cards") or []
        if not cards:
            continue

        photos = cards[0].get("photos") or []
        if not photos:
            continue

        photo = photos[0]
        return (
            photo.get("big")
            or photo.get("c516x688")
            or photo.get("square")
            or photo.get("tm")
        )

    return None


async def handle_articles(update: Update, context: ContextTypes.DEFAULT_TYPE):
    msg = update.effective_message
    chat = update.effective_chat
    text = msg.text or ""

    # ВСЕ подряд числа как есть (без удаления дублей)
    articles = re.findall(r"\d+", text)

    if not articles:
        if chat.type == "private":
            await chat.send_message("Пришли артикулы WB 🙂")
        return

    MAX_ITEMS = 100
    if len(articles) > MAX_ITEMS:
        articles = articles[:MAX_ITEMS]
        await chat.send_message(
            f"Обнаружено больше {MAX_ITEMS} артикулов, обработаю первые {MAX_ITEMS}."
        )

    await chat.send_message(f"Нашёл {len(articles)} артикулов, ищу фото...")

    found = []      # сюда пишем артикулы, по которым фото нашлось (включая дубли)
    not_found = []  # сюда — те, по которым не нашли (тоже с дублями)
    photos = []     # список URL фоток (по одному на каждый артикул, включая дубли)

    for nm in articles:
        url = get_photo(nm)
        if url:
            found.append(nm)
            photos.append(url)
        else:
            not_found.append(nm)
        await asyncio.sleep(0.1)

    # === ОТПРАВКА АЛЬБОМОВ ПО 10, С КОЛИЧЕСКОМ АЛЬБОМОВ ===

    CHUNK = 10

    if len(photos) > 1:
        for i in range(0, len(photos), CHUNK):
            chunk = photos[i:i + CHUNK]
            media = [InputMediaPhoto(url) for url in chunk]

            try:
                await chat.send_media_group(media)
            except Exception as e:
                logger.error(f"Ошибка отправки альбома: {e}")

            await asyncio.sleep(0.6)  # пауза между альбомами
    else:
        if len(photos) == 1:
            try:
                await chat.send_photo(photos[0])
            except Exception as e:
                logger.error(f"Ошибка отправки фото: {e}")

    # === ИТОГОВЫЙ ОТЧЁТ (с учётом дублей) ===

    summary = [
        "Готово ✅",
        f"Всего обработано: {len(articles)}",
        f"С фото: {len(found)}",
        f"Без фото: {len(not_found)}",
    ]

    if found:
        summary.append("Нашлись: " + ", ".join(found))
    if not_found:
        summary.append("Не найдено: " + ", ".join(not_found))

    await chat.send_message("\n".join(summary))


def main():
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_articles))
    app.run_polling()


if __name__ == "__main__":
    main()