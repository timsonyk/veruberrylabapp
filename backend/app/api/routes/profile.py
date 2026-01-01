from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.loyalty import LoyaltyAccount, Referral
from app.models.user import Address, User
from app.schemas.user import AddressCreate, AddressOut, LoyaltyOut, UserOut, UserUpdate

router = APIRouter(prefix="/me", tags=["profile"])


@router.get("", response_model=UserOut)
def get_me(user=Depends(get_current_user)):
    return user


@router.patch("", response_model=UserOut)
def update_me(payload: UserUpdate, db: Session = Depends(get_db), user=Depends(get_current_user)):
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/addresses", response_model=list[AddressOut])
def list_addresses(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(Address).filter(Address.user_id == user.id).all()


@router.post("/addresses", response_model=AddressOut)
def create_address(payload: AddressCreate, db: Session = Depends(get_db), user=Depends(get_current_user)):
    address = Address(user_id=user.id, **payload.model_dump())
    db.add(address)
    db.commit()
    db.refresh(address)
    return address


@router.delete("/addresses/{address_id}", response_model=dict)
def delete_address(address_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    address = db.query(Address).filter(Address.id == address_id, Address.user_id == user.id).first()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")
    db.delete(address)
    db.commit()
    return {"deleted": True}


@router.get("/loyalty", response_model=LoyaltyOut)
def get_loyalty(db: Session = Depends(get_db), user=Depends(get_current_user)):
    # Get or create loyalty account
    account = db.query(LoyaltyAccount).filter(LoyaltyAccount.user_id == user.id).first()
    if not account:
        account = LoyaltyAccount(user_id=user.id)
        db.add(account)
        db.commit()
        db.refresh(account)
    
    # Get user data with orders info
    user_data = db.query(User).filter(User.id == user.id).first()
    
    return LoyaltyOut(
        points_available=account.balance,
        points_spent=account.points_spent,
        cashback_percent=account.cashback_percent,
        orders_count=user_data.orders_count,
        orders_sum=float(user_data.orders_sum) if user_data.orders_sum else 0.0,
        first_order_date=user_data.first_order_date,
    )


@router.get("/cards", response_model=dict)
def list_cards():
    # Stub: would show saved tokens from provider
    return {"cards": []}


@router.get("/referrals", response_model=dict)
def list_referrals(db: Session = Depends(get_db), user=Depends(get_current_user)):
    refs = db.query(Referral).filter(Referral.inviter_id == user.id).all()
    return {"count": len(refs), "referrals": [{"invitee_id": r.invitee_id, "bonus_given": r.bonus_given} for r in refs]}

