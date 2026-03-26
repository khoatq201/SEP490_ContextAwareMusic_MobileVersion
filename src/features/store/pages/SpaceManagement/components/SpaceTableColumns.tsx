import { Tag, Dropdown, Button } from 'antd';
import type { MenuProps } from 'antd';
import {
  EyeOutlined,
  EditOutlined,
  DeleteOutlined,
  PoweroffOutlined,
  MoreOutlined,
  SoundOutlined,
  QrcodeOutlined,
  UnorderedListOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import dayjs from 'dayjs';

/**
 * Types
 */
import type { SpaceListItem } from '@/shared/modules/spaces/types';
import { EntityStatusEnum } from '@/shared/types';
import { SpaceTypeEnum } from '@/shared/modules/spaces/types';

/**
 * Constants
 */
import {
  SPACE_TYPE_LABELS,
  SPACE_TYPE_COLORS,
} from '@/features/store/constants';

type SpaceColumnActions = {
  onView: (id: string) => void;
  onManageMusic: (id: string) => void;
  onManageQueue: (id: string) => void;
  onPairDevice: (id: string) => void;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
  onToggleStatus: (id: string) => void;
};

export const getSpaceColumns = ({
  onView,
  onManageMusic,
  onManageQueue,
  onPairDevice,
  onEdit,
  onDelete,
  onToggleStatus,
}: SpaceColumnActions): ColumnsType<SpaceListItem> => [
  {
    title: 'No.',
    key: 'index',
    width: 70,
    render: (_text, _record, index) => index + 1,
  },
  {
    title: 'Space Name',
    dataIndex: 'name',
    key: 'name',
    width: 200,
    fixed: 'left',
    sorter: true,
  },
  {
    title: 'Type',
    dataIndex: 'type',
    key: 'type',
    width: 120,
    render: (type: SpaceTypeEnum) => (
      <Tag color={SPACE_TYPE_COLORS[type]}>{SPACE_TYPE_LABELS[type]}</Tag>
    ),
  },
  {
    title: 'Description',
    dataIndex: 'description',
    key: 'description',
    width: 250,
    ellipsis: true,
    render: (description?: string) => description || '-',
  },
  {
    title: 'Status',
    dataIndex: 'status',
    key: 'status',
    width: 100,
    render: (status: EntityStatusEnum) => (
      <Tag color={status === EntityStatusEnum.Active ? 'success' : 'default'}>
        {status === EntityStatusEnum.Active ? 'Active' : 'Inactive'}
      </Tag>
    ),
  },
  {
    title: 'Created At',
    dataIndex: 'createdAt',
    key: 'createdAt',
    width: 150,
    sorter: true,
    render: (date: string) => dayjs(date).format('MMM D, YYYY'),
  },
  {
    title: 'Updated At',
    dataIndex: 'updatedAt',
    key: 'updatedAt',
    width: 150,
    sorter: true,
    render: (date: string) => dayjs(date).format('MMM D, YYYY'),
  },
  {
    title: 'Actions',
    key: 'actions',
    fixed: 'right',
    width: 80,
    render: (_, record) => {
      const items: MenuProps['items'] = [
        {
          key: 'view',
          icon: <EyeOutlined />,
          label: 'View Details',
          onClick: () => onView(record.id),
        },
        {
          key: 'manage-music',
          icon: <SoundOutlined />,
          label: 'Manage Music',
          onClick: () => onManageMusic(record.id),
        },
        {
          key: 'manage-queue',
          icon: <UnorderedListOutlined />,
          label: 'Manage Queue',
          onClick: () => onManageQueue(record.id),
        },
        {
          key: 'pair-device',
          icon: <QrcodeOutlined />,
          label: 'Pair Device',
          onClick: () => onPairDevice(record.id),
        },
        {
          key: 'edit',
          icon: <EditOutlined />,
          label: 'Edit Space',
          onClick: () => onEdit(record.id),
        },
        {
          type: 'divider',
        },
        {
          key: 'toggle-status',
          icon: <PoweroffOutlined />,
          label:
            record.status === EntityStatusEnum.Active
              ? 'Deactivate'
              : 'Activate',
          onClick: () => onToggleStatus(record.id),
          danger: record.status === EntityStatusEnum.Active,
        },
        {
          type: 'divider',
        },
        {
          key: 'delete',
          icon: <DeleteOutlined />,
          label: 'Delete Space',
          onClick: () => onDelete(record.id),
          danger: true,
        },
      ];

      return (
        <Dropdown
          menu={{ items }}
          trigger={['click']}
          placement='bottomRight'
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
