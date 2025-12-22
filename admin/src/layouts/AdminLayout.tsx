import { Layout, Menu, Typography } from 'antd'
import {
  AppstoreOutlined,
  ShopOutlined,
  GiftOutlined,
  ShoppingCartOutlined,
  SettingOutlined,
  DeploymentUnitOutlined,
} from '@ant-design/icons'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useLogout } from '../hooks/useAuth'

const { Header, Sider, Content } = Layout

const menuItems = [
  { key: '/', icon: <AppstoreOutlined />, label: <Link to="/">Главная</Link> },
  {
    key: '/catalog',
    icon: <ShopOutlined />,
    label: 'Каталог',
    children: [
      { key: '/catalog/categories', label: <Link to="/catalog/categories">Категории</Link> },
      { key: '/catalog/products', label: <Link to="/catalog/products">Товары</Link> },
      { key: '/catalog/modifications', label: <Link to="/catalog/modifications">Модификации</Link> },
    ],
  },
  {
    key: '/orders',
    icon: <ShoppingCartOutlined />,
    label: <Link to="/orders">Заказы</Link>,
  },
  {
    key: '/marketing',
    icon: <GiftOutlined />,
    label: 'Маркетинг',
    children: [
      { key: '/marketing/banners', label: <Link to="/marketing/banners">Баннеры</Link> },
      { key: '/marketing/promo-codes', label: <Link to="/marketing/promo-codes">Промокоды</Link> },
    ],
  },
  {
    key: '/delivery',
    icon: <DeploymentUnitOutlined />,
    label: 'Доставка',
    children: [
      { key: '/delivery/pickups', label: <Link to="/delivery/pickups">Самовывоз</Link> },
      { key: '/delivery/zones', label: <Link to="/delivery/zones">Зоны</Link> },
    ],
  },
  {
    key: '/settings',
    icon: <SettingOutlined />,
    label: 'Настройки',
    children: [
      { key: '/settings/texts', label: <Link to="/settings/texts">Тексты</Link> },
      { key: '/settings/loyalty', label: <Link to="/settings/loyalty">Лояльность</Link> },
    ],
  },
]

export const AdminLayout = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const logout = useLogout()

  const onLogout = async () => {
    await logout.mutateAsync()
    navigate('/login')
  }

  const selectedKeys = [location.pathname.startsWith('/catalog') ? '/catalog' : location.pathname]

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider theme="light">
        <div style={{ padding: 16 }}>
          <Typography.Title level={4} style={{ margin: 0 }}>
            VeryBerryLab
          </Typography.Title>
        </div>
        <Menu mode="inline" selectedKeys={selectedKeys} items={menuItems} />
      </Sider>
      <Layout>
        <Header
          style={{
            background: '#fff',
            padding: '0 16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <Typography.Text>Админка</Typography.Text>
          <Typography.Link onClick={onLogout}>Выйти</Typography.Link>
        </Header>
        <Content style={{ padding: 16 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}

