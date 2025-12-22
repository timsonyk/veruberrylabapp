import { Button, Select, Space, Table, Tag } from 'antd'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../../lib/api'

const fetchOrders = async (status?: string) => {
  const res = await api.get('/admin/orders', { params: status ? { status } : {} })
  return res.data
}

const statuses = ['new', 'pending_payment', 'paid', 'in_progress', 'delivered', 'cancelled']

export const OrdersPage = () => {
  const qc = useQueryClient()
  const [status, setStatus] = useState<string | undefined>(undefined)
  const { data, isLoading } = useQuery({ queryKey: ['orders', status], queryFn: () => fetchOrders(status) })

  const updateStatus = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) =>
      api.post(`/admin/orders/${id}/status`, null, { params: { status } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['orders'] }),
  })

  const columns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'User', dataIndex: 'user_id' },
    { title: 'Total', dataIndex: 'total' },
    { title: 'Delivery', dataIndex: 'delivery_type' },
    { title: 'Created', dataIndex: 'created_at' },
    { title: 'Status', dataIndex: 'status', render: (v: string) => <Tag>{v}</Tag> },
    {
      title: 'Actions',
      render: (_: any, record: any) => (
        <Space>
          <Link to={`/orders/${record.id}`}>Open</Link>
          {['paid', 'in_progress', 'delivered'].map((next) => (
            <Button
              key={next}
              size="small"
              onClick={() => updateStatus.mutate({ id: record.id, status: next })}
            >
              {next}
            </Button>
          ))}
        </Space>
      ),
    },
  ]

  return (
    <>
      <Space style={{ marginBottom: 12 }}>
        <Select
          placeholder="Filter status"
          allowClear
          value={status}
          onChange={setStatus}
          style={{ width: 200 }}
          options={statuses.map((s) => ({ value: s, label: s }))}
        />
      </Space>
      <Table loading={isLoading} dataSource={data || []} columns={columns} rowKey="id" />
    </>
  )
}


