import { useMemo, useState } from 'react';
import {
  Drawer,
  Button,
  Flex,
  Radio,
  Space,
  Typography,
  Input,
  Tooltip,
  message,
} from 'antd';
import {
  PlayCircleOutlined,
  PlusOutlined,
  OrderedListOutlined,
} from '@ant-design/icons';
import { SettingSwitch } from '@/shared/components';
import { useMoods } from '@/shared/modules/moods/hooks';
import { usePlaylists } from '@/shared/modules/playlists/hooks';
import type { PlaylistFilter } from '@/shared/modules/playlists/types';
import { useTracks } from '@/shared/modules/tracks/hooks';
import type { TrackFilter } from '@/shared/modules/tracks/types';
import { useAddTracksToQueue, useAddPlaylistToQueue } from '../hooks';
import { QueueInsertMode } from '../types';
import { DRAWER_WIDTHS } from '@/config';
import { createStyles } from 'antd-style';
import {
  OverrideMusicSourceSelector,
  type OverrideSourceTab,
} from './OverrideMusicSourceSelector';

const { Text } = Typography;
const { TextArea } = Input;

interface AddToQueueDrawerProps {
  open: boolean;
  spaceId: string;
  storeId: string;
  onClose: () => void;
  onSuccess?: () => void;
}

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    selectorBlock: css`
      border: 1px solid var(--ant-color-border-secondary);
      border-radius: 12px;
      background: var(--ant-color-bg-container);
      padding: 10px;
    `,
    statusStrip: css`
      border: 1px solid var(--ant-color-border-secondary);
      border-radius: 12px;
      background: var(--ant-color-fill-tertiary);
      padding: 10px 12px;
    `,
    sectionCard: css`
      border: 1px solid var(--ant-color-border-secondary);
      border-radius: 12px;
      background: var(--ant-color-bg-container);
      padding: 12px;
    `,
    queueModeRadio: css`
      display: flex;
      flex-wrap: wrap;
      gap: 8px;

      .${prefixCls}-radio-button-wrapper {
        flex: 1;
        min-width: 160px;
        min-height: 44px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border-radius: 10px;
        margin-inline-start: 0;
      }

      .${prefixCls}-radio-button-wrapper-checked {
        .${prefixCls}-typography {
          color: #fff !important;
        }
        .anticon {
          color: #fff !important;
        }
      }
    `,
  };
});

const queueModeOptions = [
  {
    label: 'Play Now',
    value: QueueInsertMode.PlayNow,
    icon: <PlayCircleOutlined />,
    description: 'Switch to this track immediately',
  },
  {
    label: 'Play Next',
    value: QueueInsertMode.PlayNext,
    icon: <OrderedListOutlined />,
    description: 'Add after current track',
  },
  {
    label: 'Add to Queue',
    value: QueueInsertMode.AddToQueue,
    icon: <PlusOutlined />,
    description: 'Add to end of queue',
  },
];

const defaultTrackFilter: TrackFilter = {
  page: 1,
  pageSize: 10,
  sortBy: 'createdAt',
  isAscending: false,
  status: 1,
};

const defaultPlaylistFilter: PlaylistFilter = {
  page: 1,
  pageSize: 10,
  sortBy: 'createdAt',
  isAscending: false,
  status: 1,
};

