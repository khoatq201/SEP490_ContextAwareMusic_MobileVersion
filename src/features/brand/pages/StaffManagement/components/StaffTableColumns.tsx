import { Space, Dropdown, Avatar, Tag, Button } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  MoreOutlined,
  UserOutlined,
  CrownOutlined,
  ShopOutlined,
  EyeOutlined,
  EditOutlined,
  PoweroffOutlined,
  CheckCircleOutlined,
  SwapOutlined,
  LockOutlined,
} from '@ant-design/icons';

/**
 * Types
 */
import type { StaffListItem } from '@/features/brand/types';

/**
 * Utils
 */
import { formatDateTime } from '@/shared/utils';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS, ENTITY_STATUS_COLORS } from '@/shared/constants';
import type { EntityStatusEnum } from '@/shared/types';
import { AVATAR_SIZE } from '@/config';

type GetColumnsProps = {
  onView: (staffId: string) => void;
  onEdit: (staffId: string) => void;
  onAssignStore: (staffId: string) => void;
  onResetPassword: (staffId: string) => void;
  onToggleStatus: (staffId: string) => void;
};

/**
 * Columns for GROUP ROWS (Store summary)
 */
export const getGroupColumns = (): ColumnsType<StaffListItem> => [
  {
    title: 'No.',
    key: 'index',
    width: 70,
    render: (_text, _record, index) => index + 1,
  },
  {
    title: 'Store',
    key: 'store',
    render: (_, record) => (
      <Space size={12}>
        <Avatar
          src={record.brandLogoUrl}
          size={AVATAR_SIZE.medium}
          icon={<ShopOutlined />}
          shape='square'
        />
        <div>
          <div style={{ fontWeight: 500 }}>
            {record.storeName || 'Unassigned Staff'}
          </div>
          <div style={{ fontSize: 12, color: '#8c8c8c' }}>
            <UserOutlined style={{ marginRight: 4 }} />
            {record.children?.length || 0}{' '}
            {record.children?.length === 1 ? 'staff member' : 'staff members'}
          </div>
        </div>
      </Space>
    ),
  },
];

/**
 * Columns for EXPANDED ROWS (Staff details)
 */
export const getExpandedColumns = ({
  onView,
  onEdit,
  onAssignStore,
  onResetPassword,
  onToggleStatus,
}: GetColumnsProps): ColumnsType<StaffListItem> => [
  {
    title: 'No.',
    key: 'index',
    width: 70,
    render: (_text, _record, index) => index + 1,
  },
  {
    title: 'Staff',
    dataIndex: 'fullName',
    key: 'fullName',
    sorter: true,
    render: (_, record) => (
      <Space size={12}>
        <Avatar
          src={record.avatarUrl}
          size={AVATAR_SIZE.medium}
          shape='square'
          icon={<UserOutlined />}
        />
        <div>
          <div style={{ fontWeight: 500 }}>
            {record.fullName}
            {record.isPrimaryOwner && (
              <CrownOutlined
                style={{ marginLeft: 8, color: '#faad14' }}
                title='Primary Owner'
              />
            )}
          </div>
          <div style={{ fontSize: 12, color: '#8c8c8c' }}>{record.email}</div>
          <div style={{ fontSize: 12, color: '#8c8c8c' }}>
            {record.phoneNumber}
          </div>
        </div>
      </Space>
    ),
  },
  {
    title: 'Status',
    dataIndex: 'status',
    key: 'status',
    width: 120,
    sorter: true,
    render: (status: EntityStatusEnum) => (
      <Tag color={ENTITY_STATUS_COLORS[status]}>
        {ENTITY_STATUS_LABELS[status]}
      </Tag>
    ),
  },
  {
    title: 'Last Login',
    dataIndex: 'lastLogin',
    key: 'lastLogin',
    width: 150,
    sorter: true,
    render: (lastLogin: string | null) =>
      lastLogin ? formatDateTime(lastLogin) : 'Never',
  },
  {
    title: 'Actions',
    key: 'actions',
    width: 80,
    fixed: 'right',
    render: (_, record) => (
      <Dropdown
        menu={{
          items: [
            {
              key: 'view',
              label: 'View Details',
              icon: <EyeOutlined />,
              onClick: () => onView(record.id),
            },
            {
              key: 'edit',
              label: 'Edit',
              icon: <EditOutlined />,
              onClick: () => onEdit(record.id),
            },
            {
              key: 'assign-store',
              label: 'Assign Store',
              icon: <SwapOutlined />,
              onClick: () => onAssignStore(record.id),
            },
            {
              key: 'reset-password',
              label: 'Reset Password',
              icon: <LockOutlined />,
              onClick: () => onResetPassword(record.id),
            },
            {
              type: 'divider',
            },
            {
              key: 'toggle-status',
              label: record.status === 1 ? 'Deactivate' : 'Activate',
              icon:
                record.status === 1 ? (
                  <PoweroffOutlined />
                ) : (
                  <CheckCircleOutlined />
                ),
              onClick: () => onToggleStatus(record.id),
              danger: record.status === 1,
            },
          ],
        }}
        trigger={['click']}
        placement='bottomRight'
      >
        <Button
          type='text'
          icon={<MoreOutlined />}
        />
      </Dropdown>
    ),
  },
];
