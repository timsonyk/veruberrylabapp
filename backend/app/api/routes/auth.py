import hashlib
import hmac
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.security import create_access_token
from app.models.user import User
from app.schemas.auth import (
    TelegramAuthRequest, TokenResponse,
    TelegramBotAuthRequest, TelegramBotAuthStatus
)
from app.schemas.user import UserOut
from app.core.config import get_settings


router = APIRouter(prefix="/auth", tags=["auth"])


def validate_telegram_auth(data: TelegramAuthRequest, bot_token: str) -> bool:
    """
    Validate Telegram Login Widget authentication data.
    
    Based on: https://core.telegram.org/widgets/login#checking-authorization
    
    Args:
        data: Telegram auth data
        bot_token: Telegram bot token
        
    Returns:
        bool: True if valid, False otherwise
    """
    # Create data check string
    check_data = {
        'id': str(data.id),
        'auth_date': str(data.auth_date),
    }
    
    if data.first_name:
        check_data['first_name'] = data.first_name
    if data.last_name:
        check_data['last_name'] = data.last_name
    if data.username:
        check_data['username'] = data.username
    if data.photo_url:
        check_data['photo_url'] = data.photo_url
    
    # Sort keys and create check string
    data_check_string = '\n'.join([f"{k}={v}" for k, v in sorted(check_data.items())])
    
    # Create secret key from bot token
    secret_key = hashlib.sha256(bot_token.encode()).digest()
    
    # Calculate HMAC-SHA256
    calculated_hash = hmac.new(secret_key, data_check_string.encode(), hashlib.sha256).hexdigest()
    
    return calculated_hash == data.hash


# Store for pending and completed Telegram bot auth
# In production, use Redis or database
_telegram_bot_auth: dict[str, dict] = {}


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


@router.post("/telegram-bot/init", response_model=dict)
def init_telegram_bot_auth(payload: TelegramBotAuthRequest):
    """
    Initialize Telegram bot authentication.
    Returns the bot username for deep linking.
    """
    import time

    phone = normalize_phone(payload.phone)

    # Store pending auth with timestamp
    _telegram_bot_auth[f"pending:{phone}"] = {
        "phone": phone,
        "timestamp": time.time(),
        "status": "pending"
    }

    return {
        "status": "pending",
        "phone": phone,
        "bot_username": "veryberrylab1_bot",
        "deep_link": f"https://t.me/veryberrylab1_bot?start=auth"
    }


@router.post("/telegram-bot/check", response_model=TelegramBotAuthStatus)
def check_telegram_bot_auth(payload: TelegramBotAuthRequest, db: Session = Depends(get_db)):
    """
    Check if Telegram bot authentication is completed.
    The app polls this endpoint after redirecting user to Telegram.
    """
    import time

    # Try to import from telegram_bot module
    try:
        import sys
        import os
        sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
        from telegram_bot import get_auth_by_phone, completed_auth

        phone = normalize_phone(payload.phone)
        auth_data = get_auth_by_phone(phone)

        if auth_data:
            # Auth completed via Telegram bot
            user = db.query(User).filter(User.phone == phone).first()
            if user:
                settings = get_settings()
                return TelegramBotAuthStatus(
                    status="completed",
                    access_token=auth_data["token"],
                    user=UserOut.model_validate(user),
                    expires_in=settings.access_token_expire_minutes * 60,
                    issued_at=datetime.now(timezone.utc)
                )
    except ImportError:
        pass

    # Check if user exists and has telegram_id (already verified via bot previously)
    phone = normalize_phone(payload.phone)
    user = db.query(User).filter(User.phone == phone, User.telegram_id.isnot(None)).first()

    if user:
        # User exists and has telegram_id - they're verified
        settings = get_settings()
        token = create_access_token(subject=user.phone)
        return TelegramBotAuthStatus(
            status="completed",
            access_token=token,
            user=UserOut.model_validate(user),
            expires_in=settings.access_token_expire_minutes * 60,
            issued_at=datetime.now(timezone.utc)
        )

    return TelegramBotAuthStatus(status="pending")


@router.post("/telegram", response_model=TokenResponse)
def telegram_auth(payload: TelegramAuthRequest, db: Session = Depends(get_db)):
    """
    Authenticate user via Telegram Login Widget.
    
    Validates the HMAC signature and creates or logs in the user.
    """
    settings = get_settings()
    
    # Check if telegram bot token is configured
    if not settings.telegram_bot_token:
        raise HTTPException(status_code=503, detail="Telegram authentication not configured")
    
    # Validate auth_date (must be within last 24 hours)
    current_timestamp = int(datetime.now(timezone.utc).timestamp())
    if current_timestamp - payload.auth_date > 86400:  # 24 hours
        raise HTTPException(status_code=400, detail="Authentication data is too old")
    
    # Validate HMAC signature
    if not validate_telegram_auth(payload, settings.telegram_bot_token):
        raise HTTPException(status_code=401, detail="Invalid authentication signature")
    
    # Find or create user by telegram_id
    user = db.query(User).filter(User.telegram_id == payload.id).first()
    
    if not user:
        # Create new user with telegram_id
        # Use telegram username or id as phone placeholder if no phone
        phone_placeholder = f"+tg{payload.id}"
        
        # Check if this phone placeholder already exists
        existing_user = db.query(User).filter(User.phone == phone_placeholder).first()
        if existing_user:
            # Update existing user with telegram_id
            user = existing_user
            user.telegram_id = payload.id
        else:
            # Create new user
            user = User(
                phone=phone_placeholder,
                telegram_id=payload.id,
                name=f"{payload.first_name or ''} {payload.last_name or ''}".strip() or None,
            )
            db.add(user)
    else:
        # Update user name if provided and not set
        if not user.name and (payload.first_name or payload.last_name):
            user.name = f"{payload.first_name or ''} {payload.last_name or ''}".strip()
    
    db.commit()
    db.refresh(user)
    
    # Create access token (using phone as subject)
    token = create_access_token(subject=user.phone)
    
    return TokenResponse(
        access_token=token,
        user=UserOut.model_validate(user),
        expires_in=settings.access_token_expire_minutes * 60,
        issued_at=datetime.now(timezone.utc),
    )

