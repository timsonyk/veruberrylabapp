from typing import Optional
import logging

from sqlalchemy.orm import Session
from cloudpayments import CloudPayments

from app.core.config import get_settings
from app.models.order import Payment, PaymentProvider, PaymentStatus

logger = logging.getLogger(__name__)


def create_payment(db: Session, order_id: int, amount: float, user_id: int, card_token: Optional[str] = None) -> Payment:
    """
    Create CloudPayments payment and generate payment link.
    """
    settings = get_settings()

    # Проверяем включен ли CloudPayments
    if not settings.cloudpayments_enabled:
        logger.warning("CloudPayments is disabled, using stub payment")
        payment = Payment(
            order_id=order_id,
            amount=amount,
            status=PaymentStatus.PENDING,
            provider=PaymentProvider.CLOUDPAYMENTS,
            redirect_url=f"https://sandbox.example/pay/{order_id}",
            payment_token=f"stub_order_{order_id}",
        )
        db.add(payment)
        db.commit()
        db.refresh(payment)
        return payment

    # Создаём клиент CloudPayments
    try:
        cp = CloudPayments(settings.cloudpayments_public_id, settings.cloudpayments_api_key)

        invoice_id = f"order_{order_id}"
        description = f"Заказ №{order_id} VeryBerryLab"

        # Генерируем ссылку на оплату через виджет CloudPayments
        # Используем charge для одностадийного платежа
        redirect_url = (
            f"https://widget.cloudpayments.ru/terminal/charge?"
            f"publicId={settings.cloudpayments_public_id}&"
            f"description={description}&"
            f"amount={amount}&"
            f"currency=RUB&"
            f"invoiceId={invoice_id}&"
            f"accountId={user_id}"
        )

        payment = Payment(
            order_id=order_id,
            amount=amount,
            status=PaymentStatus.PENDING,
            provider=PaymentProvider.CLOUDPAYMENTS,
            redirect_url=redirect_url,
            payment_token=invoice_id,
        )
        db.add(payment)
        db.commit()
        db.refresh(payment)
        return payment

    except Exception as e:
        logger.error(f"CloudPayments error: {e}")
        # Fallback to stub if CloudPayments fails
        payment = Payment(
            order_id=order_id,
            amount=amount,
            status=PaymentStatus.PENDING,
            provider=PaymentProvider.CLOUDPAYMENTS,
            redirect_url=f"https://sandbox.example/pay/{order_id}",
            payment_token=f"error_order_{order_id}",
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

