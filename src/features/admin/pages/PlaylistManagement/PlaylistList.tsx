import { useState } from 'react';
import { useNavigate } from 'react-router';

/**
 * Components
 */
import { PageHeader, DataTable } from '@/shared/components';
import {
  getPlaylistColumns,
  PlaylistDetailsDrawer,
} from '@/shared/modules/playlists/components';
import { PlaylistFilter as PlaylistFilterComponent } from './components';

/**
 * Hooks
 */
import { usePlaylists } from '@/shared/modules/playlists/hooks';
import { useBrands } from '@/features/admin/hooks';
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
  const [selectedPlaylistId, setSelectedPlaylistId] = useState<string>();

  const { data, isLoading, refetch } = usePlaylists(filter);
  const { data: brandsData } = useBrands({ page: 1, pageSize: 1000 });
  const { data: moodsData } = useMoods();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

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
      onClick: () => navigate('/admin/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Playlist Library',
    },
  ];

  const columns = getPlaylistColumns({
    onView: handleView,
  });

  const brandOptions = (brandsData?.items || []).map((brand) => ({
    label: brand.name || 'Unnamed Brand',
    value: brand.id,
  }));

  // Transform moods data to options
  const moodOptions = (moodsData || []).map((mood) => ({
    label: mood.name || 'Unnamed Mood',
    value: mood.id,
  }));

  return (
    <div>
      <PageHeader
        title='Playlist Library'
        breadcrumbs={breadcrumbs}
      />

      {/* Filter Component */}
      <DataTable<PlaylistListItem>
        filter={
          <PlaylistFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            brands={brandOptions}
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

      {/* Details Drawer (View Only) */}
      <PlaylistDetailsDrawer
        open={detailsDrawerOpen}
        playlistId={selectedPlaylistId}
        onClose={() => {
          setDetailsDrawerOpen(false);
          setSelectedPlaylistId(undefined);
        }}
        readOnly
      />
    </div>
  );
};
