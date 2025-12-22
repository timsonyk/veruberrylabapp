from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.user import UserOut


class AuthRequest(BaseModel):
    phone: str = Field(..., example="+79161234567")


class AuthVerify(BaseModel):
    phone: str
    code: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
    expires_in: int
    issued_at: datetime


class AdminLogin(BaseModel):
    username: str
    password: str

