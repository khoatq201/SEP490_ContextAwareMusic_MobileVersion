import { useState } from 'react';
import { Drawer, Typography, Table, Button, Space, Tag, Empty } from 'antd';
import { SoundOutlined, QrcodeOutlined } from '@ant-design/icons';
import { useSpaces } from '@/shared/modules/spaces/hooks';
import { SpaceMusicDrawer } from '@/features/store/pages/SpaceManagement/components';
import { PairDeviceModal } from '@/shared/modules/cams/components';
import type { SpaceListItem, SpaceFilter } from '@/shared/modules/spaces/types';
import { EntityStatusEnum } from '@/shared/types';
import { DRAWER_WIDTHS } from '@/config';

const { Text } = Typography;

interface StoreSpacesDrawerProps {
  open: boolean;
  storeId: string | null;
  storeName?: string;
  onClose: () => void;
}

/**
 * StoreSpacesDrawer - Hiển thị danh sách spaces của store cho Brand role
 * Brand có thể xem spaces và quản lý nhạc cho từng space
 */
export const StoreSpacesDrawer = ({
  open,
  storeId,
  onClose,
}: StoreSpacesDrawerProps) => {
  const [musicDrawerOpen, setMusicDrawerOpen] = useState(false);
  const [pairDeviceModalOpen, setPairDeviceModalOpen] = useState(false);
  const [selectedSpaceId, setSelectedSpaceId] = useState<string | null>(null);

  // Fetch spaces for this store
  const filter: SpaceFilter = {
    page: 1,
    pageSize: 100,
    storeId: storeId || undefined,
    status: EntityStatusEnum.Active,
  };

  const { data: spacesData, isLoading } = useSpaces(filter, open && !!storeId);

  const handleManageMusic = (spaceId: string) => {
    setSelectedSpaceId(spaceId);
    setMusicDrawerOpen(true);
  };

  const handlePairDevice = (spaceId: string) => {
    setSelectedSpaceId(spaceId);
    setPairDeviceModalOpen(true);
  };

  const columns = [
    {
      title: 'No.',
      key: 'index',
      width: 60,
      render: (_: unknown, __: SpaceListItem, index: number) => index + 1,
    },
    {
      title: 'Space Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => <Text strong>{name}</Text>,
    },
    {
      title: 'Type',
      dataIndex: 'type',
      key: 'type',
      render: (type: number) => {
        const typeLabels: Record<number, string> = {
          1: 'Indoor',
          2: 'Outdoor',
          3: 'Private',
        };
        return <Tag>{typeLabels[type] || 'Unknown'}</Tag>;
      },
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: EntityStatusEnum) => (
        <Tag color={status === EntityStatusEnum.Active ? 'success' : 'default'}>
          {status === EntityStatusEnum.Active ? 'Active' : 'Inactive'}
        </Tag>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 200,
      render: (_: unknown, record: SpaceListItem) => (
        <Space>
          <Button
            type='primary'
            icon={<SoundOutlined />}
            onClick={() => handleManageMusic(record.id)}
          >
            Manage Music
          </Button>
          <Button
            icon={<QrcodeOutlined />}
            onClick={() => handlePairDevice(record.id)}
          >
            Pair Device
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <>
      <Drawer
        closeIcon={null}
        title='Spaces'
        open={open}
        onClose={onClose}
        width={DRAWER_WIDTHS.medium}
        destroyOnClose
      >
        {!spacesData?.items.length && !isLoading ? (
          <Empty description='No spaces found in this store' />
        ) : (
          <Space
            direction='vertical'
            style={{ width: '100%' }}
            size='large'
          >
            <Text type='secondary'>
              Select a space to manage its music playback
            </Text>
            <Table
              columns={columns}
              dataSource={spacesData?.items || []}
              rowKey='id'
              loading={isLoading}
              pagination={false}
            />
          </Space>
        )}
      </Drawer>

      <SpaceMusicDrawer
        open={musicDrawerOpen}
        spaceId={selectedSpaceId}
        storeId={storeId || ''}
        onClose={() => {
          setMusicDrawerOpen(false);
          setSelectedSpaceId(null);
        }}
      />

      <PairDeviceModal
        open={pairDeviceModalOpen}
        spaceId={selectedSpaceId}
        onClose={() => {
          setPairDeviceModalOpen(false);
          setSelectedSpaceId(null);
        }}
      />
    </>
  );
};
