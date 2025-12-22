import { Descriptions, Divider, List, Tag } from 'antd'
import { useQuery } from '@tanstack/react-query'
import { useParams } from 'react-router-dom'
import { api } from '../../lib/api'

const fetchOrder = async (id: string) => (await api.get(`/admin/orders/${id}`)).data

export const OrderDetailPage = () => {
  const { id } = useParams()
  const { data, isLoading } = useQuery({ queryKey: ['order', id], queryFn: () => fetchOrder(id!), enabled: !!id })

  if (isLoading || !data) return null

  return (
    <div>
      <Descriptions title={`Order #${data.id}`} bordered column={1}>
        <Descriptions.Item label="User">{data.user_id}</Descriptions.Item>
        <Descriptions.Item label="Status">
          <Tag>{data.status}</Tag>
        </Descriptions.Item>
        <Descriptions.Item label="Delivery type">{data.delivery_type}</Descriptions.Item>
        <Descriptions.Item label="Address">{data.address_text}</Descriptions.Item>
        <Descriptions.Item label="City">{data.city}</Descriptions.Item>
        <Descriptions.Item label="Total">{data.total} ₽</Descriptions.Item>
        <Descriptions.Item label="Delivery fee">{data.delivery_fee} ₽</Descriptions.Item>
        <Descriptions.Item label="Discount">{data.discount} ₽</Descriptions.Item>
        <Descriptions.Item label="Comment">{data.comment}</Descriptions.Item>
        <Descriptions.Item label="No call">{data.no_call ? 'Yes' : 'No'}</Descriptions.Item>
      </Descriptions>

      <Divider />
      <List
        header="Items"
        dataSource={data.items || []}
        renderItem={(item: any) => (
          <List.Item>
            #{item.product_id} size:{item.size_id ?? '-'} qty:{item.quantity} price:{item.final_price} ₽
          </List.Item>
        )}
      />
    </div>
  )
}


