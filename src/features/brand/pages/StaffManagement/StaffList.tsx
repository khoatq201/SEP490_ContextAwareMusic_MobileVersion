import { useState } from 'react';
import { Button, Table } from 'antd';
import { useNavigate } from 'react-router';

/**
 * Icons
 */
import { PlusOutlined } from '@ant-design/icons';

/**
 * Types
 */
import type { StaffListItem, StaffFilter } from '@/features/brand/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

/**
 * Hooks
 */
import { useStaff, useToggleStaffStatus } from '@/features/brand/hooks';
import { useStores } from '@/features/brand/hooks';

/**
 * Components
 */
import { DataTable, PageHeader, AppModal } from '@/shared/components';
import {
  getGroupColumns,
  getExpandedColumns,
  CreateStaffDrawer,
  EditStaffDrawer,
  AssignStaffStoreModal,
  ResetPasswordModal,
  StaffFilter as StaffFilterComponent,
  StaffDetailDrawer,
} from './components';

/**
 * Utils
 */
import { groupStaffByStore } from '@/features/brand/utils';
import { PAGINATION_SIZES } from '@/shared/constants';

export const StaffList = () => {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<StaffFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
  const [assignStoreModalOpen, setAssignStoreModalOpen] = useState(false);
  const [resetPasswordModalOpen, setResetPasswordModalOpen] = useState(false);
  const [selectedStaffId, setSelectedStaffId] = useState<string | null>(null);

  const { data, isLoading, refetch } = useStaff(filter);
  const { data: storesData } = useStores({ pageSize: 100 });

  const toggleStatus = useToggleStaffStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof StaffFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<StaffListItem> | SorterResult<StaffListItem>[],
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

  const handleEdit = (staffId: string) => {
    setSelectedStaffId(staffId);
    setEditDrawerOpen(true);
  };

  const handleAssignStore = (staffId: string) => {
    setSelectedStaffId(staffId);
    setAssignStoreModalOpen(true);
  };

  const handleResetPassword = (staffId: string) => {
    setSelectedStaffId(staffId);
    setResetPasswordModalOpen(true);
  };

  const handleToggleStatus = (staffId: string) => {
    const staff = data?.items.find((s) => s.id === staffId);
    const action = staff?.status === 1 ? 'deactivate' : 'activate';

    AppModal.confirm({
      title: `${action.charAt(0).toUpperCase() + action.slice(1)} Staff`,
      content: `Are you sure you want to ${action} "${staff?.fullName}"?`,
      okText: action.charAt(0).toUpperCase() + action.slice(1),
      cancelText: 'Cancel',
      okButtonProps: {
        danger: staff?.status === 1,
      },
      onOk: () => {
        toggleStatus.mutate(staffId, {
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

  const handleView = (staffId: string) => {
    setSelectedStaffId(staffId);
    setDetailDrawerOpen(true);
  };

  const breadcrumbs = [
    {
      title: 'Dashboard',
      onClick: () => navigate('/brand/dashboard'),
      className: 'cursor-pointer',
    },
    {
      title: 'Staff Management',
    },
  ];

  // Column handlers
  const columnHandlers = {
    onView: handleView,
    onEdit: handleEdit,
    onAssignStore: handleAssignStore,
    onResetPassword: handleResetPassword,
    onToggleStatus: handleToggleStatus,
  };

  // Separate columns for group and expanded rows
  const groupColumns = getGroupColumns();
  const expandedColumns = getExpandedColumns(columnHandlers);

  // Transform stores data to options
  const storeOptions = (storesData?.items || []).map((store) => ({
    label: store.name,
    value: store.id,
  }));

  // Group staff by store
  const groupedData = groupStaffByStore(data?.items || []);

  return (
    <div>
      <PageHeader
        title='Staff Management'
        breadcrumbs={breadcrumbs}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Add Staff
          </Button>
        }
        seo={{
          description: 'Manage store staff members and assignments',
          keywords: 'staff, management, store, employees',
        }}
      />

      <DataTable<StaffListItem>
        filter={
          <StaffFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            stores={storeOptions}
            onSearch={handleSearch}
            onFilterChange={handleFilterChange}
            onToggleAdvanced={() => setShowFilters(!showFilters)}
            onRefresh={() => refetch()}
            onReset={handleReset}
          />
        }
        columns={groupColumns}
        dataSource={groupedData}
        loading={isLoading}
        rowKey='id'
        pagination={{
          current: filter.page,
          pageSize: filter.pageSize,
          total: data?.totalItems || 0,
          showSizeChanger: true,
          showTotal: (total) => `Total ${total} staff members`,
          pageSizeOptions: PAGINATION_SIZES,
          onChange: (page, size) => {
            setFilter((prev) => ({ ...prev, page, pageSize: size }));
          },
        }}
        onChange={handleTableChange}
        expandable={{
          expandedRowRender: (record) => {
            if (!record.children || record.children.length === 0) {
              return null;
            }
            return (
              <div style={{ padding: '0 48px 16px' }}>
                <Table<StaffListItem>
                  columns={expandedColumns}
                  dataSource={record.children}
                  rowKey='id'
                  pagination={false}
                />
              </div>
            );
          },
          rowExpandable: (record) =>
            !!record.children && record.children.length > 0,
          defaultExpandAllRows: false,
          childrenColumnName: '__children_placeholder__',
        }}
      />

      <CreateStaffDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => {
          setCreateDrawerOpen(false);
          refetch();
        }}
      />

      <EditStaffDrawer
        open={editDrawerOpen}
        staffId={selectedStaffId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedStaffId(null);
        }}
        onSuccess={() => {
          setEditDrawerOpen(false);
          setSelectedStaffId(null);
          refetch();
        }}
      />

      <AssignStaffStoreModal
        open={assignStoreModalOpen}
        staffId={selectedStaffId}
        onClose={() => {
          setAssignStoreModalOpen(false);
          setSelectedStaffId(null);
        }}
        onSuccess={() => {
          setAssignStoreModalOpen(false);
          setSelectedStaffId(null);
          refetch();
        }}
      />

      <ResetPasswordModal
        open={resetPasswordModalOpen}
        staffId={selectedStaffId}
        onClose={() => {
          setResetPasswordModalOpen(false);
          setSelectedStaffId(null);
        }}
        onSuccess={() => {
          setResetPasswordModalOpen(false);
          setSelectedStaffId(null);
        }}
      />

      <StaffDetailDrawer
        open={detailDrawerOpen}
        staffId={selectedStaffId}
        onClose={() => {
          setDetailDrawerOpen(false);
          setSelectedStaffId(null);
        }}
      />
    </div>
  );
};

export default StaffList;
