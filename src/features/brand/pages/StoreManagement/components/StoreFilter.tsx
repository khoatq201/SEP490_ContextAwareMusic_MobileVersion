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
import type { StoreFilter as StoreFilterType } from '@/features/brand/types';

/**
 * Constants
 */
import { STORE_STATUS_OPTIONS } from '@/features/brand/constants';

const { RangePicker } = DatePicker;

type StoreFilterProps = {
  filter: StoreFilterType;
  showAdvanced: boolean;
  cities: Array<{ label: string; value: string }>;
  onSearch: (value: string) => void;
  onFilterChange: (key: keyof StoreFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
};

export const StoreFilter = ({
  filter,
  showAdvanced,
  cities,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: StoreFilterProps) => {
  const hasActiveFilters =
    filter.search ||
    filter.status !== undefined ||
    filter.city ||
    filter.district ||
    filter.createdFrom ||
    filter.createdTo ||
    filter.storeManagerName;

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
          placeholder='Search by name, address, city, district, contact number...'
          prefix={<SearchOutlined />}
          value={filter.search}
          onChange={(e) => onSearch(e.target.value)}
          style={{ width: 400 }}
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
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by Status'
              options={STORE_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by City'
              options={cities}
              value={filter.city}
              onChange={(value) => onFilterChange('city', value)}
              style={{ width: '100%' }}
              allowClear
              showSearch
              optionFilterProp='label'
            />
          </Col>
          <Col span={6}>
            <Input
              size='large'
              placeholder='Filter by District'
              value={filter.district}
              onChange={(e) => onFilterChange('district', e.target.value)}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Input
              size='large'
              placeholder='Store Manager Name'
              value={filter.storeManagerName}
              onChange={(e) =>
                onFilterChange('storeManagerName', e.target.value)
              }
              allowClear
            />
          </Col>
        </Row>
      )}

      {showAdvanced && (
        <Row gutter={[16, 16]}>
          <Col span={12}>
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
                STORE_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
          {filter.city && (
            <Tag
              closable
              onClose={() => onFilterChange('city', undefined)}
            >
              City: {filter.city}
            </Tag>
          )}
          {filter.district && (
            <Tag
              closable
              onClose={() => onFilterChange('district', undefined)}
            >
              District: {filter.district}
            </Tag>
          )}
          {filter.storeManagerName && (
            <Tag
              closable
              onClose={() => onFilterChange('storeManagerName', undefined)}
            >
              Manager: {filter.storeManagerName}
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
