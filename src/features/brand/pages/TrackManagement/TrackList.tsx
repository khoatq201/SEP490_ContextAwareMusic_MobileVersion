import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Button } from 'antd';

/**
 * Icons
 */
import { PlusOutlined } from '@ant-design/icons';

/**
 * Components
 */
import { PageHeader, DataTable, AppModal } from '@/shared/components';
import { getTrackColumns } from '@/shared/modules/tracks/components';
import {
  CreateTrackDrawer,
  EditTrackDrawer,
  TrackDetailsDrawer,
  TrackFilter as TrackFilterComponent,
} from './components';

/**
 * Hooks
 */
import {
  useTracks,
  useDeleteTrack,
  useToggleTrackStatus,
} from '@/shared/modules/tracks/hooks';

/**
 * Constants
 */
import { PAGINATION_SIZES } from '@/shared/constants';

/**
 * Types
 */
import type { TrackFilter, TrackListItem } from '@/shared/modules/tracks/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

export const TrackList = () => {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<TrackFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailsDrawerOpen, setDetailsDrawerOpen] = useState(false);
  const [selectedTrackId, setSelectedTrackId] = useState<string>();

  const { data, isLoading, refetch } = useTracks(filter);
  const deleteTrack = useDeleteTrack();
  const toggleStatus = useToggleTrackStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  const handleFilterChange = (key: keyof TrackFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<TrackListItem> | SorterResult<TrackListItem>[],
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
    setSelectedTrackId(id);
    setDetailsDrawerOpen(true);
  };

  const handleEdit = (id: string) => {
    setSelectedTrackId(id);
    setEditDrawerOpen(true);
  };

  const handleDelete = (id: string) => {
    AppModal.confirm({
      title: 'Delete Track',
      content:
        'Are you sure you want to delete this track? This action cannot be undone.',
      okText: 'Delete',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        deleteTrack.mutate(id, {
          onSuccess: () => refetch(),
        });
      },
    });
  };

  const handleToggleStatus = (id: string) => {
    AppModal.confirm({
      title: 'Toggle Track Status',
      content: 'Are you sure you want to change this track status?',
      okText: 'Confirm',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        toggleStatus.mutate(id, {
          onSuccess: () => refetch(),
        });
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
      onClick: () => navigate('/brand/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Track Management',
    },
  ];

  const columns = getTrackColumns({
    onView: handleView,
    onEdit: handleEdit,
    onDelete: handleDelete,
    onToggleStatus: handleToggleStatus,
  });

  return (
    <div>
      <PageHeader
        title='Track Library'
        breadcrumbs={breadcrumbs}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Upload Track
          </Button>
        }
      />

      <DataTable<TrackListItem>
        filter={
          <TrackFilterComponent
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
        loading={isLoading}
        rowKey='id'
        pagination={{
          current: filter.page,
          pageSize: filter.pageSize,
          total: data?.totalItems || 0,
          showSizeChanger: true,
          showTotal: (total) => `Total ${total} tracks`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
        scroll={{ x: 1400 }}
      />

      {/* Drawers */}
      <CreateTrackDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => refetch()}
      />

      <EditTrackDrawer
        open={editDrawerOpen}
        trackId={selectedTrackId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedTrackId(undefined);
        }}
        onSuccess={() => refetch()}
      />

      <TrackDetailsDrawer
        open={detailsDrawerOpen}
        trackId={selectedTrackId}
        onClose={() => {
          setDetailsDrawerOpen(false);
          setSelectedTrackId(undefined);
        }}
      />
    </div>
  );
};
