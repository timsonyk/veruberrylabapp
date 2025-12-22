import { Button, DatePicker, Form, Input, InputNumber, Modal, Select, Space, Switch, Table } from 'antd'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import dayjs from 'dayjs'
import { api } from '../../lib/api'

const fetchPromo = async () => (await api.get('/admin/promo_codes')).data

export const PromoCodesPage = () => {
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['promo_codes'], queryFn: fetchPromo })
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<any>(null)
  const [form] = Form.useForm()

  const save = useMutation({
    mutationFn: async (values: any) => {
      const payload = {
        ...values,
        starts_at: values.starts_at ? values.starts_at.toISOString() : null,
        ends_at: values.ends_at ? values.ends_at.toISOString() : null,
      }
      if (editing) return api.put(`/admin/promo_codes/${editing.id}`, payload)
      return api.post('/admin/promo_codes', payload)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['promo_codes'] })
      setOpen(false)
      setEditing(null)
      form.resetFields()
    },
  })

  const remove = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/promo_codes/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['promo_codes'] }),
  })

  const columns = [
    { title: 'Code', dataIndex: 'code' },
    { title: 'Type', dataIndex: 'discount_type' },
    { title: 'Value', dataIndex: 'discount_value' },
    { title: 'Active', dataIndex: 'is_active', render: (v: boolean) => (v ? 'Yes' : 'No') },
    {
      title: 'Actions',
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            onClick={() => {
              setEditing(record)
              form.setFieldsValue({
                ...record,
                starts_at: record.starts_at ? dayjs(record.starts_at) : null,
                ends_at: record.ends_at ? dayjs(record.ends_at) : null,
              })
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
          New promo
        </Button>
      </Space>
      <Table loading={isLoading} dataSource={data || []} columns={columns} rowKey="id" />

      <Modal
        open={open}
        title={editing ? 'Edit promo' : 'New promo'}
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
          initialValues={{ is_active: true, discount_type: 'percent' }}
          onFinish={(values) => save.mutate(values)}
        >
          <Form.Item name="code" label="Code" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="discount_type" label="Type" rules={[{ required: true }]}>
            <Select
              options={[
                { value: 'percent', label: 'Percent' },
                { value: 'fixed', label: 'Fixed' },
              ]}
            />
          </Form.Item>
          <Form.Item name="discount_value" label="Value" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="min_order_total" label="Min order total">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="usage_limit" label="Usage limit">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="starts_at" label="Starts at">
            <DatePicker style={{ width: '100%' }} showTime />
          </Form.Item>
          <Form.Item name="ends_at" label="Ends at">
            <DatePicker style={{ width: '100%' }} showTime />
          </Form.Item>
          <Form.Item name="is_active" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </>
  )
}


