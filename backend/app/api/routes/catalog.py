from typing import Optional
from urllib.parse import urlparse

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_db
from app.models.catalog import Banner, Category, Product, ModificationGroup, DeliveryZone, StoreLocation, FAQ
from app.schemas.catalog import BannerOut, CategoryOut, ProductOut
from app.services.pricing import _find_delivery_zone, _point_in_polygon

router = APIRouter(prefix="/catalog", tags=["catalog"])


# --- Delivery Fee Check ---

class DeliveryCheckRequest(BaseModel):
    lat: float
    lng: float
    city: str = "Москва"


class DeliveryCheckResponse(BaseModel):
    available: bool
    delivery_fee: float
    sla_minutes: int
    min_order_total: Optional[float] = None
    zone_name: Optional[str] = None


@router.post("/delivery-check", response_model=DeliveryCheckResponse)
def check_delivery(payload: DeliveryCheckRequest, db: Session = Depends(get_db)):
    """Check delivery availability and fee for given coordinates."""
    zone = _find_delivery_zone(db, city=payload.city, lat=payload.lat, lng=payload.lng)
    
    if zone:
        return DeliveryCheckResponse(
            available=True,
            delivery_fee=float(zone.delivery_fee),
            sla_minutes=zone.sla_minutes,
            min_order_total=float(zone.min_order_total) if zone.min_order_total else None,
            zone_name=f"Зона {zone.id}"
        )
    else:
        # No zone = unavailable
        return DeliveryCheckResponse(
            available=False,
            delivery_fee=0.0,
            sla_minutes=0,
            min_order_total=None,
            zone_name=None
        )


class DeliveryZoneOut(BaseModel):
    id: int
    city: str
    name: str
    polygon: Optional[list] = None
    delivery_fee: float
    sla_minutes: int
    min_order_total: Optional[float] = None
    is_active: bool


@router.get("/delivery-zones", response_model=list[DeliveryZoneOut])
def list_delivery_zones(city: str = Query("Москва"), db: Session = Depends(get_db)):
    """Get all active delivery zones for given city."""
    zones = db.query(DeliveryZone).filter(
        DeliveryZone.city == city,
        DeliveryZone.is_active == True  # noqa: E712
    ).order_by(DeliveryZone.sort_order).all()
    return zones


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).filter(Category.is_active == True).order_by(Category.sort_order).all()  # noqa: E712
    return categories


@router.get("/products", response_model=list[ProductOut])
def list_products(
    category_id: int | None = Query(None),
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    query = db.query(Product).options(
        joinedload(Product.sizes),
        joinedload(Product.modification_groups).joinedload(ModificationGroup.options),
    )
    if category_id:
        query = query.filter(Product.category_id == category_id)
    if active_only:
        query = query.filter(Product.is_active == True)  # noqa: E712
    products = query.order_by(Product.sort_order).all()
    return products


@router.get("/products/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = (
        db.query(Product)
        .options(
            joinedload(Product.sizes),
            joinedload(Product.modification_groups).joinedload(ModificationGroup.options),
        )
        .filter(Product.id == product_id)
        .first()
    )
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.get("/banners", response_model=list[BannerOut])
def list_banners(request: Request, db: Session = Depends(get_db)):
    banners = (
        db.query(Banner)
        .filter(Banner.is_active == True)  # noqa: E712
        .order_by(Banner.sort_order)
        .all()
    )

    # Normalize stored URLs (e.g. old http://localhost:8000/uploads/...) to the current public host.
    forwarded_proto = request.headers.get("x-forwarded-proto")
    forwarded_host = request.headers.get("x-forwarded-host")
    host = forwarded_host or request.headers.get("host") or request.url.netloc
    scheme = forwarded_proto or request.url.scheme
    base = f"{scheme}://{host}".rstrip("/")

    def normalize_image_url(image_url: str | None) -> str | None:
        if not image_url:
            return None
        try:
            parsed = urlparse(image_url)
        except Exception:
            return image_url

        # Relative URLs → make absolute to current host
        if not parsed.scheme and image_url.startswith("/"):
            return f"{base}{image_url}"

        # Absolute URL but points to local dev host → rewrite to current host
        if parsed.netloc in ("localhost", "localhost:8000", "127.0.0.1", "127.0.0.1:8000"):
            return f"{base}{parsed.path}"

        return image_url

    out: list[BannerOut] = []
    for b in banners:
        dto = BannerOut.model_validate(b)
        dto = BannerOut(**{**dto.model_dump(), "image_url": normalize_image_url(dto.image_url)})
        out.append(dto)
    return out


@router.get("/store_locations")
def list_store_locations(db: Session = Depends(get_db)):
    """Get list of store locations (public)."""
    return db.query(StoreLocation).filter(StoreLocation.is_active == True).order_by(StoreLocation.sort_order).all()


@router.get("/faqs")
def list_faqs(db: Session = Depends(get_db)):
    """Get list of FAQs (public)."""
    return db.query(FAQ).filter(FAQ.is_active == True).order_by(FAQ.sort_order).all()

