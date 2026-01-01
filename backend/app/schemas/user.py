from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    phone: str
    name: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None
    birthday: Optional[date] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None
    birthday: Optional[date] = None


class UserOut(BaseModel):
    id: int
    phone: str
    name: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None
    birthday: Optional[date] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AddressBase(BaseModel):
    label: Optional[str] = None
    address_text: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    city: Optional[str] = None
    entrance: Optional[str] = None
    comment: Optional[str] = None
    is_default: Optional[bool] = False


class AddressCreate(AddressBase):
    pass


class AddressUpdate(AddressBase):
    pass


class AddressOut(AddressBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class LoyaltyOut(BaseModel):
    points_available: float
    points_spent: float
    cashback_percent: float
    orders_count: int
    orders_sum: float
    first_order_date: Optional[date] = None

    class Config:
        from_attributes = True

