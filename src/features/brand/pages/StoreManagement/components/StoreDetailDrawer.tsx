import { Drawer, Descriptions, Tag, Spin, Alert, Space, Flex } from 'antd';

/**
 * Icons
 */
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  EnvironmentOutlined,
  PhoneOutlined,
  TeamOutlined,
  ExpandOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useStore } from '@/features/brand/hooks';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS, ENTITY_STATUS_COLORS } from '@/shared/constants';
import { EntityStatusEnum } from '@/shared/types';

/**
 * Utils
 */
import { formatDate } from '@/shared/utils';

/**
 * Config
 */
import { DRAWER_WIDTHS } from '@/config';

interface StoreDetailDrawerProps {
  open: boolean;
  storeId?: string;
  onClose: () => void;
}

export const StoreDetailDrawer = ({
  open,
  storeId,
  onClose,
}: StoreDetailDrawerProps) => {
  const { data: store, isLoading, error } = useStore(storeId, open);

  return (
    <Drawer
      closeIcon={null}
      title='Store Details'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={onClose}
    >
      {isLoading && (
        <Flex
          justify='center'
          align='center'
          style={{ padding: 48 }}
        >
          <Spin size='large' />
        </Flex>
      )}

      {error && !isLoading && (
        <Alert
          message='Error'
          description='Failed to load store details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {store && !isLoading && (
        <Space
          direction='vertical'
          size='large'
          style={{ width: '100%' }}
        >
          {/* Basic Information */}
          <Descriptions
            title='Basic Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Name'>{store.name}</Descriptions.Item>
            <Descriptions.Item label='Status'>
              <Tag
                icon={
                  store.status === EntityStatusEnum.Active ? (
                    <CheckCircleOutlined />
                  ) : (
                    <CloseCircleOutlined />
                  )
                }
                color={ENTITY_STATUS_COLORS[store.status]}
              >
                {ENTITY_STATUS_LABELS[store.status]}
              </Tag>
            </Descriptions.Item>
            {store.contactNumber && (
              <Descriptions.Item label='Contact Number'>
                <Flex
                  align='center'
                  gap='small'
                >
                  <PhoneOutlined />
                  {store.contactNumber}
                </Flex>
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* Location Information */}
          <Descriptions
            title='Location'
            column={1}
            bordered
          >
            {store.address && (
              <Descriptions.Item label='Address'>
                <Flex
                  align='center'
                  gap='small'
                >
                  <EnvironmentOutlined />
                  {store.address}
                </Flex>
              </Descriptions.Item>
            )}
            {store.city && (
              <Descriptions.Item label='City'>{store.city}</Descriptions.Item>
            )}
            {store.district && (
              <Descriptions.Item label='District'>
                {store.district}
              </Descriptions.Item>
            )}
            {store.latitude != null && store.longitude != null && (
              <Descriptions.Item label='Coordinates'>
                {store.latitude}, {store.longitude}
              </Descriptions.Item>
            )}
            {store.mapUrl && (
              <Descriptions.Item label='Map URL'>
                <a
                  href={store.mapUrl}
                  target='_blank'
                  rel='noopener noreferrer'
                >
                  Open in Maps
                </a>
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* Operational Details */}
          <Descriptions
            title='Operational Details'
            column={2}
            bordered
          >
            {store.areaSquareMeters != null && (
              <Descriptions.Item label='Area'>
                <Flex
                  align='center'
                  gap='small'
                >
                  <ExpandOutlined />
                  {store.areaSquareMeters} m²
                </Flex>
              </Descriptions.Item>
            )}
            {store.maxCapacity != null && (
              <Descriptions.Item label='Max Capacity'>
                <Flex
                  align='center'
                  gap='small'
                >
                  <TeamOutlined />
                  {store.maxCapacity} people
                </Flex>
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* AI / IoT Info */}
          {(store.currentMood != null ||
            store.firestoreCollectionPath ||
            store.lastMoodUpdateAt) && (
            <Descriptions
              title='AI / IoT Info'
              column={1}
              bordered
            >
              {store.currentMood != null && (
                <Descriptions.Item label='Current Mood'>
                  <Tag color='purple'>{String(store.currentMood)}</Tag>
                </Descriptions.Item>
              )}
              {store.lastMoodUpdateAt && (
                <Descriptions.Item label='Last Mood Update'>
                  {formatDate(store.lastMoodUpdateAt)}
                </Descriptions.Item>
              )}
              {store.firestoreCollectionPath && (
                <Descriptions.Item label='Firestore Path'>
                  <Tag>{store.firestoreCollectionPath}</Tag>
                </Descriptions.Item>
              )}
            </Descriptions>
          )}

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Store ID'>
              <Tag>{store.id}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Brand ID'>
              <Tag>{store.brandId}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Created At'>
              {formatDate(store.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {store.updatedAt ? formatDate(store.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
