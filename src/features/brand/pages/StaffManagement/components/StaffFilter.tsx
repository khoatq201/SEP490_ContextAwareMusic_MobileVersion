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
import type { StaffFilter as StaffFilterType } from '@/features/brand/types';

/**
 * Constants
 */
import { STAFF_STATUS_OPTIONS } from '@/features/brand/constants';

type StaffFilterProps = {
  filter: StaffFilterType;
  showAdvanced: boolean;
  stores: Array<{ label: string; value: string }>;
  onSearch: (value: string) => void;
  onFilterChange: (key: keyof StaffFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
};

export const StaffFilter = ({
  filter,
  showAdvanced,
  stores,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: StaffFilterProps) => {
  const hasActiveFilters =
    filter.search || filter.status !== undefined || filter.storeId;

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
          placeholder='Search by name, email, phone number...'
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
          <Col span={12}>
            <Select
              size='large'
              placeholder='Filter by Status'
              options={STAFF_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={12}>
            <Select
              size='large'
              placeholder='Filter by Store'
              options={stores}
              value={filter.storeId}
              onChange={(value) => onFilterChange('storeId', value)}
              style={{ width: '100%' }}
              allowClear
              showSearch
              optionFilterProp='label'
            />
          </Col>
        </Row>
      )}

      {/* Active Filters Display */}
      {hasActiveFilters && (
        <Space wrap>
          {filter.status !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('status', undefined)}
            >
              Status:{' '}
              {
                STAFF_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
          {filter.storeId && (
            <Tag
              closable
              onClose={() => onFilterChange('storeId', undefined)}
            >
              Store: {stores.find((s) => s.value === filter.storeId)?.label}
            </Tag>
          )}
        </Space>
      )}
    </Space>
  );
};
