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
 * Constants
 */
import {
  GENRE_OPTIONS,
  MUSIC_PROVIDER_OPTIONS,
} from '@/shared/modules/tracks/constants';
import { ENTITY_STATUS_OPTIONS } from '@/shared/constants';

/**
 * Types
 */
import type { TrackFilter as TrackFilterType } from '@/shared/modules/tracks/types';

interface TrackFilterProps {
  filter: TrackFilterType;
  showAdvanced: boolean;
  onSearch: (value: string) => void;
  onFilterChange: (key: keyof TrackFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
}

export const TrackFilter = ({
  filter,
  showAdvanced,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: TrackFilterProps) => {
  const hasActiveFilters =
    filter.search ||
    filter.genre ||
    filter.moodId ||
    filter.provider !== undefined ||
    filter.status !== undefined ||
    filter.isAiGenerated !== undefined;

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
          placeholder='Search by title or artist...'
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
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by Genre'
              options={GENRE_OPTIONS}
              value={filter.genre}
              onChange={(value) => onFilterChange('genre', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by Provider'
              options={MUSIC_PROVIDER_OPTIONS}
              value={filter.provider}
              onChange={(value) => onFilterChange('provider', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by Status'
              options={ENTITY_STATUS_OPTIONS}
              value={filter.status}
              onChange={(value) => onFilterChange('status', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='AI Generated'
              options={[
                { label: 'All', value: undefined },
                { label: 'AI Generated', value: true },
                { label: 'Custom Upload', value: false },
              ]}
              value={filter.isAiGenerated}
              onChange={(value) => onFilterChange('isAiGenerated', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
        </Row>
      )}

      {/* Active Filters Display */}
      {(filter.genre ||
        filter.provider !== undefined ||
        filter.status !== undefined ||
        filter.isAiGenerated !== undefined) && (
        <Space wrap>
          {filter.genre && (
            <Tag
              closable
              onClose={() => onFilterChange('genre', undefined)}
            >
              Genre: {filter.genre}
            </Tag>
          )}
          {filter.provider !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('provider', undefined)}
            >
              Provider:{' '}
              {
                MUSIC_PROVIDER_OPTIONS?.find((o) => o.value === filter.provider)
                  ?.label
              }
            </Tag>
          )}
          {filter.status !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('status', undefined)}
            >
              Status:{' '}
              {
                ENTITY_STATUS_OPTIONS?.find((o) => o.value === filter.status)
                  ?.label
              }
            </Tag>
          )}
          {filter.isAiGenerated !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('isAiGenerated', undefined)}
            >
              {filter.isAiGenerated ? 'AI Generated' : 'Custom Upload'}
            </Tag>
          )}
        </Space>
      )}
    </Space>
  );
};
