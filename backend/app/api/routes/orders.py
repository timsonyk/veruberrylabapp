from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import logging
import hmac
import hashlib
import base64

from app.api.deps import get_current_user, get_db
from app.models.order import DeliveryType, Order, OrderItem, OrderStatus, PaymentStatus
from app.schemas.order import (
    OrderCreate,
    OrderOut,
    PaymentInitResponse,
    PriceRequest,
    PriceResponse,
)
from app.services.pricing import calculate_totals
from app.services import payments as payments_service
from app.services import loyalty as loyalty_service
from app.services.telegram_notifications import send_new_order_notification_sync
from app.core.config import get_settings

router = APIRouter(prefix="/orders", tags=["orders"])
logger = logging.getLogger(__name__)


@router.post("/price", response_model=PriceResponse)
def calculate_price(payload: PriceRequest, db: Session = Depends(get_db)):
    totals = calculate_totals(
        db,
        items_payload=[item.model_dump() for item in payload.items],
        promo_code=payload.promo_code,
        lat=payload.lat,
        lng=payload.lng,
        city=payload.city,
        delivery_type=payload.delivery_type,
    )
    return PriceResponse(
        subtotal=totals["subtotal"],
        discount=totals["discount"],
        delivery_fee=totals["delivery_fee"],
        total=totals["total"],
        loyalty_earned=totals["loyalty_earned"],
    )


@router.post("", response_model=OrderOut)
def create_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    totals = calculate_totals(
        db,
        items_payload=[item.model_dump() for item in payload.items],
        promo_code=payload.promo_code,
        lat=payload.lat,
        lng=payload.lng,
        city=payload.city,
        delivery_type=payload.delivery_type,
    )

    order = Order(
        user_id=user.id,
        status=OrderStatus.PENDING_PAYMENT,
        delivery_type=DeliveryType(payload.delivery_type),
        address_text=payload.address_text,
        lat=payload.lat,
        lng=payload.lng,
        city=payload.city,
        pickup_location_id=payload.pickup_location_id,
        delivery_zone_id=totals["delivery_zone_id"],
        comment=payload.comment,
        no_call=payload.no_call,
        promo_code_id=totals["promo_code_id"],
        subtotal=totals["subtotal"],
        delivery_fee=totals["delivery_fee"],
        discount=totals["discount"],
        total=totals["total"],
        loyalty_earned=totals["loyalty_earned"],
    )
    db.add(order)
    db.flush()

    for item in totals["items"]:
        db.add(
            OrderItem(
                order_id=order.id,
                product_id=item["product_id"],
                size_id=item.get("size_id"),
                quantity=item["quantity"],
                base_price=item["base_price"],
                final_price=item["final_price"],
                modifications_json=item["modifications_json"],
            )
        )
    db.commit()
    db.refresh(order)

    # Отправляем уведомление в Telegram
    try:
        send_new_order_notification_sync(order, user)
    except Exception as e:
        logger.error(f"Failed to send Telegram notification for order {order.id}: {e}")
        # Не падаем если не удалось отправить уведомление

    return order


