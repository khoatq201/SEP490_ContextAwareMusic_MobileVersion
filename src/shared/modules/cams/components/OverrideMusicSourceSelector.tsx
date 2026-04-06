import {
  Button,
  Col,
  Flex,
  Input,
  Row,
  Select,
  Space,
  Tabs,
  Tag,
  Typography,
} from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import type { SorterResult } from 'antd/es/table/interface';
import {
  FilterOutlined,
  ReloadOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import { createStyles } from 'antd-style';

import { DataTable } from '@/shared/components';
import { PAGINATION_SIZES } from '@/shared/constants';
import {
  GENRE_OPTIONS,
  MUSIC_PROVIDER_LABELS,
  MUSIC_PROVIDER_OPTIONS,
} from '@/shared/modules/tracks/constants';
import type { MoodListItem } from '@/shared/modules/moods/types';
import type {
  PlaylistFilter,
  PlaylistListItem,
} from '@/shared/modules/playlists/types';
import type {
  MusicProviderEnum,
  TrackFilter,
  TrackListItem,
} from '@/shared/modules/tracks/types';

export type OverrideSourceTab = 'tracks' | 'playlist' | 'mood';
const { Text } = Typography;

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    customTabs: css`
      .${prefixCls}-tabs-nav {
        margin-bottom: 0;
        .${prefixCls}-tabs-nav-wrap {
          .${prefixCls}-tabs-nav-list {
            width: 100%;
            .${prefixCls}-tabs-tab {
              justify-content: center;
              &:hover {
                background-color: var(--ant-blue-1);
                color: var(--ant-tabs-item-selected-color);
              }
            }
          }
        }
      }
    `,
  };
});

export type MoodSelectorFilter = {
  search?: string;
  moodType?: number;
  page: number;
  pageSize: number;
};

type OverrideMusicSourceSelectorProps = {
  activeTab: OverrideSourceTab;
  onTabChange: (tab: OverrideSourceTab) => void;
  enabledTabs?: OverrideSourceTab[];
  track: {
    filter: TrackFilter;
    setFilter: React.Dispatch<React.SetStateAction<TrackFilter>>;
    showFilters: boolean;
    setShowFilters: React.Dispatch<React.SetStateAction<boolean>>;
    hasActiveFilters: boolean;
    data: TrackListItem[];
    total: number;
    isLoading: boolean;
    refetch: () => void;
    selectedTrackIds: string[];
    setSelectedTrackIds: React.Dispatch<React.SetStateAction<string[]>>;
    defaultFilter: TrackFilter;
    onTableChange: (
      pagination: TablePaginationConfig,
      filters: Record<string, unknown>,
      sorter: SorterResult<TrackListItem> | SorterResult<TrackListItem>[],
    ) => void;
  };
  playlist: {
    filter: PlaylistFilter;
    setFilter: React.Dispatch<React.SetStateAction<PlaylistFilter>>;
    showFilters: boolean;
    setShowFilters: React.Dispatch<React.SetStateAction<boolean>>;
    hasActiveFilters: boolean;
    data: PlaylistListItem[];
    total: number;
    isLoading: boolean;
    refetch: () => void;
    selectedPlaylistId?: string;
    setSelectedPlaylistId: React.Dispatch<
      React.SetStateAction<string | undefined>
    >;
    defaultFilter: PlaylistFilter;
    moodOptions: Array<{ label: string; value: string }>;
    onTableChange: (
      pagination: TablePaginationConfig,
      filters: Record<string, unknown>,
      sorter: SorterResult<PlaylistListItem> | SorterResult<PlaylistListItem>[],
    ) => void;
  };
  mood?: {
    filter: MoodSelectorFilter;
    setFilter: React.Dispatch<React.SetStateAction<MoodSelectorFilter>>;
    showFilters: boolean;
    setShowFilters: React.Dispatch<React.SetStateAction<boolean>>;
    hasActiveFilters: boolean;
    data: MoodListItem[];
    total: number;
    isLoading: boolean;
    refetch: () => void;
    selectedMoodId?: string;
    setSelectedMoodId: React.Dispatch<React.SetStateAction<string | undefined>>;
    defaultFilter: MoodSelectorFilter;
    moodTypeOptions: Array<{ label: string; value: number }>;
  };
};

