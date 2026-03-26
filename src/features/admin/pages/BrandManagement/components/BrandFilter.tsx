import {
  Input,
  Space,
  Flex,
  Button,
  Select,
  Tag,
  Row,
  Col,
  DatePicker,
} from 'antd';
import dayjs from 'dayjs';

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
import type { BrandFilter as BrandFilterType } from '@/features/admin/types';

/**
 * Constants
 */
import { BRAND_STATUS_OPTIONS } from '@/features/admin/constants';

const { RangePicker } = DatePicker;

type BrandFilterProps = {
  filter: BrandFilterType;
  showAdvanced: boolean;
  onSearch: (value: string) => void;
  onFilterChange: (key: keyof BrandFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
};

export const BrandFilter = ({
  filter,
  showAdvanced,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: BrandFilterProps) => {
  const hasActiveFilters =
    filter.search ||
    filter.status !== undefined ||
    filter.createdFrom ||
    filter.createdTo;

  const handleDateRangeChange = (dates: any) => {
    if (dates) {
      onFilterChange('createdFrom', dates[0]?.toISOString());
      onFilterChange('createdTo', dates[1]?.toISOString());
    } else {
      onFilterChange('createdFrom', undefined);
      onFilterChange('createdTo', undefined);
    }
  };

  const dateRangeValue =
    filter.createdFrom && filter.createdTo
      ? [dayjs(filter.createdFrom), dayjs(filter.createdTo)]
      : null;

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
          placeholder='Search by name, website, industry, contact...'
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
              placeholder='Filter by Status'
              options={BRAND_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={8}>
            <RangePicker
              size='large'
              placeholder={['Created From', 'Created To']}
              value={dateRangeValue as any}
              onChange={handleDateRangeChange}
              style={{ width: '100%' }}
              format='DD/MM/YYYY'
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
                BRAND_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
          {(filter.createdFrom || filter.createdTo) && (
            <Tag
              closable
              onClose={() => {
                onFilterChange('createdFrom', undefined);
                onFilterChange('createdTo', undefined);
              }}
            >
              Created:{' '}
              {filter.createdFrom &&
                dayjs(filter.createdFrom).format('DD/MM/YYYY')}
              {' - '}
              {filter.createdTo && dayjs(filter.createdTo).format('DD/MM/YYYY')}
            </Tag>
          )}
        </Space>
      )}
    </Space>
  );
};
