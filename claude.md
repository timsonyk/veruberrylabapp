# VeryBerryLab — Claude Memory

## Goal
Mobile app + admin panel for ordering chocolate-covered berry bouquets.

## Architecture
- Backend: FastAPI + PostgreSQL
- Admin: React (Vite)
- iOS: SwiftUI (iOS 17+, uses YandexMapsMobile)
- Auth: Telegram Bot (initTelegramAuth → checkTelegramAuth polling)
- Payments: TODO (VTB Business)

## Key iOS Files
- `AppState.swift` — global state (auth, addresses, delivery, bonus)
- `AuthService.swift` — Telegram bot auth flow
- `CatalogService.swift` — products, categories, delivery check
- `AddressSelectionView.swift` — delivery/pickup address selection with Yandex Maps

## Commands
- Backend: `cd backend && docker-compose build backend && docker-compose up -d backend`
- iOS: Xcode → Run

## Notes
- DeliveryAddress coordinates are optional (latitude/longitude)
- Yandex Maps: use `addPlacemark()` + `geometry = point` (not deprecated `addPlacemark(with:)`)
- iOS 17+: use `onChange(of:) { oldValue, newValue in }` syntax