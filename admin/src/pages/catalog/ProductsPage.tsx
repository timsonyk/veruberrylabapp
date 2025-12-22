import { useEffect, useMemo, useState } from 'react'
import {
  Button,
  Drawer,
  Form,
  Input,
  InputNumber,
  Modal,
  Select,
  Space,
  Switch,
  Table,
  Tag,
  Upload,
  message,
} from 'antd'
import type { UploadFile } from 'antd/es/upload/interface'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../../lib/api'

const fetchProducts = async () => (await api.get('/admin/products')).data
const fetchCategories = async () => (await api.get('/admin/categories')).data
const fetchSizes = async (productId?: number) =>
  (await api.get('/admin/product_sizes', { params: productId ? { product_id: productId } : {} })).data

export const ProductsPage = () => {
  const qc = useQueryClient()
  const { data: products, isLoading } = useQuery({ queryKey: ['products'], queryFn: fetchProducts })
  const { data: categories } = useQuery({ queryKey: ['categories'], queryFn: fetchCategories })
  const [form] = Form.useForm()
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<any>(null)
  const [fileList, setFileList] = useState<UploadFile[]>([])

  const [sizesOpen, setSizesOpen] = useState(false)
  const [currentProductId, setCurrentProductId] = useState<number | null>(null)
  const sizesQuery = useQuery({
    queryKey: ['product_sizes', currentProductId],
    queryFn: () => fetchSizes(currentProductId || undefined),
    enabled: !!currentProductId,
  })
  const [sizeForm] = Form.useForm()

  const saveProduct = useMutation({
    mutationFn: async (values: any) => {
      if (editing) return api.put(`/admin/products/${editing.id}`, values)
      return api.post('/admin/products', values)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['products'] })
      setOpen(false)
      setEditing(null)
      form.resetFields()
    },
  })

  const saveSize = useMutation({
    mutationFn: async (values: any) => {
      if (values.id) {
        const { id, ...rest } = values
        return api.put(`/admin/product_sizes/${id}`, rest)
      }
      return api.post('/admin/product_sizes', { ...values, product_id: currentProductId })
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['product_sizes', currentProductId] })
      sizeForm.resetFields()
    },
  })

  const deleteSize = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/product_sizes/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['product_sizes', currentProductId] }),
  })

  const deleteProduct = useMutation({
    mutationFn: async (id: number) => api.delete(`/admin/products/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['products'] }),
  })

  const columns = useMemo(
    () => [
      { title: 'ID', dataIndex: 'id' },
      { title: 'Name', dataIndex: 'name' },
      {
        title: 'Category',
        dataIndex: 'category_id',
        render: (id: number) => categories?.find((c: any) => c.id === id)?.name || id,
      },
      { title: 'Base price', dataIndex: 'base_price' },
      { title: 'Sizes', render: (_: any, record: any) => (record.size_label ? record.size_label : 'sizes table') },
      { title: 'Active', dataIndex: 'is_active', render: (v: boolean) => (v ? <Tag color="green">Yes</Tag> : <Tag>No</Tag>) },
      {
        title: 'Actions',
        render: (_: any, record: any) => (
          <Space>
            <Button
              size="small"
              onClick={() => {
                setEditing(record)
                form.resetFields()
                form.setFieldsValue(record)
                if (record.media && Array.isArray(record.media)) {
                  setFileList(
                    record.media.map((url: string, idx: number) => ({
                      uid: `${idx}`,
                      name: url.split('/').pop() || `image-${idx}`,
                      status: 'done',
                      url,
                    })),
                  )
                } else {
                  setFileList([])
                }
                setOpen(true)
              }}
            >
              Edit
            </Button>
            <Button
              size="small"
              onClick={() => {
                setCurrentProductId(record.id)
                setSizesOpen(true)
              }}
            >
              Sizes
            </Button>
            <Button danger size="small" onClick={() => deleteProduct.mutate(record.id)}>
              Delete
            </Button>
          </Space>
        ),
      },
    ],
    [categories, form, deleteProduct],
  )

  const openCreate = () => {
    setEditing(null)
    form.resetFields()
    form.setFieldsValue({ is_active: true, sort_order: 0 })
    setFileList([])
    setOpen(true)
  }

  const sizeColumns = [
    { title: 'ID', dataIndex: 'id' },
    { title: 'Name', dataIndex: 'name' },
    { title: 'Price', dataIndex: 'base_price' },
    { title: 'Sort', dataIndex: 'sort_order' },
    {
      title: 'Actions',
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            onClick={() => {
              sizeForm.setFieldsValue(record)
            }}
          >
            Edit
          </Button>
          <Button danger size="small" onClick={() => deleteSize.mutate(record.id)}>
            Delete
          </Button>
        </Space>
      ),
    },
  ]

  useEffect(() => {
    if (!sizesOpen) {
      setCurrentProductId(null)
      sizeForm.resetFields()
    }
  }, [sizesOpen, sizeForm])

  return (
    <>
      <Space style={{ marginBottom: 12 }}>
        <Button type="primary" onClick={openCreate}>
          New product
        </Button>
      </Space>
      <Table loading={isLoading} dataSource={products || []} columns={columns as any} rowKey="id" />

      <Modal
        open={open}
        title={editing ? 'Edit product' : 'New product'}
        onCancel={() => setOpen(false)}
        onOk={() => form.submit()}
        confirmLoading={saveProduct.isPending}
        destroyOnHidden
      >
        <Form
          layout="vertical"
          form={form}
          initialValues={{ is_active: true, sort_order: 0 }}
          onFinish={(values) => {
            const mediaUrls = fileList
              .map((f) => (f.response as any)?.url || f.url)
              .filter(Boolean)
            saveProduct.mutate({ ...values, media: mediaUrls })
          }}
        >
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="category_id" label="Category" rules={[{ required: true }]}>
            <Select options={(categories || []).map((c: any) => ({ value: c.id, label: c.name }))} />
          </Form.Item>
          <Form.Item name="description" label="Description">
            <Input.TextArea rows={3} />
          </Form.Item>
          <Form.Item name="base_price" label="Base price" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="size_label" label="Size label (fallback)">
            <Input placeholder="S / M / L / XL" />
          </Form.Item>
          <Form.Item label="Images">
            <Upload.Dragger
              name="file"
              multiple
              fileList={fileList}
              customRequest={async (options) => {
                const { file, onError, onSuccess } = options
                const formData = new FormData()
                formData.append('file', file as Blob)
                try {
                  const res = await api.post('/admin/upload', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                  })
                  const url = res.data.url
                  onSuccess?.(res.data, file as any)
                  setFileList((prev) =>
                    prev.map((f) => (f.uid === (file as UploadFile).uid ? { ...f, url, status: 'done' } : f)),
                  )
                } catch (err: any) {
                  message.error(err?.response?.data?.detail || 'Upload failed')
                  onError?.(err)
                }
              }}
              onChange={({ fileList: fl }) => setFileList(fl)}
              onRemove={(file) => {
                setFileList((prev) => prev.filter((f) => f.uid !== file.uid))
              }}
              accept="image/*"
              listType="picture-card"
            >
              <p className="ant-upload-drag-icon">Click or drag files</p>
            </Upload.Dragger>
          </Form.Item>
          <Form.Item name="sort_order" label="Sort order" initialValue={0}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item name="is_active" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      <Drawer
        title="Product sizes"
        open={sizesOpen}
        onClose={() => setSizesOpen(false)}
        size="large"
        destroyOnHidden
      >
        <Form layout="vertical" form={sizeForm} onFinish={(values) => saveSize.mutate(values)}>
          <Form.Item name="id" hidden>
            <Input />
          </Form.Item>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="base_price" label="Price" rules={[{ required: true }]}>
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="sort_order" label="Sort order" initialValue={0}>
            <InputNumber style={{ width: '100%' }} />
          </Form.Item>
          <Space>
            <Button type="primary" htmlType="submit" loading={saveSize.isPending}>
              Save
            </Button>
            <Button onClick={() => sizeForm.resetFields()}>Clear</Button>
          </Space>
        </Form>

        <Table
          style={{ marginTop: 16 }}
          loading={sizesQuery.isLoading}
          dataSource={sizesQuery.data || []}
          columns={sizeColumns}
          rowKey="id"
          size="small"
        />
      </Drawer>
    </>
  )
}


