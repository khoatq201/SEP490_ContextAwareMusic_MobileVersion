import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router';
import { Tabs } from 'antd';
import type { ColumnsType } from 'antd/es/table';

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
import { useBlockedTracksForAdmin } from '@/shared/modules/tracks/hooks';
import { useBrands } from '@/features/admin/hooks';

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
  const [activeTabKey, setActiveTabKey] = useState<'all' | 'blocked'>('all');

  const [allFilter, setAllFilter] = useState<TrackFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [blockedFilter, setBlockedFilter] = useState<TrackFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'brandId',
    isAscending: true,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [detailsDrawerOpen, setDetailsDrawerOpen] = useState(false);
  const [selectedTrackId, setSelectedTrackId] = useState<string>();

  const {
    data: allData,
    isLoading: isAllLoading,
    refetch: refetchAll,
  } = useTracks(allFilter);
  const {
    data: blockedData,
    isLoading: isBlockedLoading,
    refetch: refetchBlocked,
  } = useBlockedTracksForAdmin(blockedFilter);
  const { data: brandsData } = useBrands({
    page: 1,
    pageSize: 500,
    sortBy: 'name',
    isAscending: true,
  });

  const currentFilter = activeTabKey === 'all' ? allFilter : blockedFilter;
  const setCurrentFilter =
    activeTabKey === 'all' ? setAllFilter : setBlockedFilter;
  const currentData = activeTabKey === 'all' ? allData : blockedData;
  const isCurrentLoading =
    activeTabKey === 'all' ? isAllLoading : isBlockedLoading;

  const brandOptions = useMemo(
    () =>
      (brandsData?.items || []).map((brand) => ({
        label: brand.name,
        value: brand.id,
      })),
    [brandsData?.items],
  );

  const brandNameById = useMemo(() => {
    const map = new Map<string, string>();
    (brandsData?.items || []).forEach((brand) => {
      map.set(brand.id, brand.name);
    });
    return map;
  }, [brandsData?.items]);

  const handleSearch = (value: string) => {
    setCurrentFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  const handleFilterChange = (
    key: keyof TrackFilter,
    value: TrackFilter[keyof TrackFilter] | undefined,
  ) => {
    setCurrentFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<TrackListItem> | SorterResult<TrackListItem>[],
  ) => {
    const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;
    const defaultSortBy = activeTabKey === 'blocked' ? 'brandId' : 'createdAt';
    const defaultIsAscending = activeTabKey === 'blocked';

    setCurrentFilter((prev) => ({
      ...prev,
      page: pagination.current || 1,
      pageSize: pagination.pageSize || 10,
      sortBy: currentSorter.field ? String(currentSorter.field) : defaultSortBy,
      isAscending: currentSorter.order
        ? currentSorter.order === 'ascend'
        : defaultIsAscending,
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
    const defaultSortBy = activeTabKey === 'blocked' ? 'brandId' : 'createdAt';
    const defaultIsAscending = activeTabKey === 'blocked';

    setCurrentFilter({
      page: 1,
      pageSize: 10,
      sortBy: defaultSortBy,
      isAscending: defaultIsAscending,
    });
  };

  const breadcrumbs = [
    {
      title: 'Dashboard',
      onClick: () => navigate('/admin/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Track Library',
    },
  ];

  const columns = useMemo(() => {
    const baseColumns = getTrackColumns({
      onView: handleView,
      onPreview: handlePreview,
    });

    if (activeTabKey !== 'blocked') {
      return baseColumns;
    }

    const brandColumn: ColumnsType<TrackListItem>[number] = {
      title: 'Brand',
      dataIndex: 'brandId',
      key: 'brandId',
      width: 180,
      sorter: true,
      render: (brandId?: string) =>
        brandId ? brandNameById.get(brandId) || brandId : '-',
    };

    const insertAt = Math.min(3, baseColumns.length);
    return [
      ...baseColumns.slice(0, insertAt),
      brandColumn,
      ...baseColumns.slice(insertAt),
    ];
  }, [activeTabKey, brandNameById, handleView, handlePreview]);

  return (
    <div>
      <PageHeader
        title='Track Library'
        breadcrumbs={breadcrumbs}
      />

      {/* Filter Component */}
      <Tabs
        activeKey={activeTabKey}
        onChange={(key) => setActiveTabKey(key as 'all' | 'blocked')}
        items={[
          {
            key: 'all',
            label: 'All Tracks',
          },
          {
            key: 'blocked',
            label: 'Blocked Tracks',
          },
        ]}
      />

      <DataTable<TrackListItem>
        filter={
          <TrackFilterComponent
            filter={currentFilter}
            showAdvanced={showFilters}
            brandOptions={brandOptions}
            onSearch={handleSearch}
            onFilterChange={handleFilterChange}
            onToggleAdvanced={() => setShowFilters(!showFilters)}
            onRefresh={() => {
              if (activeTabKey === 'all') {
                void refetchAll();
                return;
              }

              void refetchBlocked();
            }}
            onReset={handleReset}
          />
        }
        columns={columns}
        dataSource={currentData?.items || []}
        loading={isCurrentLoading}
        rowKey='id'
        pagination={{
          current: currentFilter.page,
          pageSize: currentFilter.pageSize,
          total: currentData?.totalItems || 0,
          showSizeChanger: true,
          showTotal: (total) =>
            activeTabKey === 'all'
              ? `Total ${total} tracks`
              : `Total ${total} blocked tracks`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setCurrentFilter((prev) => ({ ...prev, page, pageSize: size }));
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
