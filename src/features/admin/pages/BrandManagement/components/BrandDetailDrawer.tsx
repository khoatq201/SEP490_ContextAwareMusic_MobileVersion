import {
  Drawer,
  Descriptions,
  Tag,
  Spin,
  Alert,
  Space,
  Flex,
  Avatar,
  Typography,
} from 'antd';

/**
 * Icons
 */
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  GlobalOutlined,
  MailOutlined,
  PhoneOutlined,
  ShopOutlined,
  ClockCircleOutlined,
  CrownOutlined,
  FileTextOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useBrand } from '@/features/admin/hooks';

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
import { AVATAR_SIZE, DRAWER_WIDTHS } from '@/config';

const { Text, Title } = Typography;

type BrandDetailDrawerProps = {
  open: boolean;
  brandId?: string | null;
  onClose: () => void;
};

export const BrandDetailDrawer = ({
  open,
  brandId,
  onClose,
}: BrandDetailDrawerProps) => {
  const {
    data: brand,
    isLoading,
    error,
  } = useBrand(brandId ?? undefined, open);

  return (
    <Drawer
      closeIcon={null}
      title='Brand Details'
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
          description='Failed to load brand details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {brand && !isLoading && (
        <Space
          direction='vertical'
          size='large'
          style={{ width: '100%' }}
        >
          {/* Brand Header */}
          <Flex
            align='center'
            gap='large'
          >
            <Avatar
              size={AVATAR_SIZE.extraLarge}
              src={brand.logoUrl}
              icon={<ShopOutlined />}
              shape='square'
            />
            <div>
              <Title
                level={4}
                style={{ margin: 0 }}
              >
                {brand.name}
              </Title>
              {brand.industry && <Text type='secondary'>{brand.industry}</Text>}
              <Flex
                gap='small'
                style={{ marginTop: 8 }}
              >
                <Tag
                  icon={
                    brand.status === EntityStatusEnum.Active ? (
                      <CheckCircleOutlined />
                    ) : (
                      <CloseCircleOutlined />
                    )
                  }
                  color={ENTITY_STATUS_COLORS[brand.status]}
                >
                  {ENTITY_STATUS_LABELS[brand.status]}
                </Tag>
                {brand.currentSubscriptionId && (
                  <Tag color='gold'>Has Subscription</Tag>
                )}
              </Flex>
            </div>
          </Flex>

          {/* Basic Information */}
          <Descriptions
            title='Basic Information'
            column={1}
            bordered
          >
            {brand.description && (
              <Descriptions.Item label='Description'>
                {brand.description}
              </Descriptions.Item>
            )}
            <Descriptions.Item label='Industry'>
              {brand.industry ?? '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Website'>
              {brand.website ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <GlobalOutlined />
                  <a
                    href={brand.website}
                    target='_blank'
                    rel='noopener noreferrer'
                  >
                    {brand.website}
                  </a>
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Default Timezone'>
              <Flex
                align='center'
                gap='small'
              >
                <ClockCircleOutlined />
                {brand.defaultTimeZone}
              </Flex>
            </Descriptions.Item>
          </Descriptions>

          {/* Contact Information */}
          <Descriptions
            title='Contact Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Primary Contact'>
              {brand.primaryContactName ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <CrownOutlined />
                  {brand.primaryContactName}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Contact Email'>
              {brand.contactEmail ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <MailOutlined />
                  {brand.contactEmail}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Technical Email'>
              {brand.technicalContactEmail ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <MailOutlined />
                  {brand.technicalContactEmail}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Contact Phone'>
              {brand.contactPhone ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <PhoneOutlined />
                  {brand.contactPhone}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Legal & Billing */}
          {(brand.legalName || brand.taxCode || brand.billingAddress) && (
            <Descriptions
              title='Legal & Billing'
              column={1}
              bordered
            >
              <Descriptions.Item label='Legal Name'>
                {brand.legalName ? (
                  <Flex
                    align='center'
                    gap='small'
                  >
                    <FileTextOutlined />
                    {brand.legalName}
                  </Flex>
                ) : (
                  '—'
                )}
              </Descriptions.Item>
              <Descriptions.Item label='Tax Code'>
                {brand.taxCode ?? '—'}
              </Descriptions.Item>
              <Descriptions.Item label='Billing Address'>
                {brand.billingAddress ?? '—'}
              </Descriptions.Item>
            </Descriptions>
          )}

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Brand ID'>
              <Tag>{brand.id}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Created At'>
              {formatDate(brand.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {brand.updatedAt ? formatDate(brand.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
