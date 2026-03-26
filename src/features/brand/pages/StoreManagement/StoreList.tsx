import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router';
import { Button } from 'antd';

/**
 * Icons
 */
import { PlusOutlined } from '@ant-design/icons';

/**
 * Types
 */
import type { StoreListItem, StoreFilter } from '@/features/brand/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

/**
 * Hooks
 */
import {
  useDeleteStore,
  useStores,
  useToggleStoreStatus,
} from '@/features/brand/hooks';

/**
 * Components
 */
import { PageHeader, AppModal, DataTable } from '@/shared/components';
import {
  getStoreColumns,
  CreateStoreDrawer,
  EditStoreDrawer,
  StoreFilter as StoreFilterComponent,
  StoreDetailDrawer,
  StoreSpacesDrawer,
} from './components';

/**
 * Constants
 */
import { PAGINATION_SIZES } from '@/shared/constants';

export const StoreList = () => {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<StoreFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdat',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
  const [spacesDrawerOpen, setSpacesDrawerOpen] = useState(false);
  const [selectedStoreId, setSelectedStoreId] = useState<string | null>(null);

  const { data, isLoading, refetch } = useStores(filter);

  const toggleStatus = useToggleStoreStatus();
  const deleteStore = useDeleteStore();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof StoreFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<StoreListItem> | SorterResult<StoreListItem>[],
  ) => {
    const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;

    setFilter((prev) => ({
      ...prev,
      page: pagination.current || 1,
      pageSize: pagination.pageSize || 10,
      sortBy: currentSorter.field ? String(currentSorter.field) : 'createdat',
      isAscending: currentSorter.order === 'ascend',
    }));
  };

  const handleView = (storeId: string) => {
    setSelectedStoreId(storeId);
    setDetailDrawerOpen(true);
  };

  const handleViewSpaces = (storeId: string) => {
    setSelectedStoreId(storeId);
    setSpacesDrawerOpen(true);
  };

  const handleEdit = (store: StoreListItem) => {
    setSelectedStoreId(store.id);
    setEditDrawerOpen(true);
  };

  const handleToggleStatus = (storeId: string) => {
    const store = data?.items.find((s) => s.id === storeId);

    AppModal.confirm({
      title: 'Toggle Store Status',
      content: `Are you sure you want to change status of "${store?.name}"?`,
      okText: 'Yes',
      cancelText: 'No',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        toggleStatus.mutate(storeId);
      },
    });
  };

  const handleDelete = (storeId: string) => {
    const store = data?.items.find((s) => s.id === storeId);

    AppModal.confirm({
      title: 'Delete Store',
      content: `Are you sure you want to delete "${store?.name}"? This action cannot be undone.`,
      okText: 'Delete',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        deleteStore.mutate(storeId);
      },
    });
  };

  const handleReset = () => {
    setFilter({
      page: 1,
      pageSize: 10,
      sortBy: 'createdat',
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
      title: 'Store Management',
    },
  ];

  const columns = getStoreColumns({
    onView: handleView,
    onViewSpaces: handleViewSpaces,
    onEdit: handleEdit,
    onToggleStatus: handleToggleStatus,
    onDelete: handleDelete,
  });

  // Extract unique cities from data
  const cityOptions = useMemo(() => {
    const cities = new Set(
      data?.items.filter((s) => s.city).map((s) => s.city!),
    );
    return Array.from(cities)
      .sort()
      .map((city) => ({ label: city, value: city }));
  }, [data?.items]);

  return (
    <div>
      <PageHeader
        title='Store Management'
        breadcrumbs={breadcrumbs}
        seo={{
          description: 'Manage all stores in your brand',
          keywords: 'store, management, brand, locations',
        }}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Add Store
          </Button>
        }
      />

      <DataTable<StoreListItem>
        filter={
          <StoreFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            cities={cityOptions}
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
          showTotal: (total) => `Total ${total} stores`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
      />

      <CreateStoreDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => {
          setCreateDrawerOpen(false);
          refetch();
        }}
      />

      <EditStoreDrawer
        open={editDrawerOpen}
        storeId={selectedStoreId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedStoreId(null);
        }}
        onSuccess={() => {
          setEditDrawerOpen(false);
          setSelectedStoreId(null);
          refetch();
        }}
      />

      <StoreDetailDrawer
        open={detailDrawerOpen}
        storeId={selectedStoreId ?? undefined}
        onClose={() => {
          setDetailDrawerOpen(false);
          setSelectedStoreId(null);
        }}
      />

      <StoreSpacesDrawer
        open={spacesDrawerOpen}
        storeId={selectedStoreId}
        onClose={() => {
          setSpacesDrawerOpen(false);
          setSelectedStoreId(null);
        }}
      />
    </div>
  );
};

export default StoreList;