const getStatusLabel = (status?: number) => {
  if (status === 1) {
    return 'Active';
  }

  if (status === 0) {
    return 'Inactive';
  }

  return '-';
};

export const OverrideMusicSourceSelector = ({
  activeTab,
  onTabChange,
  enabledTabs,
  track,
  playlist,
  mood,
}: OverrideMusicSourceSelectorProps) => {
  const { styles } = useStyle();
  const allowedTabs = enabledTabs ?? ['tracks', 'playlist', 'mood'];

  const trackColumns: ColumnsType<TrackListItem> = [
    {
      title: 'Title',
      dataIndex: 'title',
      sorter: true,
      ellipsis: true,
      render: (_, record) => (
        <Space
          direction='vertical'
          size={0}
        >
          <Text strong>{record.title}</Text>
          <Text type='secondary'>{record.artist || 'Unknown artist'}</Text>
        </Space>
      ),
    },
    {
      title: 'Mood',
      dataIndex: 'moodName',
      width: 160,
      render: (value) => value || '-',
    },
    {
      title: 'Genre',
      dataIndex: 'genre',
      width: 140,
      render: (value) => value || '-',
    },
    {
      title: 'Provider',
      dataIndex: 'provider',
      width: 140,
      render: (value?: MusicProviderEnum) =>
        value !== undefined ? MUSIC_PROVIDER_LABELS[value] : '-',
    },
  ];

  const playlistColumns: ColumnsType<PlaylistListItem> = [
    {
      title: 'Playlist',
      dataIndex: 'name',
      sorter: true,
      ellipsis: true,
      render: (_, record) => (
        <Space
          direction='vertical'
          size={0}
        >
          <Text strong>{record.name || 'Unnamed playlist'}</Text>
          <Text type='secondary'>{record.moodName || 'No mood'}</Text>
        </Space>
      ),
    },
    {
      title: 'Tracks',
      dataIndex: 'trackCount',
      width: 120,
      sorter: true,
      render: (value: number) => value,
    },
    {
      title: 'Default',
      dataIndex: 'isDefault',
      width: 120,
      render: (value?: boolean) => (value ? 'Yes' : 'No'),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      width: 140,
      render: (value: number) => getStatusLabel(value),
    },
  ];

  const moodColumns: ColumnsType<MoodListItem> = [
    {
      title: 'Mood',
      dataIndex: 'name',
      render: (_, record) => (
        <Space
          direction='vertical'
          size={0}
        >
          <Text strong>{record.name}</Text>
          <Text type='secondary'>Type: {record.moodType || '-'}</Text>
        </Space>
      ),
    },
    {
      title: 'BPM',
      width: 140,
      render: (_, record) =>
        record.minBpm && record.maxBpm
          ? `${record.minBpm} - ${record.maxBpm}`
          : '-',
    },
    {
      title: 'Genre',
      dataIndex: 'genre',
      width: 160,
      render: (value) => value || '-',
    },
  ];

  return (
    <Tabs
      className={styles.customTabs}
      styles={{
        item: {
          width: 'fit-content',
          paddingInline: 15,
        },
        content: {
          paddingTop: 20,
        },
      }}
      size='small'
      activeKey={activeTab}
      onChange={(key) => onTabChange(key as OverrideSourceTab)}
      items={[
        ...(allowedTabs.includes('tracks')
          ? [
              {
                key: 'tracks',
                label: 'Tracks',
                children: (
                  <DataTable<TrackListItem>
                    filter={
                      <Space
                        direction='vertical'
                        size='middle'
                        style={{ width: '100%' }}
                      >
                        <Flex
                          justify='space-between'
                          wrap='wrap'
                        >
                          <Input
                            size='large'
                            placeholder='Search by title or artist...'
                            prefix={<SearchOutlined />}
                            value={track.filter.search}
                            onChange={(e) =>
                              track.setFilter((prev) => ({
                                ...prev,
                                search: e.target.value,
                                page: 1,
                              }))
                            }
                            style={{ width: 300 }}
                            allowClear
                          />

                          <Space>
                            <Button
                              size='large'
                              icon={<FilterOutlined />}
                              onClick={() =>
                                track.setShowFilters((prev) => !prev)
                              }
                            >
                              {track.showFilters ? 'Hide' : 'Show'} Filters
                            </Button>
                            <Button
                              size='large'
                              icon={<ReloadOutlined />}
                              onClick={track.refetch}
                            >
                              Refresh
                            </Button>
                            {track.hasActiveFilters && (
                              <Button
                                size='large'
                                onClick={() =>
                                  track.setFilter(track.defaultFilter)
                                }
                              >
                                Reset Filters
                              </Button>
                            )}
                          </Space>
                        </Flex>

                        {track.showFilters && (
                          <Row gutter={[16, 16]}>
                            <Col span={8}>
                              <Select
                                size='large'
                                placeholder='Genre'
                                options={GENRE_OPTIONS}
                                value={track.filter.genre}
                                onChange={(value) =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    genre: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                              />
                            </Col>
                            <Col span={8}>
                              <Select
                                size='large'
                                placeholder='Provider'
                                options={MUSIC_PROVIDER_OPTIONS}
                                value={track.filter.provider}
                                onChange={(value) =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    provider: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                              />
                            </Col>
                            <Col span={8}>
                              <Select
                                size='large'
                                placeholder='AI Generated'
                                options={[
                                  { label: 'All', value: undefined },
                                  { label: 'AI Generated', value: true },
                                  { label: 'Custom Upload', value: false },
                                ]}
                                value={track.filter.isAiGenerated}
                                onChange={(value) =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    isAiGenerated: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                              />
                            </Col>
                          </Row>
                        )}

                        {track.hasActiveFilters && (
                          <Space wrap>
                            {track.filter.genre && (
                              <Tag
                                closable
                                onClose={() =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    genre: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                Genre: {track.filter.genre}
                              </Tag>
                            )}
                            {track.filter.provider !== undefined && (
                              <Tag
                                closable
                                onClose={() =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    provider: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                Provider:{' '}
                                {MUSIC_PROVIDER_LABELS[track.filter.provider]}
                              </Tag>
                            )}
                            {track.filter.isAiGenerated !== undefined && (
                              <Tag
                                closable
                                onClose={() =>
                                  track.setFilter((prev) => ({
                                    ...prev,
                                    isAiGenerated: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                {track.filter.isAiGenerated
                                  ? 'AI Generated'
                                  : 'Custom Upload'}
                              </Tag>
                            )}
                          </Space>
                        )}
                      </Space>
                    }
                    rowKey='id'
                    columns={trackColumns}
                    dataSource={track.data}
                    loading={track.isLoading}
                    rowSelection={{
                      selectedRowKeys: track.selectedTrackIds,
                      onChange: (selectedRowKeys) =>
                        track.setSelectedTrackIds(selectedRowKeys as string[]),
                    }}
                    onRow={(record) => ({
                      onClick: () => {
                        track.setSelectedTrackIds((prev) =>
                          prev.includes(record.id)
                            ? prev.filter((id) => id !== record.id)
                            : [...prev, record.id],
                        );
                      },
                    })}
                    pagination={{
                      current: track.filter.page,
                      pageSize: track.filter.pageSize,
                      total: track.total,
                      showSizeChanger: true,
                      pageSizeOptions: PAGINATION_SIZES,
                      showTotal: (total) => `Total ${total} tracks`,
                      onChange: (page, pageSize) => {
                        track.setFilter((prev) => ({
                          ...prev,
                          page,
                          pageSize,
                        }));
                      },
                    }}
                    onChange={track.onTableChange}
                  />
                ),
              },
            ]
          : []),
        ...(allowedTabs.includes('playlist')
          ? [
              {
                key: 'playlist',
                label: 'Playlists',
                children: (
                  <DataTable<PlaylistListItem>
                    filter={
                      <Space
                        direction='vertical'
                        size='middle'
                        style={{ width: '100%' }}
                      >
                        <Flex
                          justify='space-between'
                          wrap='wrap'
                        >
                          <Input
                            size='large'
                            placeholder='Search by playlist name...'
                            prefix={<SearchOutlined />}
                            value={playlist.filter.search}
                            onChange={(e) =>
                              playlist.setFilter((prev) => ({
                                ...prev,
                                search: e.target.value,
                                page: 1,
                              }))
                            }
                            style={{ width: 300 }}
                            allowClear
                          />

                          <Space>
                            <Button
                              size='large'
                              icon={<FilterOutlined />}
                              onClick={() =>
                                playlist.setShowFilters((prev) => !prev)
                              }
                            >
                              {playlist.showFilters ? 'Hide' : 'Show'} Filters
                            </Button>
                            <Button
                              size='large'
                              icon={<ReloadOutlined />}
                              onClick={playlist.refetch}
                            >
                              Refresh
                            </Button>
                            {playlist.hasActiveFilters && (
                              <Button
                                size='large'
                                onClick={() =>
                                  playlist.setFilter(playlist.defaultFilter)
                                }
                              >
                                Reset Filters
                              </Button>
                            )}
                          </Space>
                        </Flex>

                        {playlist.showFilters && (
                          <Row gutter={[16, 16]}>
                            <Col span={12}>
                              <Select
                                size='large'
                                placeholder='Mood'
                                options={playlist.moodOptions}
                                value={playlist.filter.moodId}
                                onChange={(value) =>
                                  playlist.setFilter((prev) => ({
                                    ...prev,
                                    moodId: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                                showSearch
                                optionFilterProp='label'
                              />
                            </Col>
                            <Col span={12}>
                              <Select
                                size='large'
                                placeholder='Default'
                                options={[
                                  { label: 'All', value: undefined },
                                  { label: 'Default Only', value: true },
                                  { label: 'Non-Default', value: false },
                                ]}
                                value={playlist.filter.isDefault}
                                onChange={(value) =>
                                  playlist.setFilter((prev) => ({
                                    ...prev,
                                    isDefault: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                              />
                            </Col>
                          </Row>
                        )}

                        {playlist.hasActiveFilters && (
                          <Space wrap>
                            {playlist.filter.moodId && (
                              <Tag
                                closable
                                onClose={() =>
                                  playlist.setFilter((prev) => ({
                                    ...prev,
                                    moodId: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                Mood:{' '}
                                {
                                  playlist.moodOptions.find(
                                    (x) => x.value === playlist.filter.moodId,
                                  )?.label
                                }
                              </Tag>
                            )}
                            {playlist.filter.isDefault !== undefined && (
                              <Tag
                                closable
                                onClose={() =>
                                  playlist.setFilter((prev) => ({
                                    ...prev,
                                    isDefault: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                {playlist.filter.isDefault
                                  ? 'Default Only'
                                  : 'Non-Default'}
                              </Tag>
                            )}
                          </Space>
                        )}
                      </Space>
                    }
                    rowKey='id'
                    columns={playlistColumns}
                    dataSource={playlist.data}
                    loading={playlist.isLoading}
                    rowSelection={{
                      type: 'radio',
                      selectedRowKeys: playlist.selectedPlaylistId
                        ? [playlist.selectedPlaylistId]
                        : [],
                      onChange: (selectedRowKeys) =>
                        playlist.setSelectedPlaylistId(
                          selectedRowKeys[0] as string,
                        ),
                    }}
                    onRow={(record) => ({
                      onClick: () => playlist.setSelectedPlaylistId(record.id),
                    })}
                    pagination={{
                      current: playlist.filter.page,
                      pageSize: playlist.filter.pageSize,
                      total: playlist.total,
                      showSizeChanger: true,
                      pageSizeOptions: PAGINATION_SIZES,
                      showTotal: (total) => `Total ${total} playlists`,
                      onChange: (page, pageSize) => {
                        playlist.setFilter((prev) => ({
                          ...prev,
                          page,
                          pageSize,
                        }));
                      },
                    }}
                    onChange={playlist.onTableChange}
                  />
                ),
              },
            ]
          : []),
        ...(allowedTabs.includes('mood') && mood
          ? [
              {
                key: 'mood',
                label: 'Moods',
                children: (
                  <DataTable<MoodListItem>
                    filter={
                      <Space
                        direction='vertical'
                        size='middle'
                        style={{ width: '100%' }}
                      >
                        <Flex
                          justify='space-between'
                          wrap='wrap'
                        >
                          <Input
                            size='large'
                            placeholder='Search by mood name or genre...'
                            prefix={<SearchOutlined />}
                            value={mood.filter.search}
                            onChange={(e) =>
                              mood.setFilter((prev) => ({
                                ...prev,
                                search: e.target.value,
                                page: 1,
                              }))
                            }
                            style={{ width: 300 }}
                            allowClear
                          />

                          <Space>
                            <Button
                              size='large'
                              icon={<FilterOutlined />}
                              onClick={() =>
                                mood.setShowFilters((prev) => !prev)
                              }
                            >
                              {mood.showFilters ? 'Hide' : 'Show'} Filters
                            </Button>
                            <Button
                              size='large'
                              icon={<ReloadOutlined />}
                              onClick={mood.refetch}
                            >
                              Refresh
                            </Button>
                            {mood.hasActiveFilters && (
                              <Button
                                size='large'
                                onClick={() =>
                                  mood.setFilter(mood.defaultFilter)
                                }
                              >
                                Reset Filters
                              </Button>
                            )}
                          </Space>
                        </Flex>

                        {mood.showFilters && (
                          <Row gutter={[16, 16]}>
                            <Col span={8}>
                              <Select
                                size='large'
                                placeholder='Mood Type'
                                options={mood.moodTypeOptions}
                                value={mood.filter.moodType}
                                onChange={(value) =>
                                  mood.setFilter((prev) => ({
                                    ...prev,
                                    moodType: value,
                                    page: 1,
                                  }))
                                }
                                style={{ width: '100%' }}
                                allowClear
                              />
                            </Col>
                          </Row>
                        )}

                        {mood.hasActiveFilters && (
                          <Space wrap>
                            {mood.filter.moodType && (
                              <Tag
                                closable
                                onClose={() =>
                                  mood.setFilter((prev) => ({
                                    ...prev,
                                    moodType: undefined,
                                    page: 1,
                                  }))
                                }
                              >
                                Type: {mood.filter.moodType}
                              </Tag>
                            )}
                          </Space>
                        )}
                      </Space>
                    }
                    rowKey='id'
                    columns={moodColumns}
                    dataSource={mood.data}
                    loading={mood.isLoading}
                    rowSelection={{
                      type: 'radio',
                      selectedRowKeys: mood.selectedMoodId
                        ? [mood.selectedMoodId]
                        : [],
                      onChange: (selectedRowKeys) =>
                        mood.setSelectedMoodId(selectedRowKeys[0] as string),
                    }}
                    onRow={(record) => ({
                      onClick: () => mood.setSelectedMoodId(record.id),
                    })}
                    pagination={{
                      current: mood.filter.page,
                      pageSize: mood.filter.pageSize,
                      total: mood.total,
                      showSizeChanger: true,
                      pageSizeOptions: PAGINATION_SIZES,
                      showTotal: (total) => `Total ${total} moods`,
                      onChange: (page, pageSize) => {
                        mood.setFilter((prev) => ({ ...prev, page, pageSize }));
                      },
                    }}
                  />
                ),
              },
            ]
          : []),
      ]}
    />
  );
};
