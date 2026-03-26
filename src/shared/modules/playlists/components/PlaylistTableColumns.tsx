import { Space, Tag, Dropdown, Button, type MenuProps } from 'antd';

/**
 * Icons
 */
import {
  MoreOutlined,
  EyeOutlined,
  EditOutlined,
  DeleteOutlined,
  PoweroffOutlined,
  PlusOutlined,
} from '@ant-design/icons';

/**
 * Utils
 */
import { formatDateTime } from '@/shared/utils';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS, ENTITY_STATUS_COLORS } from '@/shared/constants';

/**
 * Types
 */
import type { ColumnsType } from 'antd/es/table';
import type { PlaylistListItem } from '@/shared/modules/playlists/types';
import type { EntityStatusEnum } from '@/shared/types';

interface PlaylistColumnActions {
  onView: (id: string) => void;
  onEdit?: (id: string) => void;
  onDelete?: (id: string) => void;
  onToggleStatus?: (id: string) => void;
  onAddTracks?: (id: string) => void;
}

export const getPlaylistColumns = ({
  onView,
  onEdit,
  onDelete,
  onToggleStatus,
  onAddTracks,
}: PlaylistColumnActions): ColumnsType<PlaylistListItem> => [
  {
    title: 'No.',
    key: 'index',
    width: 70,
    render: (_text, _record, index) => index + 1,
  },
  {
    title: 'Name',
    dataIndex: 'name',
    key: 'name',
    width: 250,
    sorter: true,
    render: (name: string, record: PlaylistListItem) => (
      <Space
        direction='vertical'
        size={0}
      >
        <span style={{ fontWeight: 500 }}>{name}</span>
        {record.storeName && (
          <span style={{ fontSize: 12, color: '#999' }}>
            Store: {record.storeName}
          </span>
        )}
      </Space>
    ),
  },
  {
    title: 'Mood',
    dataIndex: 'moodName',
    key: 'moodName',
    width: 120,
    render: (moodName: string) =>
      moodName ? <Tag color='blue'>{moodName}</Tag> : '—',
  },
  {
    title: 'Tracks',
    dataIndex: 'trackCount',
    key: 'trackCount',
    width: 100,
    sorter: true,
    align: 'center',
    render: (count: number) => (
      <Tag color={count > 0 ? 'success' : 'default'}>{count}</Tag>
    ),
  },
  {
    title: 'Default',
    dataIndex: 'isDefault',
    key: 'isDefault',
    width: 100,
    align: 'center',
    render: (isDefault: boolean) =>
      isDefault ? <Tag color='gold'>Default</Tag> : '—',
  },
  {
    title: 'Status',
    dataIndex: 'status',
    key: 'status',
    width: 100,
    render: (status: EntityStatusEnum) => (
      <Tag color={ENTITY_STATUS_COLORS[status]}>
        {ENTITY_STATUS_LABELS[status]}
      </Tag>
    ),
  },
  {
    title: 'Created At',
    dataIndex: 'createdAt',
    key: 'createdAt',
    width: 160,
    sorter: true,
    render: (date: string) => formatDateTime(date),
  },
  {
    title: 'Actions',
    key: 'actions',
    fixed: 'right',
    width: 80,
    render: (_, record: PlaylistListItem) => {
      const menuItems: MenuProps['items'] = [
        {
          key: 'view',
          icon: <EyeOutlined />,
          label: 'View Details',
          onClick: () => onView(record.id),
        },
      ];

      // Add management actions if handlers provided
      if (onEdit || onAddTracks || onToggleStatus || onDelete) {
        menuItems.push({ type: 'divider' });
      }

      if (onEdit) {
        menuItems.push({
          key: 'edit',
          icon: <EditOutlined />,
          label: 'Edit',
          onClick: () => onEdit(record.id),
        });
      }

      if (onAddTracks) {
        menuItems.push({
          key: 'add-tracks',
          icon: <PlusOutlined />,
          label: 'Add Tracks',
          onClick: () => onAddTracks(record.id),
        });
      }

      if (onToggleStatus) {
        menuItems.push({
          key: 'toggle',
          icon: <PoweroffOutlined />,
          label: record.status === 1 ? 'Deactivate' : 'Activate',
          onClick: () => onToggleStatus(record.id),
        });
      }

      if (onDelete) {
        menuItems.push({ type: 'divider' });
        menuItems.push({
          key: 'delete',
          icon: <DeleteOutlined />,
          label: 'Delete',
          danger: true,
          onClick: () => onDelete(record.id),
        });
      }

      return (
        <Dropdown
          menu={{ items: menuItems }}
          trigger={['click']}
        >
          <Button
            type='text'
            icon={<MoreOutlined />}
          />
        </Dropdown>
      );
    },
  },
];
