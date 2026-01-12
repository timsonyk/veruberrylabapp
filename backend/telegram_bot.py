"""
VeryBerryLab Telegram Bot for phone number verification.

This bot handles phone number authentication for the iOS app.
Users enter their phone in the app, get redirected to this bot,
share their phone number, and the bot validates and confirms auth.
"""

import os
import sys
import hashlib
import time
import logging
import httpx

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from telegram import Update, ReplyKeyboardMarkup, KeyboardButton, ReplyKeyboardRemove
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# Configure logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Bot token from environment
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "REDACTED")
BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:8000")


def normalize_phone(phone: str) -> str:
    """Normalize phone number to +7XXXXXXXXXX format."""
    digits = "".join(c for c in phone if c.isdigit())

    if digits.startswith("8") and len(digits) == 11:
        digits = "7" + digits[1:]
    elif digits.startswith("7") and len(digits) == 11:
        pass
    elif len(digits) == 10:
        digits = "7" + digits

    return f"+{digits}"


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /start command."""
    keyboard = ReplyKeyboardMarkup(
        [[KeyboardButton("Поделиться номером телефона", request_contact=True)]],
        resize_keyboard=True,
        one_time_keyboard=True
    )

    await update.message.reply_text(
        "Добро пожаловать в VeryBerryLab! 🍓\n\n"
        "Для входа в приложение нажмите кнопку ниже и поделитесь номером телефона.",
        reply_markup=keyboard
    )


async def handle_contact(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle shared contact (phone number)."""
    contact = update.message.contact

    if not contact:
        await update.message.reply_text(
            "Не удалось получить номер телефона. Попробуйте еще раз."
        )
        return

    # Verify that the user is sharing their own number
    if contact.user_id != update.effective_user.id:
        await update.message.reply_text(
            "Пожалуйста, поделитесь своим номером телефона, а не чужим контактом."
        )
        return

    phone = normalize_phone(contact.phone_number)
    telegram_id = update.effective_user.id
    first_name = update.effective_user.first_name or ""
    last_name = update.effective_user.last_name or ""

    logger.info(f"Phone verification: {phone} from Telegram user {telegram_id}")

    # Notify backend about completed auth
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{BACKEND_URL}/auth/telegram-bot/confirm",
                json={
                    "phone": phone,
                    "telegram_id": telegram_id,
                    "first_name": first_name,
                    "last_name": last_name,
                },
                timeout=10.0
            )
            if response.status_code == 200:
                logger.info(f"Auth confirmed for phone: {phone}")
            else:
                logger.error(f"Failed to confirm auth: {response.status_code} {response.text}")
    except Exception as e:
        logger.error(f"Error notifying backend: {e}")

    await update.message.reply_text(
        "Отлично! Вы успешно авторизованы. ✅\n\n"
        "Вернитесь в приложение VeryBerryLab — вход будет выполнен автоматически.",
        reply_markup=ReplyKeyboardRemove()
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /help command."""
    await update.message.reply_text(
        "Этот бот используется для авторизации в приложении VeryBerryLab.\n\n"
        "Команды:\n"
        "/start - Начать авторизацию\n"
        "/help - Показать справку\n\n"
        "Для авторизации нажмите кнопку 'Поделиться номером телефона'."
    )


def main():
    """Start the bot."""
    if not BOT_TOKEN:
        logger.error("TELEGRAM_BOT_TOKEN not set!")
        sys.exit(1)

    logger.info("Starting VeryBerryLab Telegram Bot...")

    application = Application.builder().token(BOT_TOKEN).build()

    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(MessageHandler(filters.CONTACT, handle_contact))

    logger.info("Bot is running...")
    application.run_polling(allowed_updates=Update.ALL_TYPES, drop_pending_updates=True)


if __name__ == "__main__":
    main()
