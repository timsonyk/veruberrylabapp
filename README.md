# VeryBerryLab Monorepo

Экосистема: FastAPI backend + React admin + SwiftUI iOS.

## Структура
- `backend/` — FastAPI, PostgreSQL, Alembic.
- `admin/` — React/TypeScript (scaffold далее).
- `veryberrylab/` + `veryberrylab.xcodeproj/` — iOS-приложение (будет вынесено в `ios/` при доработке).

## Быстрый старт (backend)
1. Перейти в каталог `backend/`.
2. Создать `.env` на базе `env.example` (временно без точки, т.к. секреты не коммитим). Обновить пароли/ключи.
3. Поднять Postgres и API:
   ```bash
   cd backend
   docker-compose up -d db
   ```
4. Применить миграции:
   ```bash
   alembic upgrade head
   ```
5. Запуск API локально:
   ```bash
   uvicorn app.main:app --reload
   ```
   или через docker-compose (поднимет бэкенд на `:8000`):
   ```bash
   docker-compose up --build
   ```

## Backend: основное
- FastAPI, SQLAlchemy 2.0, Alembic, JWT.
- Модели: пользователи, лояльность, рефералы, каталог (категории, продукты, размеры, модификации, баннеры, промокоды), доставка (pickup, delivery zones), заказы, платежи (stub CloudPayments).
- Маршруты (через `/api` не префиксованы — сразу):
  - `POST /auth/request_code`, `POST /auth/verify`
  - `GET /catalog/categories|products|products/{id}|banners`
  - `POST /promo/validate`
  - `POST /orders/price`, `POST /orders`, `GET /orders`, `GET /orders/{id}`, `POST /orders/{id}/pay`, `POST /orders/{id}/mark_paid`
  - `GET/PATCH /me`, `GET/POST/DELETE /me/addresses`, `GET /me/loyalty`, `GET /me/cards`, `GET /me/referrals`

## Админка
- План: Vite + React + TypeScript + MUI/Ant, авторизация по cookie, REST к FastAPI. (Scaffold в следующих шагах.)

## iOS
- SwiftUI, iOS 17, MVVM. Сейчас базовый проект (`veryberrylab.xcodeproj`). Добавим модули Catalog/Cart/Profile/Menu и сетевой слой в дальнейших шагах.

## Требования
- Docker, Python 3.11+, Node 18+, Xcode 15+.
- Переменные окружения (см. `backend/env.example`): Postgres, JWT секреты, CloudPayments (stub).

