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
import type { AccountListItem, AccountFilter } from '@/features/admin/types';
import type { TablePaginationConfig } from 'antd';
import type { FilterValue, SorterResult } from 'antd/es/table/interface';

/**
 * Components
 */
import {
  CreateAccountDrawer,
  EditAccountDrawer,
  ResetPasswordModal,
  AssignBrandModal,
  getGroupColumns,
  getExpandedColumns,
  AccountFilter as AccountFilterComponent,
  AccountDetailDrawer,
} from './components';
import { PageHeader, DataTable, AppModal } from '@/shared/components';

/**
 * Hooks
 */
import {
  useAccounts,
  useToggleAccountStatus,
  useTransferBrandOwnership,
} from '@/features/admin/hooks';
import { useBrands } from '@/features/admin/hooks';

/**
 * Utils
 */
import { groupAccountsByBrand } from '@/features/admin/utils';
import { PAGINATION_SIZES } from '@/shared/constants';

export const AccountList = () => {
  const navigate = useNavigate();
  const transferOwnership = useTransferBrandOwnership();
  const [filter, setFilter] = useState<AccountFilter>({
    page: 1,
    pageSize: 10,
    sortBy: 'createdAt',
    isAscending: false,
  });

  const [showFilters, setShowFilters] = useState(false);
  const [createDrawerOpen, setCreateDrawerOpen] = useState(false);
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
  const [resetPasswordModalOpen, setResetPasswordModalOpen] = useState(false);
  const [assignBrandModalOpen, setAssignBrandModalOpen] = useState(false);
  const [selectedAccountId, setSelectedAccountId] = useState<string | null>(
    null,
  );

  const { data, isLoading, refetch } = useAccounts(filter);
  const { data: brandsData } = useBrands({ pageSize: 100 });

  const toggleStatus = useToggleAccountStatus();

  const handleSearch = (value: string) => {
    setFilter((prev) => ({ ...prev, search: value, page: 1 }));
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const handleFilterChange = (key: keyof AccountFilter, value: any) => {
    setFilter((prev) => ({ ...prev, [key]: value, page: 1 }));
  };

  const handleTableChange = (
    pagination: TablePaginationConfig,
    _filters: Record<string, FilterValue | null>,
    sorter: SorterResult<AccountListItem> | SorterResult<AccountListItem>[],
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

  const handleView = (accountId: string) => {
    setSelectedAccountId(accountId);
    setDetailDrawerOpen(true);
  };

  const handleEdit = (account: AccountListItem) => {
    setSelectedAccountId(account.id);
    setEditDrawerOpen(true);
  };

  const handleToggleStatus = (accountId: string) => {
    const account = data?.items.find((a) => a.id === accountId);
    const action = account?.status === 1 ? 'deactivate' : 'activate';

    AppModal.confirm({
      title: `${action.charAt(0).toUpperCase() + action.slice(1)} Account`,
      content: `Are you sure you want to ${action} account "${account?.fullName}"?`,
      okText: action.charAt(0).toUpperCase() + action.slice(1),
      cancelText: 'Cancel',
      okButtonProps: {
        danger: account?.status === 1,
      },
      onOk: () => {
        toggleStatus.mutate(accountId, {
          onSuccess: () => refetch(),
        });
      },
    });
  };

  const handleTransferOwnership = (accountId: string) => {
    const account = data?.items.find((a) => a.id === accountId);
    if (!account || !account.brandId) return;

    AppModal.confirm({
      title: 'Transfer Brand Ownership',
      content: (
        <span>
          Are you sure you want to transfer <b>Primary Owner</b> of brand{' '}
          <b>{account.brandName}</b> to <b>{account.fullName}</b>?
        </span>
      ),
      okText: 'Transfer',
      cancelText: 'Cancel',
      okButtonProps: { type: 'primary', danger: true },
      onOk: () => {
        transferOwnership.mutate(
          { id: account.brandId!, newOwnerId: accountId },
          {
            onSuccess: () => {
              refetch();
            },
          },
        );
      },
    });
  };

  const handleResetPassword = (accountId: string) => {
    setSelectedAccountId(accountId);
    setResetPasswordModalOpen(true);
  };

  const handleAssignBrand = (accountId: string) => {
    setSelectedAccountId(accountId);
    setAssignBrandModalOpen(true);
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
      title: 'Manager Management',
    },
  ];

  // Column handlers
  const columnHandlers = {
    onView: handleView,
    onEdit: handleEdit,
    onToggleStatus: handleToggleStatus,
    onResetPassword: handleResetPassword,
    onAssignBrand: handleAssignBrand,
    onTransferOwnership: handleTransferOwnership,
  };

  // Separate columns for group and expanded rows
  const groupColumns = getGroupColumns();
  const expandedColumns = getExpandedColumns(columnHandlers);

  // Transform brands data to options
  const brandOptions = (brandsData?.items || []).map((brand) => ({
    label: brand.name,
    value: brand.id,
  }));

  // Group accounts by brand using lodash
  const groupedData = groupAccountsByBrand(data?.items || []);

  return (
    <div>
      <PageHeader
        title='Manager Management'
        breadcrumbs={breadcrumbs}
        extra={
          <Button
            size='large'
            type='primary'
            icon={<PlusOutlined />}
            onClick={() => setCreateDrawerOpen(true)}
          >
            Create Account
          </Button>
        }
        seo={{
          description: 'Manage brand manager accounts and permissions',
          keywords: 'brand manager, accounts, users, management',
        }}
      />

      <DataTable<AccountListItem>
        filter={
          <AccountFilterComponent
            filter={filter}
            showAdvanced={showFilters}
            brands={brandOptions}
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
          showTotal: (total) => `Total ${total} accounts`,
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
                <Table<AccountListItem>
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

      <CreateAccountDrawer
        open={createDrawerOpen}
        onClose={() => setCreateDrawerOpen(false)}
        onSuccess={() => {
          setCreateDrawerOpen(false);
          refetch();
        }}
      />

      <EditAccountDrawer
        open={editDrawerOpen}
        accountId={selectedAccountId}
        onClose={() => {
          setEditDrawerOpen(false);
          setSelectedAccountId(null);
        }}
        onSuccess={() => {
          setEditDrawerOpen(false);
          setSelectedAccountId(null);
          refetch();
        }}
      />

      <ResetPasswordModal
        open={resetPasswordModalOpen}
        accountId={selectedAccountId}
        onClose={() => {
          setResetPasswordModalOpen(false);
          setSelectedAccountId(null);
        }}
        onSuccess={() => {
          setResetPasswordModalOpen(false);
          setSelectedAccountId(null);
        }}
      />

      <AssignBrandModal
        open={assignBrandModalOpen}
        accountId={selectedAccountId}
        onClose={() => {
          setAssignBrandModalOpen(false);
          setSelectedAccountId(null);
        }}
        onSuccess={() => {
          setAssignBrandModalOpen(false);
          setSelectedAccountId(null);
          refetch();
        }}
      />

      <AccountDetailDrawer
        open={detailDrawerOpen}
        accountId={selectedAccountId}
        onClose={() => {
          setDetailDrawerOpen(false);
          setSelectedAccountId(null);
        }}
      />
    </div>
  );
};
