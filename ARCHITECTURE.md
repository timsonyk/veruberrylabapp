# VeryBerryLab - Архитектура проекта

## Обзор

E-commerce приложение для заказа букетов из ягод в шоколаде. Состоит из трёх компонентов:
- **Backend** — FastAPI + PostgreSQL
- **Admin** — React + Ant Design
- **iOS App** — SwiftUI

---

## Структура проекта

```
veryberrylab/
├── backend/              # FastAPI REST API
├── admin/                # React админ-панель
├── veryberrylab/         # SwiftUI iOS приложение
├── Pods/                 # iOS зависимости (CocoaPods)
├── CLAUDE.md             # Инструкции для Claude
└── ARCHITECTURE.md       # Этот файл
```

---

## Backend (FastAPI)

**Путь:** `/backend/`

### Запуск
```bash
cd backend
docker compose up
```

### Структура

```
backend/
├── app/
│   ├── main.py                 # Точка входа FastAPI
│   ├── core/
│   │   └── config.py           # Настройки (Pydantic Settings)
│   ├── db/
│   │   └── session.py          # SQLAlchemy сессии
│   ├── models/                 # ORM модели
│   │   ├── user.py             # User, AuthCode, Address
│   │   ├── catalog.py          # Product, Category, ModificationGroup, DeliveryZone...
│   │   ├── order.py            # Order, OrderItem, Payment
│   │   └── loyalty.py          # LoyaltyAccount, LoyaltyTransaction, Referral
│   ├── schemas/                # Pydantic схемы
│   │   ├── auth.py
│   │   ├── catalog.py
│   │   ├── order.py
│   │   ├── user.py
│   │   └── admin.py
│   ├── api/
│   │   ├── router.py           # Главный роутер
│   │   ├── deps.py             # Зависимости (get_db, get_current_user)
│   │   ├── admin_deps.py       # Админ авторизация
│   │   └── routes/
│   │       ├── auth.py         # SMS авторизация, Telegram Login
│   │       ├── catalog.py      # Каталог, категории, продукты
│   │       ├── orders.py       # Заказы, оплата
│   │       ├── profile.py      # Профиль пользователя
│   │       ├── admin.py        # Админ CRUD операции
│   │       └── promo.py        # Промокоды
│   └── services/
│       ├── pricing.py          # Расчёт стоимости заказа
│       ├── loyalty.py          # Логика кэшбека и бонусов
│       └── payments.py         # Интеграция платёжной системы (TODO: VTB Business)
├── migrations/                 # Alembic миграции
├── docker-compose.yml
└── requirements.txt
```

### Ключевые эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/auth/request_code` | Запрос SMS-кода |
| POST | `/auth/verify` | Верификация и получение JWT |
| GET | `/catalog/categories` | Список категорий |
| GET | `/catalog/products` | Список продуктов |
| POST | `/catalog/delivery-check` | Проверка доставки по координатам |
| POST | `/orders` | Создание заказа |
| POST | `/orders/{id}/pay` | Инициация оплаты |
| GET | `/me` | Текущий пользователь |
| GET | `/me/loyalty` | Бонусный счёт |

### Модели данных

**User** — пользователь с телефоном, email, городом, статистикой заказов

**Product** — товар с ценой, размерами, модификациями

**Order** — заказ со статусами: `new → pending_payment → paid → in_progress → delivered`

**DeliveryZone** — зона доставки с полигоном (GeoJSON), стоимостью, минимальным заказом

**LoyaltyAccount** — бонусный счёт (5% кэшбек по умолчанию)

---

## Admin Panel (React)

**Путь:** `/admin/`

### Запуск
```bash
cd admin
npm install
npm run dev
```

### Технологии
- React 19 + TypeScript
- Vite
- Ant Design 6
- TanStack React Query
- React Router DOM 7

### Структура

