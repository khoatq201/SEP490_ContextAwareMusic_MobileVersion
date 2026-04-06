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
import type { BrandListItem, BrandFilter } from '@/features/admin/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

/**
 * Components
 */
import {
  AddBrandDrawer,
  EditBrandDrawer,
  getBrandColumns,
  BrandFilter as BrandFilterComponent,
  BrandDetailDrawer,
} from './components';
import { PageHeader, DataTable, AppModal } from '@/shared/components';

/**
 * Hooks
 */
import {
  useBrands,
  useDeleteBrand,
  useToggleBrandStatus,
} from '@/features/admin/hooks';

/**
 * Constants
 */
import { PAGINATION_SIZES } from '@/shared/constants';

export const BrandList = () => {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<BrandFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdat',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [addDrawerOpen, setAddDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
  const [selectedBrandId, setSelectedBrandId] = useState<string | null>(null);

  const { data, isLoading, refetch } = useBrands(filter);

  const deleteBrand = useDeleteBrand();
  const toggleBrandStatus = useToggleBrandStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof BrandFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<BrandListItem> | SorterResult<BrandListItem>[],
  ) => {
    const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;

    setFilter((prev) => ({
      ...prev,
      page: pagination.current || 1,
      pageSize: pagination.pageSize || 10,
      sortBy: currentSorter.field
        ? (String(currentSorter.field) as BrandFilter['sortBy'])
        : 'createdat',
      isAscending: currentSorter.order === 'ascend',
    }));
  };

  const handleToggleStatus = (brandId: string) => {
    const brand = data?.items.find((b) => b.id === brandId);

    AppModal.confirm({
      title: `${brand?.status === 1 ? 'Deactivate' : 'Activate'} Brand`,
      content: (
        <p>
          Are you sure you want to{' '}
          <strong>{brand?.status === 1 ? 'deactivate' : 'activate'}</strong> "
          <strong>{brand?.name}</strong>"?
        </p>
      ),
      okText: brand?.status === 1 ? 'Deactivate' : 'Activate',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: brand?.status === 1,
      },
      onOk: () => {
        toggleBrandStatus.mutate(brandId);
      },
    });
  };

  const handleView = (brandId: string) => {
    setSelectedBrandId(brandId);
    setDetailDrawerOpen(true);
  };

  const handleEdit = (brand: BrandListItem) => {
    setSelectedBrandId(brand.id);
    setEditDrawerOpen(true);
  };

  const handleDelete = (brandId: string) => {
    const brand = data?.items.find((b) => b.id === brandId);

    AppModal.confirm({
      title: 'Are you sure you want to delete this brand?',
      content: (
        <div>
          <p>
            By deleting "<strong>{brand?.name}</strong>", all associated data
            will be permanently removed.
          </p>
        </div>
      ),
      okText: 'Delete',
      cancelText: 'Cancel',
      okButtonProps: {
        danger: true,
      },
      onOk: () => {
        deleteBrand.mutate(brandId);
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
      onClick: () => navigate('/admin/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Brand Management',
    },
  ];

  const columns = getBrandColumns({
    onView: handleView,
    onEdit: handleEdit,
    onToggleStatus: handleToggleStatus,
    onDelete: handleDelete,
  });

  return (
    <div>
      <PageHeader
        title='Brand Management'
        breadcrumbs={breadcrumbs}
        seo={{
          description: 'Manage all brands in the system',
          keywords: 'brand, management, admin, cms',
        }}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setAddDrawerOpen(true)}
          >
            Add Brand
          </Button>
        }
      />

      <DataTable<BrandListItem>
        filter={
          <BrandFilterComponent
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
          showTotal: (total) => `Total ${total} brands`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
      />

      <AddBrandDrawer
        open={addDrawerOpen}
        onClose={() => setAddDrawerOpen(false)}
        onSuccess={() => {
          setAddDrawerOpen(false);
          refetch();
        }}
      />

      <EditBrandDrawer
        open={editDrawerOpen}
        brandId={selectedBrandId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedBrandId(null);
        }}
        onSuccess={() => {
          setEditDrawerOpen(false);
          setSelectedBrandId(null);
          refetch();
        }}
      />
      <BrandDetailDrawer
        open={detailDrawerOpen}
        brandId={selectedBrandId}
        onClose={() => {
          setDetailDrawerOpen(false);
          setSelectedBrandId(null);
        }}
      />
    </div>
  );
};
