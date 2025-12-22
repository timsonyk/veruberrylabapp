import { Button, Form, Input, InputNumber, Modal, Select, Space, Switch, Table, Tag } from 'antd'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { api } from '../../lib/api'

const fetchGroups = async (product_id?: number) =>
  (await api.get('/admin/modification_groups', { params: product_id ? { product_id } : {} })).data
const fetchOptions = async (group_id?: number) =>
  (await api.get('/admin/modification_options', { params: group_id ? { group_id } : {} })).data
const fetchProducts = async () => (await api.get('/admin/products')).data

export const ModificationsPage = () => {
  const qc = useQueryClient()
  const { data: products } = useQuery({ queryKey: ['products'], queryFn: fetchProducts })
  const [productFilter, setProductFilter] = useState<number | undefined>(undefined)
  const { data: groups, isLoading } = useQuery({
    queryKey: ['mod_groups', productFilter],
    queryFn: () => fetchGroups(productFilter),
  })
  const [openGroup, setOpenGroup] = useState(false)
  const [editingGroup, setEditingGroup] = useState<any>(null)
  const [groupForm] = Form.useForm()

  const [openOption, setOpenOption] = useState(false)
  const [editingOption, setEditingOption] = useState<any>(null)
  const [optionForm] = Form.useForm()
  const [currentGroupId, setCurrentGroupId] = useState<number | null>(null)
  const optionsQuery = useQuery({
    queryKey: ['mod_options', currentGroupId],
    queryFn: () => fetchOptions(currentGroupId || undefined),
    enabled: !!currentGroupId,
  })

  const saveGroup = useMutation({
    mutationFn: async (values: any) => {
      if (editingGroup) return api.put(`/admin/modification_groups/${editingGroup.id}`, values)
      return api.post('/admin/modification_groups', values)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['mod_groups'] })
      setOpenGroup(false)
      setEditingGroup(null)
      groupForm.resetFields()
    },
  })

  const saveOption = useMutation({
    mutationFn: async (values: any) => {
      if (editingOption) {
        const { id, ...rest } = values
        return api.put(`/admin/modification_options/${id}`, rest)
      }
      return api.post('/admin/modification_options', { ...values, group_id: currentGroupId })
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['mod_options', currentGroupId] })
      setOpenOption(false)
      setEditingOption(null)
      optionForm.resetFields()
    },
  })

  const deleteGroup = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/modification_groups/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['mod_groups'] }),
  })

  const deleteOption = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/modification_options/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['mod_options', currentGroupId] }),
  })

  const groupColumns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'Название', dataIndex: 'name' },
    { title: 'Тип', dataIndex: 'type' },
    { title: 'Мин.', dataIndex: 'min_count' },
    { title: 'Макс.', dataIndex: 'max_count' },
    {
      title: 'Товары',
      dataIndex: 'products',
      render: (list: any[]) => (list || []).map((p) => p.name || p.id).join(', '),
    },
    { title: 'Активна', dataIndex: 'is_active', render: (v: boolean) => (v ? <Tag color="green">Да</Tag> : <Tag>Нет</Tag>) },
    {
      title: 'Действия',
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            onClick={() => {
              setEditingGroup(record)
              groupForm.setFieldsValue({
                ...record,
                product_ids: (record.products || []).map((p: any) => p.id),
              })
              setOpenGroup(true)
            }}
          >
            Редактировать
          </Button>
          <Button
            size="small"
            onClick={() => {
              setCurrentGroupId(record.id)
              setOpenOption(true)
            }}
          >
            Опции
          </Button>
          <Button danger size="small" onClick={() => deleteGroup.mutate(record.id)}>
            Удалить
          </Button>
        </Space>
      ),
    },
  ]

  const optionColumns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'Название', dataIndex: 'name' },
    { title: 'Доплата', dataIndex: 'extra_price' },
    { title: 'По умолчанию', dataIndex: 'is_default', render: (v: boolean) => (v ? 'Да' : 'Нет') },
    {
      title: 'Действия',
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            onClick={() => {
              setEditingOption(record)
              optionForm.setFieldsValue(record)
              setOpenOption(true)
            }}
          >
            Редактировать
          </Button>
          <Button danger size="small" onClick={() => deleteOption.mutate(record.id)}>
            Удалить
          </Button>
        </Space>
      ),
    },
  ]

  return (
    <>
      <Space style={{ marginBottom: 12 }}>
        <Select
          placeholder="Фильтр по товару"
          allowClear
          style={{ width: 240 }}
          value={productFilter}
          onChange={(v) => setProductFilter(v)}
          options={(products || []).map((p: any) => ({ value: p.id, label: p.name }))}
        />
        <Button type="primary" onClick={() => setOpenGroup(true)}>
          Новая группа
        </Button>
      </Space>
      <Table loading={isLoading} dataSource={groups || []} columns={groupColumns} rowKey="id" />

      <Modal
        open={openGroup}
        title={editingGroup ? 'Редактировать группу' : 'Новая группа'}
        onCancel={() => {
          setOpenGroup(false)
          setEditingGroup(null)
        }}
        onOk={() => groupForm.submit()}
        confirmLoading={saveGroup.isPending}
      >
        <Form
          layout="vertical"
          form={groupForm}
          initialValues={{ type: 'single', min_count: 0, max_count: 1, is_active: true }}
          onFinish={(values) => saveGroup.mutate({ ...values, type: (values.type || 'single') })}
        >
          <Form.Item name="name" label="Название" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="product_ids" label="Товары">
            <Select
              mode="multiple"
              allowClear
              options={(products || []).map((p: any) => ({ value: p.id, label: p.name }))}
              placeholder="Выберите товары"
            />
          </Form.Item>
          <Form.Item name="type" label="Тип">
            <Select
              options={[
                { value: 'single', label: 'Один (радио)' },
                { value: 'multiple', label: 'Несколько (чекбоксы)' },
              ]}
            />
          </Form.Item>
          <Form.Item name="min_count" label="Мин. количество">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="max_count" label="Макс. количество">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="sort_order" label="Порядок сортировки">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="is_active" label="Активна" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        open={openOption}
        title={editingOption ? 'Редактировать опцию' : 'Новая опция'}
        onCancel={() => {
          setOpenOption(false)
          setEditingOption(null)
        }}
        onOk={() => optionForm.submit()}
        confirmLoading={saveOption.isPending}
      >
        <Form
          layout="vertical"
          form={optionForm}
          initialValues={{ is_active: true, sort_order: 0, is_default: false }}
          onFinish={(values) => saveOption.mutate(values)}
        >
          <Form.Item name="id" hidden>
            <Input />
          </Form.Item>
          <Form.Item name="name" label="Название" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="extra_price" label="Доплата" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="sort_order" label="Порядок сортировки">
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="is_default" label="По умолчанию" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Form.Item name="is_active" label="Активна" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>

        <Table
          style={{ marginTop: 16 }}
          loading={optionsQuery.isLoading}
          dataSource={optionsQuery.data || []}
          columns={optionColumns}
          rowKey="id"
          size="small"
        />
      </Modal>
    </>
  )
}


