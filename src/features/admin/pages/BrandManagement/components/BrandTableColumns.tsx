import { Button, Dropdown, Tag, Avatar } from 'antd';

/**
 * Icons
 */
import {
  EditOutlined,
  DeleteOutlined,
  MoreOutlined,
  EyeOutlined,
  PoweroffOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';

/**
 * Types
 */
import type { ColumnsType } from 'antd/es/table';
import type { MenuProps } from 'antd';
import type { BrandListItem } from '@/features/admin/types';
import { EntityStatusEnum } from '@/shared/types';

/**
 * Constants
 */
import {
  BRAND_STATUS_COLORS,
  BRAND_STATUS_LABELS,
} from '@/features/admin/constants';

/**
 * Configs
 */
import { AVATAR_SIZE } from '@/config';

type GetColumnsProps = {
  onView: (brandId: string) => void;
  onEdit: (brand: BrandListItem) => void;
  onToggleStatus: (brandId: string) => void;
  onDelete: (brandId: string) => void;
};

export const getBrandColumns = ({
  onView,
  onEdit,
  onToggleStatus,
  onDelete,
}: GetColumnsProps): ColumnsType<BrandListItem> => {
  const getActionMenuItems = (record: BrandListItem): MenuProps['items'] => [
    {
      key: 'view',
      label: 'View Details',
      icon: <EyeOutlined />,
      onClick: () => onView(record.id),
    },
    {
      type: 'divider',
    },
    {
      key: 'edit',
      label: 'Edit',
      icon: <EditOutlined />,
      onClick: () => onEdit(record),
    },
    {
      key: 'toggle-status',
      label:
        record.status === EntityStatusEnum.Active ? 'Deactivate' : 'Activate',
      icon:
        record.status === EntityStatusEnum.Active ? (
          <PoweroffOutlined />
        ) : (
          <CheckCircleOutlined />
        ),
      onClick: () => onToggleStatus(record.id),
      danger: record.status === EntityStatusEnum.Active,
    },
    {
      key: 'delete',
      label: 'Delete',
      icon: <DeleteOutlined />,
      onClick: () => onDelete(record.id),
      danger: true,
    },
  ];

  return [
    {
      title: 'No.',
      key: 'index',
      width: 70,
      render: (_text, _record, index) => index + 1,
    },
    {
      title: 'Brand',
      key: 'brand',
      render: (_, record) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Avatar
            src={record.logoUrl}
            size={AVATAR_SIZE.medium}
            shape='square'
            style={{ borderRadius: 5 }}
          >
            {record.name.charAt(0).toUpperCase()}
          </Avatar>
          <div>
            <div style={{ fontWeight: 500 }}>{record.name}</div>
            {record.industry && (
              <div style={{ fontSize: 12, color: '#8c8c8c' }}>
                {record.industry}
              </div>
            )}
          </div>
        </div>
      ),
      sorter: (a, b) => a.name.localeCompare(b.name),
    },
    {
      title: 'Contact',
      key: 'contact',
      render: (_, record) => (
        <div>
          {record.primaryContactName && <div>{record.primaryContactName}</div>}
          {record.contactEmail && (
            <div style={{ fontSize: 12, color: '#8c8c8c' }}>
              {record.contactEmail}
            </div>
          )}
          {record.contactPhone && (
            <div style={{ fontSize: 12, color: '#8c8c8c' }}>
              {record.contactPhone}
            </div>
          )}
        </div>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: EntityStatusEnum) => (
        <Tag color={BRAND_STATUS_COLORS[status]}>
          {BRAND_STATUS_LABELS[status]}
        </Tag>
      ),
    },
    {
      title: 'Created At',
      dataIndex: 'createdAt',
      key: 'createdAt',
      width: 150,
      render: (date: string) => new Date(date).toLocaleDateString(),
    },
    {
      title: 'Actions',
      key: 'actions',
      fixed: 'right',
      width: 80,
      render: (_, record) => (
        <Dropdown
          menu={{ items: getActionMenuItems(record) }}
          placement='bottomRight'
          trigger={['click']}
        >
          <Button
            type='text'
            icon={<MoreOutlined />}
          />
        </Dropdown>
      ),
    },
  ];
};