```
admin/src/
├── main.tsx                    # Точка входа
├── router.tsx                  # Роутинг
├── layouts/
│   └── AdminLayout.tsx         # Основной layout с сайдбаром
├── pages/
│   ├── Login.tsx
│   ├── Dashboard.tsx
│   ├── catalog/                # Категории, продукты, модификации
│   ├── orders/                 # Заказы
│   ├── marketing/              # Баннеры, промокоды
│   ├── delivery/               # Точки самовывоза, зоны доставки
│   ├── settings/               # Тексты, лояльность, локации магазинов
│   └── customers/              # Клиенты
├── hooks/
│   └── useAuth.ts
├── components/
│   └── Protected.tsx
└── lib/
    └── api.ts                  # Axios клиент
```

### Маршруты

- `/login` — авторизация
- `/` — дашборд
- `/catalog/categories` — категории
- `/catalog/products` — продукты
- `/orders` — заказы
- `/marketing/banners` — баннеры
- `/delivery/zones` — зоны доставки
- `/settings/loyalty` — настройки лояльности

---

## iOS App (SwiftUI)

**Путь:** `/veryberrylab/`

### Запуск
Открыть в Xcode → Run

### Зависимости (CocoaPods)
- YandexMapsMobile — Яндекс.Карты

### Структура

```
veryberrylab/
├── veryberrylabApp.swift       # Точка входа
├── ContentView.swift
├── AppState.swift              # Главный State Manager
├── Shared/
│   └── Config.swift            # API URL, ключи
├── Models/
│   ├── NetworkModels.swift     # DTO для API
│   ├── DeliveryModels.swift    # Модели доставки
│   └── CartModels.swift        # Модели корзины
├── Services/
│   ├── APIClient.swift         # HTTP клиент
│   ├── AuthService.swift       # Авторизация
│   └── CatalogService.swift    # Каталог и доставка
├── ViewModels/
│   ├── CartViewModel.swift     # Логика корзины
│   ├── CatalogViewModel.swift
│   └── ProductDetailViewModel.swift
└── Views/
    ├── MainTabView.swift       # Таб-навигация
    ├── CatalogView.swift       # Каталог
    ├── ProductDetailView.swift # Детали продукта
    ├── CartView.swift          # Корзина
    ├── LoginView.swift         # Авторизация
    ├── ProfileView.swift       # Профиль
    ├── AddressSelectionView.swift
    ├── SplashView.swift
    ├── MenuView.swift
    ├── FAQView.swift
    └── StoreLocationsView.swift
```

### AppState — главные данные

```swift
// Авторизация
token: String?
user: UserDTO?
isLoggedIn: Bool

// Доставка
deliveryType: DeliveryType  // .delivery / .pickup
selectedAddress: DeliveryAddress?
selectedPickupPoint: PickupPoint?
deliveryFee: Double
isDeliveryAvailable: Bool

// Бонусы
bonusBalance: Int
loyaltyInfo: LoyaltyInfoDTO?
```

---

## Бизнес-логика

### Авторизация
1. Пользователь вводит телефон → `POST /auth/request_code`
2. Получает SMS-код (сейчас возвращается в ответе — заглушка)
3. Вводит код → `POST /auth/verify` → JWT токен
4. Альтернатива: Telegram Login Widget

### Расчёт заказа (pricing.py)
1. Базовая цена товаров + модификации
2. Применение промокода (% или фиксированная сумма)
3. Расчёт доставки по зоне (point-in-polygon)
4. Начисление бонусов (5% от subtotal)

### Система доставки
1. Зоны доставки задаются полигонами (GeoJSON)
2. При выборе адреса — проверка попадания в зону
3. Каждая зона имеет свою стоимость и время доставки
4. Минимальная сумма заказа для зоны

### Программа лояльности
- 5% кэшбек с каждого заказа
- Бонусы можно тратить на следующие заказы
- Реферальная система с начислением бонусов

---

## Переменные окружения

### Backend (.env)
```env
DATABASE_URL=postgresql://user:pass@localhost/db
SECRET_KEY=CHANGE_ME
ADMIN_USERNAME=admin
ADMIN_PASSWORD=CHANGE_ME
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
```

### Admin (.env)
```env
VITE_API_URL=http://localhost:8000
```

### iOS (Config.swift)
```swift
static let apiBaseURL = "https://your-api.ngrok-free.dev"
// Yandex Maps API Key в Info.plist
```
