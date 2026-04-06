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
  CrownOutlined,
  MailOutlined,
  PhoneOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useAccount } from '@/features/admin/hooks';

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

type AccountDetailDrawerProps = {
  open: boolean;
  accountId?: string | null;
  onClose: () => void;
};

export const AccountDetailDrawer = ({
  open,
  accountId,
  onClose,
}: AccountDetailDrawerProps) => {
  const {
    data: account,
    isLoading,
    error,
  } = useAccount(accountId ?? undefined, open);

  return (
    <Drawer
      closeIcon={null}
      title='Account Details'
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
          description='Failed to load account details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {account && !isLoading && (
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
              src={account.avatarUrl}
              icon={<UserOutlined />}
            />
            <div>
              <Flex
                align='center'
                gap='small'
              >
                <Title
                  level={4}
                  style={{ margin: 0 }}
                >
                  {account.fullName}
                </Title>
                {account.isPrimaryOwner && (
                  <Tag
                    icon={<CrownOutlined />}
                    color='gold'
                  >
                    Primary Owner
                  </Tag>
                )}
              </Flex>
              <Text type='secondary'>{account.email}</Text>
              <Flex
                gap='small'
                style={{ marginTop: 8 }}
              >
                <Tag
                  icon={
                    account.status === EntityStatusEnum.Active ? (
                      <CheckCircleOutlined />
                    ) : (
                      <CloseCircleOutlined />
                    )
                  }
                  color={ENTITY_STATUS_COLORS[account.status]}
                >
                  {ENTITY_STATUS_LABELS[account.status]}
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
                {account.email}
              </Flex>
            </Descriptions.Item>
            <Descriptions.Item label='Phone Number'>
              {account.phoneNumber ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <PhoneOutlined />
                  {account.phoneNumber}
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Organization */}
          <Descriptions
            title='Organization'
            column={1}
            bordered
          >
            <Descriptions.Item label='Brand'>
              {account.brandName ? (
                <Flex
                  align='center'
                  gap='small'
                >
                  <Tag color='blue'>{account.brandName}</Tag>
                </Flex>
              ) : (
                '—'
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Security */}
          <Descriptions
            title='Security'
            column={1}
            bordered
          >
            <Descriptions.Item label='Two-Factor Auth'>
              {account.twoFactorEnabled ? (
                <Badge
                  status='success'
                  text='Enabled'
                />
              ) : (
                <Badge
                  status='default'
                  text='Disabled'
                />
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Last Login'>
              {account.lastLoginAt ? formatDate(account.lastLoginAt) : 'Never'}
            </Descriptions.Item>
          </Descriptions>

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Account ID'>
              <Tag>{account.id}</Tag>
            </Descriptions.Item>
            {account.brandId && (
              <Descriptions.Item label='Brand ID'>
                <Tag>{account.brandId}</Tag>
              </Descriptions.Item>
            )}
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
