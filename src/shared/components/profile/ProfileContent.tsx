import {
  Avatar,
  Card,
  Col,
  Descriptions,
  Flex,
  Row,
  Tag,
  Typography,
  Badge,
} from 'antd';

/**
 * Icons
 */
import {
  UserOutlined,
  MailOutlined,
  PhoneOutlined,
  ShopOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  CrownOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useMyProfile } from '@/shared/modules/auth/hooks';

/**
 * Components
 */

const { Title, Text } = Typography;

/**
 * Constants
 */
import {
  ENTITY_STATUS_LABELS,
  ENTITY_STATUS_COLORS,
  ROLE_LABELS,
  ROLE_COLORS,
} from '@/shared/constants';

/**
 * Types
 */
import { EntityStatusEnum, type RoleEnum } from '@/shared/types';

/**
 * Utils
 */
import { formatDate } from '@/shared/utils';

/**
 * ProfileContent - Profile tab content
 * Displays user profile information (read-only)
 */
export const ProfileContent = () => {
  const { data: profile, isLoading } = useMyProfile();

  return (
    <Row gutter={[24, 24]}>
      {/* Left sidebar */}
      <Col
        xs={24}
        md={6}
      >
        <Card
          loading={isLoading}
          styles={{ body: { padding: 24 } }}
        >
          <Flex
            vertical
            align='center'
            gap='small'
            style={{ marginBottom: 24 }}
          >
            <div
              style={{
                width: 120,
                height: 120,
                borderRadius: '50%',
                border: '2px dashed var(--ant-blue-4)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Avatar
                size={110}
                src={profile?.avatarUrl}
                icon={<UserOutlined className='text-blue-600!' />}
                className='bg-blue-50!'
              />
            </div>
            <Flex
              align='center'
              gap='small'
            >
              <Title
                level={5}
                style={{ margin: 0 }}
              >
                {profile?.fullName ?? '—'}
              </Title>
              {profile?.isPrimaryOwner && (
                <CrownOutlined style={{ color: '#faad14' }} />
              )}
            </Flex>
            <Text
              type='secondary'
              style={{ fontSize: 13 }}
            >
              {profile?.roles
                ?.map((r: RoleEnum) => ROLE_LABELS[r])
                .join(', ') ?? '—'}
            </Text>
            <Flex
              gap='small'
              wrap='wrap'
              justify='center'
            >
              {profile?.roles?.map((r: RoleEnum) => (
                <Tag
                  key={r}
                  color={ROLE_COLORS[r]}
                >
                  {ROLE_LABELS[r]}
                </Tag>
              ))}
              {profile && (
                <Tag
                  icon={
                    profile.status === EntityStatusEnum.Active ? (
                      <CheckCircleOutlined />
                    ) : (
                      <CloseCircleOutlined />
                    )
                  }
                  color={ENTITY_STATUS_COLORS[profile.status]}
                >
                  {ENTITY_STATUS_LABELS[profile.status]}
                </Tag>
              )}
            </Flex>
          </Flex>

          {/* Organization */}
          <Flex
            vertical
            gap='small'
          >
            {profile?.brandName && (
              <Flex
                align='center'
                gap='small'
              >
                <ShopOutlined style={{ color: '#1677ff' }} />
                <Text style={{ fontSize: 13 }}>{profile.brandName}</Text>
              </Flex>
            )}
            {profile?.storeName && (
              <Flex
                align='center'
                gap='small'
              >
                <ShopOutlined style={{ color: '#52c41a' }} />
                <Text style={{ fontSize: 13 }}>{profile.storeName}</Text>
              </Flex>
            )}
            {profile?.lastLoginAt && (
              <Flex
                align='center'
                gap='small'
                justify='center'
              >
                <SafetyCertificateOutlined style={{ color: '#722ed1' }} />
                <Text
                  type='secondary'
                  style={{ fontSize: 12 }}
                >
                  Last login: {formatDate(profile.lastLoginAt)}
                </Text>
              </Flex>
            )}
          </Flex>
        </Card>
      </Col>

      {/* Right content */}
      <Col
        xs={24}
        md={18}
      >
        <Flex
          vertical
          gap='large'
        >
          {/* Personal Information */}
          <Card
            title='Personal Information'
            loading={isLoading}
          >
            <Row gutter={[16, 16]}>
              <Col
                xs={24}
                sm={12}
              >
                <Flex
                  vertical
                  gap={4}
                >
                  <Text
                    type='secondary'
                    style={{ fontSize: 12 }}
                  >
                    First Name
                  </Text>
                  <div
                    style={{
                      padding: '8px 12px',
                      border: '1px solid #d9d9d9',
                      borderRadius: 6,
                      background: '#fafafa',
                      minHeight: 40,
                    }}
                  >
                    <Text>{profile?.firstName ?? '—'}</Text>
                  </div>
                </Flex>
              </Col>
              <Col
                xs={24}
                sm={12}
              >
                <Flex
                  vertical
                  gap={4}
                >
                  <Text
                    type='secondary'
                    style={{ fontSize: 12 }}
                  >
                    Last Name
                  </Text>
                  <div
                    style={{
                      padding: '8px 12px',
                      border: '1px solid #d9d9d9',
                      borderRadius: 6,
                      background: '#fafafa',
                      minHeight: 40,
                    }}
                  >
                    <Text>{profile?.lastName ?? '—'}</Text>
                  </div>
                </Flex>
              </Col>
              <Col
                xs={24}
                sm={12}
              >
                <Flex
                  vertical
                  gap={4}
                >
                  <Text
                    type='secondary'
                    style={{ fontSize: 12 }}
                  >
                    Email Address
                  </Text>
                  <div
                    style={{
                      padding: '8px 12px',
                      border: '1px solid #d9d9d9',
                      borderRadius: 6,
                      background: '#fafafa',
                      minHeight: 40,
                    }}
                  >
                    <Flex
                      align='center'
                      gap='small'
                    >
                      <MailOutlined style={{ color: '#8c8c8c' }} />
                      <Text>{profile?.email ?? '—'}</Text>
                      {profile?.emailConfirmed ? (
                        <Badge status='success' />
                      ) : (
                        <Badge status='warning' />
                      )}
                    </Flex>
                  </div>
                </Flex>
              </Col>
              <Col
                xs={24}
                sm={12}
              >
                <Flex
                  vertical
                  gap={4}
                >
                  <Text
                    type='secondary'
                    style={{ fontSize: 12 }}
                  >
                    Phone Number
                  </Text>
                  <div
                    style={{
                      padding: '8px 12px',
                      border: '1px solid #d9d9d9',
                      borderRadius: 6,
                      background: '#fafafa',
                      minHeight: 40,
                    }}
                  >
                    <Flex
                      align='center'
                      gap='small'
                    >
                      <PhoneOutlined style={{ color: '#8c8c8c' }} />
                      <Text>{profile?.phoneNumber ?? 'Not provided'}</Text>
                      {profile?.phoneNumber &&
                        (profile.phoneNumberConfirmed ? (
                          <Badge status='success' />
                        ) : (
                          <Badge status='warning' />
                        ))}
                    </Flex>
                  </div>
                </Flex>
              </Col>
            </Row>
          </Card>

          {/* Organization */}
          {(profile?.brandName || profile?.storeName) && (
            <Card
              title='Organization'
              loading={isLoading}
            >
              <Row gutter={[16, 16]}>
                {profile.brandName && (
                  <Col
                    xs={24}
                    sm={12}
                  >
                    <Flex
                      vertical
                      gap={4}
                    >
                      <Text
                        type='secondary'
                        style={{ fontSize: 12 }}
                      >
                        Brand
                      </Text>
                      <div
                        style={{
                          padding: '8px 12px',
                          border: '1px solid #d9d9d9',
                          borderRadius: 6,
                          background: '#fafafa',
                          minHeight: 40,
                        }}
                      >
                        <Tag color='blue'>{profile.brandName}</Tag>
                      </div>
                    </Flex>
                  </Col>
                )}
                {profile.storeName && (
                  <Col
                    xs={24}
                    sm={12}
                  >
                    <Flex
                      vertical
                      gap={4}
                    >
                      <Text
                        type='secondary'
                        style={{ fontSize: 12 }}
                      >
                        Store
                      </Text>
                      <div
                        style={{
                          padding: '8px 12px',
                          border: '1px solid #d9d9d9',
                          borderRadius: 6,
                          background: '#fafafa',
                          minHeight: 40,
                        }}
                      >
                        <Tag color='green'>{profile.storeName}</Tag>
                      </div>
                    </Flex>
                  </Col>
                )}
              </Row>
            </Card>
          )}

          {/* Security & System */}
          <Card
            title='Security & System'
            loading={isLoading}
          >
            <Descriptions
              column={{ xs: 1, sm: 2 }}
              bordered
            >
              <Descriptions.Item label='Two-Factor Auth'>
                {profile?.twoFactorEnabled ? (
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
              <Descriptions.Item label='Email Confirmed'>
                {profile?.emailConfirmed ? (
                  <Badge
                    status='success'
                    text='Confirmed'
                  />
                ) : (
                  <Badge
                    status='warning'
                    text='Not confirmed'
                  />
                )}
              </Descriptions.Item>
              <Descriptions.Item label='Last Login'>
                {profile?.lastLoginAt
                  ? formatDate(profile.lastLoginAt)
                  : 'Never'}
              </Descriptions.Item>
              <Descriptions.Item label='Member Since'>
                {profile?.createdAt ? formatDate(profile.createdAt) : '—'}
              </Descriptions.Item>
              <Descriptions.Item
                label='Account ID'
                span={2}
              >
                <Tag>{profile?.id ?? '—'}</Tag>
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Flex>
      </Col>
    </Row>
  );
};
