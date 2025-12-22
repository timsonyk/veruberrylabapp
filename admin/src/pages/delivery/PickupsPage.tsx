import { Button, Form, Input, InputNumber, Modal, Space, Switch, Table } from 'antd'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { api } from '../../lib/api'

const fetchPickups = async () => (await api.get('/admin/pickup_locations')).data

export const PickupsPage = () => {
  const qc = useQueryClient()
  const { data, isLoading } = useQuery({ queryKey: ['pickups'], queryFn: fetchPickups })
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<any>(null)
  const [form] = Form.useForm()

  const save = useMutation({
    mutationFn: async (values: any) => {
      if (editing) return api.put(`/admin/pickup_locations/${editing.id}`, values)
      return api.post('/admin/pickup_locations', values)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pickups'] })
      setOpen(false)
      setEditing(null)
      form.resetFields()
    },
  })

  const remove = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/pickup_locations/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pickups'] }),
  })

  const columns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'Город', dataIndex: 'city' },
    { title: 'Адрес', dataIndex: 'address' },
    { title: 'График', dataIndex: 'schedule_text' },
    { title: 'Сортировка', dataIndex: 'sort_order' },
    { title: 'Активна', dataIndex: 'is_active', render: (v: boolean) => (v ? 'Да' : 'Нет') },
    {
      title: 'Действия',
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
            Редактировать
          </Button>
          <Button danger size="small" onClick={() => remove.mutate(record.id)}>
            Удалить
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <>
      <Space style={{ marginBottom: 12 }}>
        <Button type="primary" onClick={() => setOpen(true)}>
          Новая точка самовывоза
        </Button>
      </Space>
      <Table loading={isLoading} dataSource={data || []} columns={columns} rowKey="id" />

      <Modal
        open={open}
        title={editing ? 'Редактировать точку самовывоза' : 'Новая точка самовывоза'}
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
          initialValues={{ is_active: true, sort_order: 0 }}
          onFinish={(values) => save.mutate(values)}
        >
          <Form.Item name="city" label="Город" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="address" label="Адрес" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="schedule_text" label="График">
            <Input />
          </Form.Item>
          <Form.Item name="sort_order" label="Порядок сортировки">
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="is_active" label="Активна" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </>
  )
}


