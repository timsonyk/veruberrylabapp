import { createBrowserRouter, Navigate } from 'react-router-dom'
import { AdminLayout } from './layouts/AdminLayout'
import { LoginPage } from './pages/Login'
import { DashboardPage } from './pages/Dashboard'
import { CategoriesPage } from './pages/catalog/CategoriesPage'
import { ProductsPage } from './pages/catalog/ProductsPage'
import { ModificationsPage } from './pages/catalog/ModificationsPage'
import { CustomersPage } from './pages/customers/CustomersPage'
import { OrdersPage } from './pages/orders/OrdersPage'
import { OrderDetailPage } from './pages/orders/OrderDetailPage'
import { BannersPage } from './pages/marketing/BannersPage'
import { PromoCodesPage } from './pages/marketing/PromoCodesPage'
import { NotificationsPage } from './pages/notifications/NotificationsPage'
import { PickupsPage } from './pages/delivery/PickupsPage'
import { ZonesPage } from './pages/delivery/ZonesPage'
import { TextsPage } from './pages/settings/TextsPage'
import { LoyaltyPage } from './pages/settings/LoyaltyPage'
import { StoreLocationsPage } from './pages/settings/StoreLocationsPage'
import { Protected } from './components/Protected'

export const router = createBrowserRouter([
  { path: '/login', element: <LoginPage /> },
  {
    path: '/',
    element: (
      <Protected>
        <AdminLayout />
      </Protected>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'catalog/categories', element: <CategoriesPage /> },
      { path: 'catalog/products', element: <ProductsPage /> },
      { path: 'catalog/modifications', element: <ModificationsPage /> },
      { path: 'customers', element: <CustomersPage /> },
      { path: 'orders', element: <OrdersPage /> },
      { path: 'orders/:id', element: <OrderDetailPage /> },
      { path: 'marketing/banners', element: <BannersPage /> },
      { path: 'marketing/promo-codes', element: <PromoCodesPage /> },
      { path: 'marketing/notifications', element: <NotificationsPage /> },
      { path: 'delivery/pickups', element: <PickupsPage /> },
      { path: 'delivery/zones', element: <ZonesPage /> },
      { path: 'settings/texts', element: <TextsPage /> },
      { path: 'settings/loyalty', element: <LoyaltyPage /> },
      { path: 'settings/store-locations', element: <StoreLocationsPage /> },
      { path: '*', element: <Navigate to="/" replace /> },
    ],
  },
  { path: '*', element: <Navigate to="/" replace /> },
])

