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
import {
  AddTracksDrawer,
  getPlaylistColumns,
  PlaylistDetailsDrawer,
} from '@/shared/modules/playlists/components';
import {
  PlaylistFilter as PlaylistFilterComponent,
  CreatePlaylistDrawer,
  EditPlaylistDrawer,
} from './components';

/**
 * Hooks
 */
import {
  usePlaylists,
  useDeletePlaylist,
  useTogglePlaylistStatus,
} from '@/shared/modules/playlists/hooks';
import { useStores } from '@/features/brand/hooks';
import { useMoods } from '@/shared/modules/moods/hooks';

/**
 * Constants
 */
import { PAGINATION_SIZES } from '@/shared/constants';

/**
 * Types
 */
import type {
  PlaylistFilter,
  PlaylistListItem,
} from '@/shared/modules/playlists/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

export const PlaylistList = () => {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<PlaylistFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [detailsDrawerOpen, setDetailsDrawerOpen] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [addTracksDrawerOpen, setAddTracksDrawerOpen] = useState(false);
  const [selectedPlaylistId, setSelectedPlaylistId] = useState<string>();

  const { data, isLoading, refetch } = usePlaylists(filter);
  const { data: storesData } = useStores({
    page: 1,
    pageSize: 1000,
    status: 1,
  });
  const { data: moodsData } = useMoods();

  const deletePlaylist = useDeletePlaylist();
  const toggleStatus = useTogglePlaylistStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof PlaylistFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<PlaylistListItem> | SorterResult<PlaylistListItem>[],
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
    setSelectedPlaylistId(id);
    setDetailsDrawerOpen(true);
  };

  const handleEdit = (id: string) => {
    setSelectedPlaylistId(id);
    setEditDrawerOpen(true);
  };

  const handleAddTracks = (id: string) => {
    setSelectedPlaylistId(id);
    setAddTracksDrawerOpen(true);
  };

  const handleDelete = (id: string) => {
    const playlist = data?.items.find((p) => p.id === id);

    AppModal.confirm({
      title: 'Delete Playlist',
      content: (
        <div>
          <p>
            Are you sure you want to delete playlist{' '}
            <strong>"{playlist?.name}"</strong>?
          </p>
          <p style={{ color: '#ff4d4f', marginTop: 8 }}>
            This action cannot be undone!
          </p>
        </div>
      ),
      okText: 'Delete',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        deletePlaylist.mutate(id, {
          onSuccess: () => refetch(),
        });
      },
    });
  };

  const handleToggleStatus = (id: string) => {
    const playlist = data?.items.find((p) => p.id === id);
    const action = playlist?.status === 1 ? 'deactivate' : 'activate';

    AppModal.confirm({
      title: `${action.charAt(0).toUpperCase() + action.slice(1)} Playlist`,
      content: `Are you sure you want to ${action} playlist "${playlist?.name}"?`,
      okText: action.charAt(0).toUpperCase() + action.slice(1),
      cancelText: 'Cancel',
      okButtonProps: {
        danger: playlist?.status === 1,
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
      title: 'Playlist Management',
    },
  ];

  const columns = getPlaylistColumns({
    onView: handleView,
    onEdit: handleEdit,
    onDelete: handleDelete,
    onToggleStatus: handleToggleStatus,
    onAddTracks: handleAddTracks,
  });

  // Transform stores data to options
  const storeOptions = (storesData?.items || []).map((store) => ({
    label: store.name || 'Unnamed Store',
    value: store.id,
  }));

  // Transform moods data to options
  const moodOptions = (moodsData || []).map((mood) => ({
    label: mood.name || 'Unnamed Mood',
    value: mood.id,
  }));

  return (
    <div>
      <PageHeader
        title='Playlist Management'
        breadcrumbs={breadcrumbs}
        extra={
          <Button
            type='primary'
            size='large'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Create Playlist
          </Button>
        }
      />

      {/* Filter Component */}
      <DataTable<PlaylistListItem>
        filter={
          <PlaylistFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            stores={storeOptions}
            moods={moodOptions}
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
          showTotal: (total) => `Total ${total} playlists`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
        scroll={{ x: 1400 }}
      />

      {/* Create Playlist Drawer */}
      <CreatePlaylistDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => refetch()}
      />

      {/* Edit Playlist Drawer */}
      <EditPlaylistDrawer
        open={editDrawerOpen}
        playlistId={selectedPlaylistId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedPlaylistId(undefined);
        }}
        onSuccess={() => refetch()}
      />

      {/* Details Drawer */}
      <PlaylistDetailsDrawer
        open={detailsDrawerOpen}
        playlistId={selectedPlaylistId}
        onClose={() => {
          setDetailsDrawerOpen(false);
          setSelectedPlaylistId(undefined);
        }}
      />

      {/* Add Tracks Drawer */}
      <AddTracksDrawer
        open={addTracksDrawerOpen}
        playlistId={selectedPlaylistId}
        onClose={() => {
          setAddTracksDrawerOpen(false);
          setSelectedPlaylistId(undefined);
        }}
        onSuccess={() => refetch()}
      />
    </div>
  );
};
