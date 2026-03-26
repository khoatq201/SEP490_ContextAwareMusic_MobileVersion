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
import type { SpaceFilter as SpaceFilterType } from '@/shared/modules/spaces/types';

/**
 * Constants
 */
import { SPACE_STATUS_OPTIONS } from '@/features/store/constants';

type SpaceFilterProps = {
  filter: SpaceFilterType;
  showAdvanced: boolean;
  onSearch: (value: string) => void;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  onFilterChange: (key: keyof SpaceFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
};

export const SpaceFilter = ({
  filter,
  showAdvanced,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: SpaceFilterProps) => {
  const hasActiveFilters = filter.search || filter.status !== undefined;

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
          placeholder='Search by name, description...'
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
              options={SPACE_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
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
                SPACE_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
        </Space>
      )}
    </Space>
  );
};
