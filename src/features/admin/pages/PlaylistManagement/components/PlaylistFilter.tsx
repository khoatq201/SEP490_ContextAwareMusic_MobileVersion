import { Input, Space, Flex, Button, Select, Tag, Row, Col, Alert } from 'antd';

/**
 * Icons
 */
import {
  SearchOutlined,
  ReloadOutlined,
  FilterOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';

/**
 * Constants
 */
import { ENTITY_STATUS_OPTIONS } from '@/shared/constants';

/**
 * Types
 */
import type { PlaylistFilter as PlaylistFilterType } from '@/shared/modules/playlists/types';

interface PlaylistFilterProps {
  filter: PlaylistFilterType;
  showAdvanced: boolean;
  brands: Array<{ label: string; value: string }>;
  moods: Array<{ label: string; value: string }>;
  onSearch: (value: string) => void;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  onFilterChange: (key: keyof PlaylistFilterType, value: any) => void;
  onToggleAdvanced: () => void;
  onRefresh: () => void;
  onReset: () => void;
}

export const PlaylistFilter = ({
  filter,
  showAdvanced,
  brands,
  moods,
  onSearch,
  onFilterChange,
  onToggleAdvanced,
  onRefresh,
  onReset,
}: PlaylistFilterProps) => {
  const hasActiveFilters =
    filter.search ||
    filter.brandId ||
    filter.moodId ||
    filter.status !== undefined ||
    filter.isDefault !== undefined;

  return (
    <Space
      direction='vertical'
      size='middle'
      style={{ width: '100%' }}
    >
      {/* Read-Only Notice */}
      <Alert
        message='System Administrator View'
        description='You can view all playlists across all brands but cannot modify them. Playlist management is handled by Brand and Store Managers.'
        type='info'
        icon={<InfoCircleOutlined />}
        showIcon
        closable
      />

      {/* Search Bar & Action Buttons */}
      <Flex
        justify='space-between'
        wrap='wrap'
      >
        <Input
          size='large'
          placeholder='Search by playlist name...'
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
          <Col span={6}>
            <Select
              size='large'
              placeholder='Filter by Mood'
              options={moods}
              value={filter.moodId}
              onChange={(value) => onFilterChange('moodId', value)}
              style={{ width: '100%' }}
              allowClear
              showSearch
              optionFilterProp='label'
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='Default'
              options={[
                { label: 'All', value: undefined },
                { label: 'Default Only', value: true },
                { label: 'Non-Default', value: false },
              ]}
              value={filter.isDefault}
              onChange={(value) => onFilterChange('isDefault', value)}
              style={{ width: '100%' }}
              allowClear
            />
          </Col>
          <Col span={6}>
            <Select
              size='large'
              placeholder='Status'
              options={ENTITY_STATUS_OPTIONS}
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
          {filter.brandId && (
            <Tag
              closable
              onClose={() => onFilterChange('brandId', undefined)}
            >
              Brand: {brands.find((b) => b.value === filter.brandId)?.label}
            </Tag>
          )}
          {filter.moodId && (
            <Tag
              closable
              onClose={() => onFilterChange('moodId', undefined)}
            >
              Mood: {moods.find((m) => m.value === filter.moodId)?.label}
            </Tag>
          )}
          {filter.isDefault !== undefined && (
            <Tag
              closable
              onClose={() => onFilterChange('isDefault', undefined)}
            >
              {filter.isDefault ? 'Default Only' : 'Non-Default'}
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
        </Space>
      )}
    </Space>
  );
};
