from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.user import UserOut


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
    expires_in: int
    issued_at: datetime


class AdminLogin(BaseModel):
    username: str
    password: str


class TelegramAuthRequest(BaseModel):
    """Telegram Login Widget auth data."""
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    photo_url: Optional[str] = None
    auth_date: int
    hash: str


class TelegramBotAuthRequest(BaseModel):
    """Request to initiate Telegram bot auth."""
    phone: str = Field(..., example="+79161234567")


class TelegramBotAuthStatus(BaseModel):
    """Status of Telegram bot auth."""
    status: str  # "pending", "completed", "expired"
    access_token: Optional[str] = None
    user: Optional[UserOut] = None
    expires_in: Optional[int] = None
    issued_at: Optional[datetime] = None