export const AddToQueueDrawer = ({
  open,
  spaceId,
  storeId,
  onClose,
  onSuccess,
}: AddToQueueDrawerProps) => {
  const { styles } = useStyle();
  const [activeTab, setActiveTab] = useState<OverrideSourceTab>('tracks');
  const [showTrackFilters, setShowTrackFilters] = useState(false);
  const [showPlaylistFilters, setShowPlaylistFilters] = useState(false);
  const [reason, setReason] = useState('');
  const [mode, setMode] = useState<QueueInsertMode>(QueueInsertMode.AddToQueue);
  const [isClearExistingQueue, setIsClearExistingQueue] = useState(false);

  const [trackFilter, setTrackFilter] =
    useState<TrackFilter>(defaultTrackFilter);
  const [playlistFilter, setPlaylistFilter] = useState<PlaylistFilter>(
    defaultPlaylistFilter,
  );

  const [selectedTrackIds, setSelectedTrackIds] = useState<string[]>([]);
  const [selectedPlaylistId, setSelectedPlaylistId] = useState<string>();

  const {
    data: playlistsData,
    isLoading: isLoadingPlaylists,
    refetch: refetchPlaylists,
  } = usePlaylists({
    ...playlistFilter,
    storeId,
  });

  const {
    data: tracksData,
    isLoading: isLoadingTracks,
    refetch: refetchTracks,
  } = useTracks(trackFilter);

  const { data: moods = [] } = useMoods();

  const addTracks = useAddTracksToQueue();
  const addPlaylist = useAddPlaylistToQueue();

  const moodOptions = useMemo(
    () =>
      moods.map((mood) => ({
        label: mood.name,
        value: mood.id,
      })),
    [moods],
  );

  const hasActiveTrackFilters =
    trackFilter.search ||
    trackFilter.genre ||
    trackFilter.provider !== undefined ||
    trackFilter.isAiGenerated !== undefined;

  const hasActivePlaylistFilters =
    playlistFilter.search ||
    playlistFilter.moodId ||
    playlistFilter.isDefault !== undefined;

  const resetState = () => {
    setActiveTab('tracks');
    setShowTrackFilters(false);
    setShowPlaylistFilters(false);
    setReason('');
    setMode(QueueInsertMode.AddToQueue);
    setIsClearExistingQueue(false);
    setTrackFilter(defaultTrackFilter);
    setPlaylistFilter(defaultPlaylistFilter);
    setSelectedTrackIds([]);
    setSelectedPlaylistId(undefined);
  };

  const handleSubmit = async () => {
    try {
      if (activeTab === 'tracks') {
        if (selectedTrackIds.length === 0) {
          message.warning('Please select at least one track');
          return;
        }

        await addTracks.mutateAsync({
          spaceId,
          data: {
            trackIds: selectedTrackIds,
            mode,
            isClearExistingQueue,
            reason: reason.trim() || undefined,
          },
        });
      } else {
        if (!selectedPlaylistId) {
          message.warning('Please select a playlist');
          return;
        }

        await addPlaylist.mutateAsync({
          spaceId,
          data: {
            playlistId: selectedPlaylistId,
            mode,
            isClearExistingQueue,
            reason: reason.trim() || undefined,
          },
        });
      }

      resetState();
      onSuccess?.();
      onClose();
    } catch {
      // Error handled by mutation hooks
    }
  };

  const handleClose = () => {
    resetState();
    onClose();
  };

  const isPending = addTracks.isPending || addPlaylist.isPending;

  return (
    <Drawer
      title='Add to Queue'
      open={open}
      onClose={handleClose}
      closeIcon={null}
      width={DRAWER_WIDTHS.large}
      destroyOnHidden
      footer={
        <Flex
          justify='end'
          gap='small'
        >
          <Button
            size='large'
            onClick={handleClose}
          >
            Cancel
          </Button>
          <Button
            size='large'
            type='primary'
            loading={isPending}
            onClick={handleSubmit}
          >
            Add to Queue
          </Button>
        </Flex>
      }
    >
      <Space
        direction='vertical'
        size='large'
        style={{ width: '100%' }}
      >
        <OverrideMusicSourceSelector
          activeTab={activeTab}
          onTabChange={setActiveTab}
          enabledTabs={['tracks', 'playlist']}
          track={{
            filter: trackFilter,
            setFilter: setTrackFilter,
            showFilters: showTrackFilters,
            setShowFilters: setShowTrackFilters,
            hasActiveFilters: !!hasActiveTrackFilters,
            data: tracksData?.items || [],
            total: tracksData?.totalItems || 0,
            isLoading: isLoadingTracks,
            refetch: refetchTracks,
            selectedTrackIds,
            setSelectedTrackIds,
            defaultFilter: defaultTrackFilter,
            onTableChange: (pagination, _filters, sorter) => {
              const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;

              setTrackFilter((prev) => ({
                ...prev,
                page: pagination.current || 1,
                pageSize: pagination.pageSize || 10,
                sortBy: currentSorter.field
                  ? String(currentSorter.field)
                  : 'createdAt',
                isAscending: currentSorter.order === 'ascend',
              }));
            },
          }}
          playlist={{
            filter: playlistFilter,
            setFilter: setPlaylistFilter,
            showFilters: showPlaylistFilters,
            setShowFilters: setShowPlaylistFilters,
            hasActiveFilters: !!hasActivePlaylistFilters,
            data: playlistsData?.items || [],
            total: playlistsData?.totalItems || 0,
            isLoading: isLoadingPlaylists,
            refetch: refetchPlaylists,
            selectedPlaylistId,
            setSelectedPlaylistId,
            defaultFilter: defaultPlaylistFilter,
            moodOptions,
            onTableChange: (pagination, _filters, sorter) => {
              const currentSorter = Array.isArray(sorter) ? sorter[0] : sorter;

              setPlaylistFilter((prev) => ({
                ...prev,
                page: pagination.current || 1,
                pageSize: pagination.pageSize || 10,
                sortBy: currentSorter.field
                  ? String(currentSorter.field)
                  : 'createdAt',
                isAscending: currentSorter.order === 'ascend',
              }));
            },
          }}
        />

        <div className={styles.sectionCard}>
          <Text strong>Queue Mode</Text>
          <Radio.Group
            className={styles.queueModeRadio}
            style={{ marginTop: 10 }}
            value={mode}
            onChange={(e) => setMode(e.target.value)}
            options={queueModeOptions.map((option) => ({
              label: (
                <Tooltip title={option.description}>
                  <Space size={6}>
                    {option.icon}
                    <Text strong>{option.label}</Text>
                  </Space>
                </Tooltip>
              ),
              value: option.value,
            }))}
            optionType='button'
            buttonStyle='solid'
          />
        </div>

        <div className={styles.sectionCard}>
          <SettingSwitch
            label='Clear existing queue before adding'
            description='Remove all current tracks from the queue before adding new ones'
            value={isClearExistingQueue}
            onChange={setIsClearExistingQueue}
            className='mb-2! pt-0!'
          />

          <Text strong>Reason (Optional)</Text>
          <TextArea
            size='large'
            placeholder='Why are you adding this to the queue?'
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={3}
            maxLength={500}
            showCount
            style={{ marginTop: 8 }}
          />
        </div>
      </Space>
    </Drawer>
  );
};
