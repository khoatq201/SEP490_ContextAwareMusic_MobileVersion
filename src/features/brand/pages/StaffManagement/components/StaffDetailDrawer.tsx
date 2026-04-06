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
  Badge,
} from 'antd';

/**
 * Icons
 */
import {
  UserOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  MailOutlined,
  PhoneOutlined,
  ShopOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useStaffDetail } from '@/features/brand/hooks';

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

type StaffDetailDrawerProps = {
  open: boolean;
  staffId?: string | null;
  onClose: () => void;
};

export const StaffDetailDrawer = ({
  open,
  staffId,
  onClose,
}: StaffDetailDrawerProps) => {
  const {
    data: staff,
    isLoading,
    error,
  } = useStaffDetail(staffId ?? undefined, open);

  return (
    <Drawer
      closeIcon={null}
      title='Staff Details'
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
          description='Failed to load staff details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {staff && !isLoading && (
        <Space
          direction='vertical'
          size='large'
          style={{ width: '100%' }}
        >
          {/* Profile Header */}
          <Flex
            align='center'
            gap='large'
          >
            <Avatar
              size={AVATAR_SIZE.extraLarge}
              shape='square'
              src={staff.avatarUrl}
              icon={<UserOutlined />}
            />
            <div>
              <Title
                level={4}
                style={{ margin: 0 }}
              >
                {staff.fullName}
              </Title>
              <Text type='secondary'>{staff.email}</Text>
              <Flex
                gap='small'
                style={{ marginTop: 8 }}
              >
                <Tag
                  icon={
                    staff.status === EntityStatusEnum.Active ? (
                      <CheckCircleOutlined />
                    ) : (
                      <CloseCircleOutlined />
                    )
                  }
                  color={ENTITY_STATUS_COLORS[staff.status]}
                >
                  {ENTITY_STATUS_LABELS[staff.status]}
                </Tag>
              </Flex>
            </div>
          </Flex>

          {/* Contact Information */}
          <Descriptions
            title='Contact Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Email'>
              <Flex
                align='center'
                gap='small'
              >
                <MailOutlined />
                {staff.email}
              </Flex>
            </Descriptions.Item>
            <Descriptions.Item label='Phone Number'>
              {staff.phoneNumber ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <PhoneOutlined />
                  {staff.phoneNumber}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Assignment */}
          <Descriptions
            title='Assignment'
            column={1}
            bordered
          >
            <Descriptions.Item label='Brand'>
              {staff.brandName ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <ShopOutlined />
                  <Tag color='blue'>{staff.brandName}</Tag>
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Store'>
              {staff.storeName ? (
                <Tag color='green'>{staff.storeName}</Tag>
              ) : (
                <Badge
                  status='warning'
                  text='Not assigned to any store'
                />
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Security */}
          <Descriptions
            title='Security'
            column={1}
            bordered
          >
            <Descriptions.Item label='Last Login'>
              {staff.lastLoginAt ? formatDate(staff.lastLoginAt) : 'Never'}
            </Descriptions.Item>
          </Descriptions>

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Staff ID'>
              <Tag>{staff.id}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Created At'>
              {formatDate(staff.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {staff.updatedAt ? formatDate(staff.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