@router.get("", response_model=list[OrderOut])
def list_orders(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(Order).filter(Order.user_id == user.id).order_by(Order.created_at.desc()).all()


@router.get("/{order_id}", response_model=OrderOut)
def get_order(order_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@router.post("/{order_id}/pay", response_model=PaymentInitResponse)
def pay_order(order_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status not in {OrderStatus.PENDING_PAYMENT, OrderStatus.NEW}:
        raise HTTPException(status_code=400, detail="Order not payable")

    payment = payments_service.create_payment(db, order_id=order.id, amount=float(order.total), user_id=user.id)
    return PaymentInitResponse(payment_id=payment.id, status=payment.status.value, redirect_url=payment.redirect_url)


@router.post("/{order_id}/mark_paid", response_model=OrderOut)
def mark_paid(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Only award cashback if this is the first time marking as paid
    should_award_cashback = order.status != OrderStatus.PAID
    
    order.status = OrderStatus.PAID
    if order.payment:
        order.payment.status = PaymentStatus.PAID
    db.commit()
    
    # Award cashback points
    if should_award_cashback:
        try:
            points_awarded = loyalty_service.award_cashback_for_order(db, order)
            print(f"Awarded {points_awarded} cashback points for order {order_id}")
        except Exception as e:
            print(f"Failed to award cashback for order {order_id}: {e}")
            # Don't fail the request if cashback award fails

    db.refresh(order)
    return order


@router.post("/cloudpayments/webhook")
async def cloudpayments_webhook(request: Request, db: Session = Depends(get_db)):
    """
    CloudPayments webhook for payment notifications.
    Handles: pay (successful payment), fail (failed payment), refund, etc.
    """
    try:
        # Получаем тело запроса
        body = await request.body()
        data = await request.json()

        logger.info(f"CloudPayments webhook received: {data.get('TransactionId', 'unknown')}")

        # Проверяем HMAC подпись (опционально, но рекомендуется)
        settings = get_settings()
        if settings.cloudpayments_api_key:
            # CloudPayments отправляет HMAC в заголовке Content-HMAC
            content_hmac = request.headers.get("Content-HMAC", "")
            if content_hmac:
                # Вычисляем HMAC
                expected_hmac = base64.b64encode(
                    hmac.new(
                        settings.cloudpayments_api_key.encode('utf-8'),
                        body,
                        hashlib.sha256
                    ).digest()
                ).decode('utf-8')

                if content_hmac != expected_hmac:
                    logger.warning("CloudPayments HMAC verification failed")
                    return {"code": 13, "message": "Invalid HMAC"}

        # Извлекаем данные
        invoice_id = data.get("InvoiceId", "")  # "order_123"
        transaction_id = data.get("TransactionId")
        status = data.get("Status")  # "Completed", "Declined", "Refunded"
        amount = data.get("Amount")

        # Парсим order_id из InvoiceId
        if not invoice_id.startswith("order_"):
            logger.error(f"Invalid InvoiceId format: {invoice_id}")
            return {"code": 0}  # Возвращаем успех чтобы CloudPayments не повторял запросы

        try:
            order_id = int(invoice_id.split("_")[1])
        except (IndexError, ValueError):
            logger.error(f"Failed to parse order_id from InvoiceId: {invoice_id}")
            return {"code": 0}

        # Находим заказ
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            logger.error(f"Order not found: {order_id}")
            return {"code": 0}

        # Обрабатываем успешную оплату
        if status == "Completed":
            # Проверяем что заказ еще не оплачен (избегаем дублей)
            should_award_cashback = order.status != OrderStatus.PAID

            order.status = OrderStatus.PAID
            if order.payment:
                order.payment.status = PaymentStatus.PAID
                # Сохраняем transaction_id в extra поле
                if transaction_id:
                    order.payment.extra = {"transaction_id": transaction_id}

            db.commit()

            # Начисляем бонусы
            if should_award_cashback:
                try:
                    points_awarded = loyalty_service.award_cashback_for_order(db, order)
                    logger.info(f"Awarded {points_awarded} cashback points for order {order_id}")
                except Exception as e:
                    logger.error(f"Failed to award cashback for order {order_id}: {e}")

            logger.info(f"Order {order_id} marked as PAID via CloudPayments webhook")

        # Обрабатываем неудачную оплату
        elif status == "Declined":
            if order.payment:
                order.payment.status = PaymentStatus.FAILED
            db.commit()
            logger.info(f"Order {order_id} payment declined")

        # Обрабатываем возврат
        elif status == "Refunded":
            if order.payment:
                order.payment.status = PaymentStatus.CANCELLED
            order.status = OrderStatus.CANCELLED
            db.commit()
            logger.info(f"Order {order_id} refunded")

        # CloudPayments требует {"code": 0} для успеха
        return {"code": 0}

    except Exception as e:
        logger.error(f"CloudPayments webhook error: {e}")
        # Возвращаем успех чтобы не ломать поток платежей
        return {"code": 0}

