from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_db
from app.models.catalog import Banner, Category, Product, ModificationGroup
from app.schemas.catalog import BannerOut, CategoryOut, ProductOut

router = APIRouter(prefix="/catalog", tags=["catalog"])


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
def list_banners(db: Session = Depends(get_db)):
    banners = (
        db.query(Banner)
        .filter(Banner.is_active == True)  # noqa: E712
        .order_by(Banner.sort_order)
        .all()
    )
    return banners

