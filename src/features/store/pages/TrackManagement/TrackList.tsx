import { useState } from 'react';
import { useNavigate } from 'react-router';

/**
 * Components
 */
import { PageHeader, DataTable } from '@/shared/components';
import { getTrackColumns } from '@/shared/modules/tracks/components';
import {
  TrackDetailsDrawer,
  TrackFilter as TrackFilterComponent,
} from './components';

/**
 * Hooks
 */
import { useTracks } from '@/shared/modules/tracks/hooks';

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
  const [detailsDrawerOpen, setDetailsDrawerOpen] = useState(false);
  const [selectedTrackId, setSelectedTrackId] = useState<string>();

  const { data, isLoading, refetch } = useTracks(filter);

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

  const handlePreview = (id: string) => {
    setSelectedTrackId(id);
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
      onClick: () => navigate('/store/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Track Library',
    },
  ];

  const columns = getTrackColumns({
    onView: handleView,
    onPreview: handlePreview,
  });

  return (
    <div>
      <PageHeader
        title='Track Library'
        breadcrumbs={breadcrumbs}
      />

      {/* Filter Component */}
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

      {/* Details Drawer (View Only) */}
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
