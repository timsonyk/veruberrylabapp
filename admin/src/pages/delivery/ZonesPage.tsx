import { Button, Form, Input, InputNumber, Modal, Space, Switch, Table } from 'antd'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { api } from '../../lib/api'

const fetchZones = async () => (await api.get('/admin/delivery_zones')).data

export const ZonesPage = () => {
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['zones'], queryFn: fetchZones })
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<any>(null)
  const [form] = Form.useForm()

  const save = useMutation({
    mutationFn: async (values: any) => {
      if (editing) return api.put(`/admin/delivery_zones/${editing.id}`, values)
      return api.post('/admin/delivery_zones', values)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['zones'] })
      setOpen(false)
      setEditing(null)
      form.resetFields()
    },
  })

  const remove = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/delivery_zones/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['zones'] }),
  })

  const columns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'City', dataIndex: 'city' },
    { title: 'Lat', dataIndex: 'center_lat' },
    { title: 'Lng', dataIndex: 'center_lng' },
    { title: 'Radius m', dataIndex: 'radius_meters' },
    { title: 'Fee', dataIndex: 'delivery_fee' },
    { title: 'SLA', dataIndex: 'sla_minutes' },
    { title: 'Sort', dataIndex: 'sort_order' },
    { title: 'Active', dataIndex: 'is_active', render: (v: boolean) => (v ? 'Yes' : 'No') },
    {
      title: 'Actions',
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            onClick={() => {
              setEditing(record)
              form.setFieldsValue(record)
              setOpen(true)
            }}
          >
            Edit
          </Button>
          <Button danger size="small" onClick={() => remove.mutate(record.id)}>
            Delete
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <>
      <Space style={{ marginBottom: 12 }}>
        <Button type="primary" onClick={() => setOpen(true)}>
          New zone
        </Button>
      </Space>
      <Table loading={isLoading} dataSource={data || []} columns={columns} rowKey="id" />

      <Modal
        open={open}
        title={editing ? 'Edit zone' : 'New zone'}
        onCancel={() => {
          setOpen(false)
          setEditing(null)
        }}
        onOk={() => form.submit()}
        confirmLoading={save.isPending}
      >
        <Form
          layout="vertical"
          form={form}
          initialValues={{ is_active: true, sort_order: 0, sla_minutes: 180 }}
          onFinish={(values) => save.mutate(values)}
        >
          <Form.Item name="city" label="City" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="center_lat" label="Latitude" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="center_lng" label="Longitude" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="radius_meters" label="Radius (m)" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="delivery_fee" label="Delivery fee" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="sla_minutes" label="SLA minutes">
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="min_order_total" label="Min order total">
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="sort_order" label="Sort order">
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="is_active" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </>
  )
}


