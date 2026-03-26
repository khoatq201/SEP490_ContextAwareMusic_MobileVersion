import { useState } from 'react';
import { Button } from 'antd';
import { useNavigate } from 'react-router';

/**
 * Icons
 */
import { PlusOutlined } from '@ant-design/icons';

/**
 * Types
 */
import type { SpaceListItem, SpaceFilter } from '@/shared/modules/spaces/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

/**
 * Hooks
 */
import {
  useSpaces,
  useDeleteSpace,
  useToggleSpaceStatus,
} from '@/shared/modules/spaces/hooks';
import { useAuth } from '@/providers';

/**
 * Components
 */
import { DataTable, PageHeader, AppModal } from '@/shared/components';
import {
  getSpaceColumns,
  CreateSpaceDrawer,
  EditSpaceDrawer,
  SpaceFilter as SpaceFilterComponent,
  SpaceDetailDrawer,
  SpaceMusicDrawer,
} from './components';
import {
  PairDeviceModal,
  QueueManagementDrawer,
} from '@/shared/modules/cams/components';

/**
 * Constants
 */
import { PAGINATION_SIZES } from '@/shared/constants';

export const SpaceList = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [filter, setFilter] = useState<SpaceFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailsDrawerOpen, setDetailsDrawerOpen] = useState(false);
  const [musicDrawerOpen, setMusicDrawerOpen] = useState(false);
  const [queueDrawerOpen, setQueueDrawerOpen] = useState(false);
  const [pairDeviceModalOpen, setPairDeviceModalOpen] = useState(false);
  const [selectedSpaceId, setSelectedSpaceId] = useState<string | null>(null);

  const { data, isLoading, refetch } = useSpaces(filter);

  const deleteSpace = useDeleteSpace();
  const toggleStatus = useToggleSpaceStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof SpaceFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<SpaceListItem> | SorterResult<SpaceListItem>[],
  ) => {
    const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;

    setFilter((prev) => ({
      ...prev,
      page: pagination.current || 1,
      pageSize: pagination.pageSize || 10,
      sortBy: currentSorter.field ? String(currentSorter.field) : 'createdAt',
      isAscending: currentSorter.order === 'ascend',
    }));
  };

  const handleView = (id: string) => {
    setSelectedSpaceId(id);
    setDetailsDrawerOpen(true);
  };

  const handleManageMusic = (id: string) => {
    setSelectedSpaceId(id);
    setMusicDrawerOpen(true);
  };

  const handleManageQueue = (id: string) => {
    setSelectedSpaceId(id);
    setQueueDrawerOpen(true);
  };

  const handlePairDevice = (id: string) => {
    setSelectedSpaceId(id);
    setPairDeviceModalOpen(true);
  };

  const handleEdit = (spaceId: string) => {
    setSelectedSpaceId(spaceId);
    setEditDrawerOpen(true);
  };

  const handleDelete = (spaceId: string) => {
    const space = data?.items.find((s) => s.id === spaceId);

    AppModal.confirm({
      title: 'Delete Space',
      content: `Are you sure you want to delete "${space?.name}"? This action cannot be undone.`,
      okText: 'Yes, Delete',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        deleteSpace.mutate(spaceId);
      },
    });
  };

  const handleToggleStatus = (spaceId: string) => {
    const space = data?.items.find((s) => s.id === spaceId);
    const action = space?.status === 1 ? 'deactivate' : 'activate';

    AppModal.confirm({
      title: 'Toggle Space Status',
      content: `Are you sure you want to ${action} "${space?.name}"?`,
      okText: action.charAt(0).toUpperCase() + action.slice(1),
      cancelText: 'Cancel',
      okButtonProps: {
        danger: space?.status === 1,
      },
      onOk: () => {
        toggleStatus.mutate(spaceId);
      },
    });
  };

  const handleReset = () => {
    setFilter({
      page: 1,
      pageSize: 10,
      sortBy: 'createdAt',
      isAscending: false,
    });
  };

  const breadcrumbs = [
    {
      title: 'Dashboard',
      onClick: () => navigate('/store/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Space Management',
    },
  ];

  const columns = getSpaceColumns({
    onView: handleView,
    onManageMusic: handleManageMusic,
    onManageQueue: handleManageQueue,
    onPairDevice: handlePairDevice,
    onEdit: handleEdit,
    onDelete: handleDelete,
    onToggleStatus: handleToggleStatus,
  });

  return (
    <div>
      <PageHeader
        title='Space Management'
        breadcrumbs={breadcrumbs}
        seo={{
          description: 'Manage all spaces in your store',
          keywords: 'space, management, store, locations',
        }}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Create Space
          </Button>
        }
      />

      <DataTable<SpaceListItem>
        filter={
          <SpaceFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            onSearch={handleSearch}
            onFilterChange={handleFilterChange}
            onToggleAdvanced={() => setShowFilters(!showFilters)}
            onRefresh={() => refetch()}
            onReset={handleReset}
          />
        }
        columns={columns}
        dataSource={data?.items || []}
        rowKey='id'
        loading={isLoading}
        pagination={{
          current: filter.page,
          pageSize: filter.pageSize,
          total: data?.totalItems || 0,
          showSizeChanger: true,
          showTotal: (total) => `Total ${total} spaces`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
      />

      <CreateSpaceDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => {
          setCreateDrawerOpen(false);
          refetch();
        }}
      />

      <EditSpaceDrawer
        open={editDrawerOpen}
        spaceId={selectedSpaceId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedSpaceId(null);
        }}
        onSuccess={() => {
          setEditDrawerOpen(false);
          setSelectedSpaceId(null);
          refetch();
        }}
      />

      <SpaceDetailDrawer
        open={detailsDrawerOpen}
        spaceId={selectedSpaceId ?? undefined}
        onClose={() => {
          setDetailsDrawerOpen(false);
          setSelectedSpaceId(null);
        }}
      />

      <SpaceMusicDrawer
        open={musicDrawerOpen}
        spaceId={selectedSpaceId}
        storeId={user?.storeId || ''}
        onClose={() => {
          setMusicDrawerOpen(false);
          setSelectedSpaceId(null);
        }}
      />

      <QueueManagementDrawer
        open={queueDrawerOpen}
        spaceId={selectedSpaceId || ''}
        storeId={user?.storeId || ''}
        onClose={() => {
          setQueueDrawerOpen(false);
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
    </div>
  );
};

export default SpaceList;
