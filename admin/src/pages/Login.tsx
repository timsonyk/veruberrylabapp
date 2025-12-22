import { Card, Form, Input, Button, Typography, message } from 'antd'
import { useLogin, useSession } from '../hooks/useAuth'
import { useEffect } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'

export const LoginPage = () => {
  const login = useLogin()
  const { data } = useSession()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as any)?.from?.pathname || '/'

  useEffect(() => {
    if (data?.authenticated) {
      navigate(from, { replace: true })
    }
  }, [data, from, navigate])

  const onFinish = async (values: any) => {
    try {
      await login.mutateAsync(values)
      message.success('Logged in')
      navigate(from, { replace: true })
    } catch (e: any) {
      message.error(e?.response?.data?.detail || 'Login failed')
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Card title="Admin Login" style={{ width: 360 }}>
        <Form layout="vertical" onFinish={onFinish}>
          <Form.Item name="username" label="Username" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="password" label="Password" rules={[{ required: true }]}>
            <Input.Password />
          </Form.Item>
          <Button type="primary" htmlType="submit" block loading={login.isPending}>
            Login
          </Button>
        </Form>
      </Card>
    </div>
  )
}


