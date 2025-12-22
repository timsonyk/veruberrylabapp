from typing import Optional

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.order import Payment, PaymentProvider, PaymentStatus


def create_payment(db: Session, order_id: int, amount: float, user_id: int, card_token: Optional[str] = None) -> Payment:
    """
    Stub implementation that mimics CloudPayments. Generates a fake redirect URL.
    """
    payment = Payment(
        order_id=order_id,
        amount=amount,
        status=PaymentStatus.PENDING,
        provider=PaymentProvider.CLOUDPAYMENTS,
        redirect_url=f"https://sandbox.example/pay/{order_id}",
        payment_token=card_token,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return payment


def update_payment_status(db: Session, payment_id: int, status: PaymentStatus) -> Payment:
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise ValueError("Payment not found")
    payment.status = status
    db.commit()
    db.refresh(payment)
    return payment

