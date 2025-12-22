import random
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.security import create_access_token
from app.models.user import AuthCode, User
from app.schemas.auth import AuthRequest, AuthVerify, TokenResponse
from app.schemas.user import UserOut
from app.core.config import get_settings


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/request_code", response_model=dict)
def request_code(payload: AuthRequest, db: Session = Depends(get_db)):
    code = f"{random.randint(1000, 9999)}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
    db.add(AuthCode(phone=payload.phone, code=code, expires_at=expires_at, consumed=False))
    db.commit()
    return {"sent": True, "code_stub": code}


@router.post("/verify", response_model=TokenResponse)
def verify_code(payload: AuthVerify, db: Session = Depends(get_db)):
    auth_code = (
        db.query(AuthCode)
        .filter(AuthCode.phone == payload.phone, AuthCode.code == payload.code, AuthCode.consumed == False)  # noqa: E712
        .order_by(AuthCode.expires_at.desc())
        .first()
    )
    if not auth_code or auth_code.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    auth_code.consumed = True

    user = db.query(User).filter(User.phone == payload.phone).first()
    if not user:
        user = User(phone=payload.phone)
        db.add(user)
        db.commit()
        db.refresh(user)

    token = create_access_token(subject=user.phone)
    settings = get_settings()
    db.commit()
    return TokenResponse(
        access_token=token,
        user=UserOut.model_validate(user),
        expires_in=settings.access_token_expire_minutes * 60,
        issued_at=datetime.now(timezone.utc),
    )

