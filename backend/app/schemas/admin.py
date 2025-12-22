from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel


class AdminLoginRequest(BaseModel):
    username: str
    password: str


class CategoryCreate(BaseModel):
    name: str
    sort_order: int = 0
    is_active: bool = True


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class ProductCreate(BaseModel):
    name: str
    category_id: int
    description: Optional[str] = None
    base_price: float
    size_label: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True
    media: Optional[list] = None


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category_id: Optional[int] = None
    description: Optional[str] = None
    base_price: Optional[float] = None
    size_label: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None
    media: Optional[list] = None


class ProductSizeCreate(BaseModel):
    product_id: int
    name: str
    base_price: float
    sort_order: int = 0


class ProductSizeUpdate(BaseModel):
    name: Optional[str] = None
    base_price: Optional[float] = None
    sort_order: Optional[int] = None


class ModificationGroupCreate(BaseModel):
    product_ids: Optional[List[int]] = None
    name: str
    min_count: int = 0
    max_count: int = 1
    type: str = "single"
    sort_order: int = 0
    is_active: bool = True


class ModificationGroupUpdate(BaseModel):
    product_ids: Optional[List[int]] = None
    name: Optional[str] = None
    min_count: Optional[int] = None
    max_count: Optional[int] = None
    type: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class ModificationOptionCreate(BaseModel):
    group_id: int
    name: str
    extra_price: float = 0
    is_default: bool = False
    sort_order: int = 0
    is_active: bool = True


class ModificationOptionUpdate(BaseModel):
    name: Optional[str] = None
    extra_price: Optional[float] = None
    is_default: Optional[bool] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class BannerCreate(BaseModel):
    title: str
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class BannerUpdate(BaseModel):
    title: Optional[str] = None
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class PromoCodeCreate(BaseModel):
    code: str
    discount_type: str
    discount_value: float
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    min_order_total: Optional[float] = None
    allowed_category_ids: Optional[list[int]] = None
    usage_limit: Optional[int] = None
    is_active: bool = True


class PromoCodeUpdate(BaseModel):
    code: Optional[str] = None
    discount_type: Optional[str] = None
    discount_value: Optional[float] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    min_order_total: Optional[float] = None
    allowed_category_ids: Optional[list[int]] = None
    usage_limit: Optional[int] = None
    is_active: Optional[bool] = None


class PickupLocationCreate(BaseModel):
    city: str
    address: str
    schedule_text: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class PickupLocationUpdate(BaseModel):
    city: Optional[str] = None
    address: Optional[str] = None
    schedule_text: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class DeliveryZoneCreate(BaseModel):
    city: str
    center_lat: float
    center_lng: float
    radius_meters: int
    delivery_fee: float
    sla_minutes: int = 180
    min_order_total: Optional[float] = None
    is_active: bool = True
    sort_order: int = 0


class DeliveryZoneUpdate(BaseModel):
    city: Optional[str] = None
    center_lat: Optional[float] = None
    center_lng: Optional[float] = None
    radius_meters: Optional[int] = None
    delivery_fee: Optional[float] = None
    sla_minutes: Optional[int] = None
    min_order_total: Optional[float] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class FAQCreate(BaseModel):
    question: str
    answer: str
    sort_order: int = 0
    is_active: bool = True


class FAQUpdate(BaseModel):
    question: Optional[str] = None
    answer: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class AppTextUpdate(BaseModel):
    key: str
    value: str


class LoyaltySettingsUpdate(BaseModel):
    cashback_percent: float


