import { Input, Space, Flex, Button, Select, Tag, Row, Col } from 'antd';

/**
 * Icons
 */
import {
  SearchOutlined,
  ReloadOutlined,
  FilterOutlined,
} from '@ant-design/icons';

/**
 * Types
 */
import type { AccountFilter as AccountFilterType } from '@/features/admin/types';

/**
 * Constants
 */
import { ACCOUNT_STATUS_OPTIONS } from '@/features/admin/constants';

type AccountFilterProps = {
  filter: AccountFilterType;
  showAdvanced: boolean;
  brands: Array<{ label: string; value: string }>;
  onSearch: (value: string) => void;
  onFilterChange: (key: keyof AccountFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
};

export const AccountFilter = ({
  filter,
  showAdvanced,
  brands,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: AccountFilterProps) => {
  const hasActiveFilters =
    filter.search ||
    filter.brandId ||
    filter.status !== undefined ||
    filter.hasAssignedBrand !== undefined;

  return (
    <Space
      direction='vertical'
      size='middle'
      style={{ width: '100%' }}
    >
      {/* Search Bar & Action Buttons */}
      <Flex
        justify='space-between'
        wrap='wrap'
      >
        <Input
          size='large'
          placeholder='Search by name or email...'
          prefix={<SearchOutlined />}
          value={filter.search}
          onChange={(e) => onSearch(e.target.value)}
          style={{ width: 300 }}
          allowClear
        />

        <Space>
          <Button
            size='large'
            icon={<FilterOutlined />}
            onClick={onToggleAdvanced}
          >
            {showAdvanced ? 'Hide' : 'Show'} Filters
          </Button>

          <Button
            size='large'
            icon={<ReloadOutlined />}
            onClick={onRefresh}
          >
            Refresh
          </Button>

          {hasActiveFilters && (
            <Button
              size='large'
              onClick={onReset}
            >
              Reset Filters
            </Button>
          )}
        </Space>
      </Flex>

      {/* Advanced Filters */}
      {showAdvanced && (
        <Row gutter={[16, 16]}>
          <Col span={8}>
            <Select
              size='large'
              placeholder='Filter by Brand'
              options={brands}
              value={filter.brandId}
              onChange={(value) => onFilterChange('brandId', value)}
              style={{ width: '100%' }}
              allowClear
              showSearch
              optionFilterProp='label'
            />
          </Col>
          <Col span={8}>
            <Select
              size='large'
              placeholder='Filter by Status'
              options={ACCOUNT_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={8}>
            <Select
              size='large'
              placeholder='Assignment Status'
              options={[
                { label: 'All Accounts', value: undefined },
                { label: 'Assigned to Brand', value: true },
                { label: 'Not Assigned', value: false },
              ]}
              value={filter.hasAssignedBrand}
              onChange={(value) => onFilterChange('hasAssignedBrand', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
        </Row>
      )}

      {/* Active Filters Display */}
      {(filter.brandId ||
        filter.status !== undefined ||
        filter.hasAssignedBrand !== undefined) && (
        <Space wrap>
          {filter.brandId && (
            <Tag
              closable
              onClose={() => onFilterChange('brandId', undefined)}
            >
              Brand: {brands.find((b) => b.value === filter.brandId)?.label}
            </Tag>
          )}
          {filter.status !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('status', undefined)}
            >
              Status:{' '}
              {
                ACCOUNT_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
          {filter.hasAssignedBrand !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('hasAssignedBrand', undefined)}
            >
              {filter.hasAssignedBrand ? 'Assigned to Brand' : 'Not Assigned'}
            </Tag>
          )}
        </Space>
      )}
    </Space>
  );
};
