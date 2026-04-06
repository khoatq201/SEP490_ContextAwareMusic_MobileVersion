import { useState, useCallback, useRef } from 'react';
import {
  Card,
  Button,
  Space,
  Select,
  Typography,
  Divider,
  Flex,
  message,
} from 'antd';
import {
  SettingOutlined,
  PlusOutlined,
  DeleteOutlined,
} from '@ant-design/icons';
import {
  SpacePlayer,
  AIExplainabilityPanel,
  QueueList,
  OverrideSpaceMusicDrawer,
  AddToQueueDrawer,
} from '@/shared/modules/cams/components';
import {
  useSpaceState,
  usePlaybackControl,
  useOverridePlaylist,
  useCancelOverride,
  useUpdateAudioState,
  useRemoveQueueItem,
  useRemoveQueueItems,
  useClearQueue,
  useReorderQueue,
} from '@/shared/modules/cams/hooks';
import {
  PlaybackCommand,
  QueueItemSource,
  QueueItemStatus,
  QueueEndBehavior,
} from '@/shared/modules/cams/types';
import type { SpaceQueueItemResponse } from '@/shared/modules/cams/types';
import { isSpacePlaying } from '@/shared/modules/cams/utils';
import { usePlaylists } from '@/shared/modules/playlists/hooks';
import type { SpaceListItem } from '@/shared/modules/spaces/types';
import { AppModal, SettingSwitch } from '@/shared/components';

const { Title, Text } = Typography;

interface SpacePlayerCardProps {
  space: SpaceListItem;
  storeId: string;
}

export const SpacePlayerCard = ({ space, storeId }: SpacePlayerCardProps) => {
  const [showSettings, setShowSettings] = useState(false);
  const [isOverrideDrawerOpen, setIsOverrideDrawerOpen] = useState(false);
  const [isAddQueueModalOpen, setIsAddQueueModalOpen] = useState(false);

  // Fetch space state from API (initial load only)
  const { data: spaceState, isLoading: isLoadingState } = useSpaceState(
    space.id,
    true,
  );

  // ✅ Use spaceState directly - no need for intermediate state
  // The component will re-render when spaceState changes from React Query

  // Fetch available playlists for this store
  const { data: playlistsData } = usePlaylists({
    page: 1,
    pageSize: 100,
    status: 1,
    storeId,
  });

  // Mutations
  const playbackControl = usePlaybackControl();
  const overridePlaylist = useOverridePlaylist();
  const cancelOverride = useCancelOverride();
  const updateAudio = useUpdateAudioState();
  const removeQueueItem = useRemoveQueueItem();
  const removeQueueItems = useRemoveQueueItems();
  const clearQueue = useClearQueue();
  const reorderQueue = useReorderQueue();

  // Debounce ref for volume updates
  const volumeUpdateTimeoutRef = useRef<number | null>(null);

  // ✅ Use spaceState directly from React Query
  const hlsUrl = spaceState?.hlsUrl || null;
  const hasActiveTrack = !!spaceState?.currentQueueItemId;
  const isPending = !!spaceState?.pendingQueueItemId;
  const rawQueue = spaceState?.spaceQueueItems || [];
  // queue presence is derived where needed

  // ✅ Calculate if currently playing - prioritize isPaused flag from server
  const isPlaying = spaceState
    ? !spaceState.isPaused && isSpacePlaying(spaceState)
    : false;

  // Normalize queue items: accept either `position` or `orderIndex`, accept optional queueStatus from server
  const normalizedQueue = (
    rawQueue as Array<
      Partial<SpaceQueueItemResponse> & {
        orderIndex?: number;
        queueStatus?: number;
        source?: number;
      }
    >
  ).map((item) => {
    const position = item.position ?? item.orderIndex ?? 0;
    const rawStatus =
      typeof item.queueStatus === 'number' ? item.queueStatus : undefined;
    return {
      queueItemId: item.queueItemId,
      trackId: item.trackId ?? null,
      trackName: item.trackName || 'Unknown',
      position,
      rawStatus,
      source:
        typeof item.source === 'number'
          ? (item.source as QueueItemSource)
          : QueueItemSource.Manager,
      hlsUrl: item.hlsUrl ?? null,
      isReadyToStream: !!item.hlsUrl,
      coverImageUrl: item.coverImageUrl ?? null,
    } as Partial<SpaceQueueItemResponse & { rawStatus?: number }>;
  });

  // Sort by position
  const sortedByPosition = [...normalizedQueue].sort(
    (a, b) => (a.position! as number) - (b.position! as number),
  );

  // Determine current item position (if any)
  const currentItem = sortedByPosition.find(
    (i) => i.queueItemId === spaceState?.currentQueueItemId,
  ) || { position: 0 };

  // Map to full SpaceQueueItemResponse with proper queueStatus mapping
  const queueItems: SpaceQueueItemResponse[] = sortedByPosition.map((i) => {
    const position = i.position ?? 0;
    let queueStatus: QueueItemStatus;

    if (typeof i.rawStatus === 'number') {
      queueStatus = i.rawStatus as QueueItemStatus;
    } else if (i.queueItemId === spaceState?.currentQueueItemId) {
      queueStatus = QueueItemStatus.Playing;
    } else if (i.queueItemId === spaceState?.pendingQueueItemId) {
      queueStatus = QueueItemStatus.Pending;
    } else if (position < (currentItem.position ?? 0)) {
      queueStatus = QueueItemStatus.Played;
    } else {
      queueStatus = QueueItemStatus.Pending;
    }

    return {
      queueItemId: i.queueItemId!,
      trackId: i.trackId ?? '',
      trackName: i.trackName ?? 'Unknown',
      position: position as number,
      queueStatus,
      source: i.source ?? QueueItemSource.AI,
      hlsUrl: i.hlsUrl ?? null,
      isReadyToStream: !!i.hlsUrl,
      coverImageUrl: i.coverImageUrl ?? null,
    } as SpaceQueueItemResponse;
  });

  // Playback control handlers
  const handlePlayPause = useCallback(() => {
    if (!hasActiveTrack) {
      message.warning('Please select a playlist first');
      return;
    }

    if (isPending) {
      message.info('Playlist is being prepared. Please wait...');
      return;
    }

    // Toggle based on current playing state
    const command = isPlaying ? PlaybackCommand.Pause : PlaybackCommand.Resume;

    playbackControl.mutate({
      spaceId: space.id,
      command,
    });
  }, [space.id, isPlaying, hasActiveTrack, isPending, playbackControl]);

  const handleSkipNext = useCallback(() => {
    if (isPending) {
      message.info('Playlist is being prepared. Please wait...');
      return;
    }
    playbackControl.mutate({
      spaceId: space.id,
      command: PlaybackCommand.SkipNext,
    });
  }, [space.id, isPending, playbackControl]);

  const handleSkipPrevious = useCallback(() => {
    if (isPending) {
      message.info('Playlist is being prepared. Please wait...');
      return;
    }

    // Attempt to jump to previous track (always jump when available).
    // Find previous item by position
    const currentPos = currentItem.position ?? 0;
    const previous = queueItems
      .filter((it) => it.position < currentPos)
      .sort((a, b) => b.position - a.position)[0];

    if (previous && previous.queueItemId) {
      // Use SkipToTrack to explicitly jump to previous queue item
      playbackControl.mutate({
        spaceId: space.id,
        command: PlaybackCommand.SkipToTrack,
        targetQueueItemId: previous.queueItemId,
      });
      return;
    }

    // Fallback: no previous found — send regular SkipPrevious
    playbackControl.mutate({
      spaceId: space.id,
      command: PlaybackCommand.SkipPrevious,
    });
  }, [space.id, isPending, playbackControl, currentItem.position, queueItems]);

  const handleSkipToTrack = useCallback(
    (_queueItemId: string, trackId?: string) => {
      if (isPending) {
        message.info('Playlist is being prepared. Please wait...');
        return;
      }

      if (!trackId) {
        message.warning('Track not available');
        return;
      }

      playbackControl.mutate({
        spaceId: space.id,
        command: PlaybackCommand.SkipToTrack,
        targetQueueItemId: _queueItemId,
      });
    },
    [space.id, isPending, playbackControl],
  );

  const handleRemoveQueueItem = useCallback(
    async (queueItemId: string) => {
      if (!queueItemId) {
        return;
      }

      await removeQueueItem.mutateAsync({
        spaceId: space.id,
        queueItemId,
      });
    },
    [removeQueueItem, space.id],
  );

  const handleReorderQueue = useCallback(
    async (orderedQueueItemIds: string[]) => {
      const pendingIdSet = new Set(
        queueItems
          .filter((item) => item.queueStatus === QueueItemStatus.Pending)
          .map((item) => item.queueItemId),
      );

      const pendingOrderedIds = orderedQueueItemIds.filter((id) =>
        pendingIdSet.has(id),
      );

      if (pendingOrderedIds.length === 0) {
        return;
      }

      await reorderQueue.mutateAsync({
        spaceId: space.id,
        data: { queueItemIds: pendingOrderedIds },
      });
    },
    [queueItems, reorderQueue, space.id],
  );

  const handleRemoveQueueItems = useCallback(
    async (queueItemIds: string[]) => {
      if (!queueItemIds.length) {
        return;
      }

      await removeQueueItems.mutateAsync({
        spaceId: space.id,
        queueItemIds,
      });
    },
    [removeQueueItems, space.id],
  );

  const handleClearQueue = useCallback(() => {
    AppModal.confirm({
      title: 'Clear Queue',
      content: 'Are you sure you want to clear the entire queue?',
      okText: 'Clear All',
      cancelText: 'Cancel',
      okButtonProps: { danger: true },
      onOk: async () => {
        await clearQueue.mutateAsync(space.id);
      },
    });
  }, [clearQueue, space.id]);

  // Seek (absolute) from player slider (debounced on after-change)
  const handleSeek = useCallback(
    (seconds: number) => {
      if (isPending) {
        message.info('Playlist is being prepared. Please wait...');
        return;
      }

      playbackControl.mutate({
        spaceId: space.id,
        command: PlaybackCommand.Seek,
        seekPositionSeconds: Math.max(0, Math.floor(seconds)),
      });
    },
    [space.id, isPending, playbackControl],
  );

  const handleRewind10 = useCallback(() => {
    if (isPending) {
      message.info('Playlist is being prepared. Please wait...');
      return;
    }
    playbackControl.mutate({
      spaceId: space.id,
      command: PlaybackCommand.SeekBackward,
      seekPositionSeconds: 10,
    });
  }, [space.id, isPending, playbackControl]);

  const handleForward10 = useCallback(() => {
    if (isPending) {
      message.info('Playlist is being prepared. Please wait...');
      return;
    }
    playbackControl.mutate({
      spaceId: space.id,
      command: PlaybackCommand.SeekForward,
      seekPositionSeconds: 10,
    });
  }, [space.id, isPending, playbackControl]);

  // Volume / Mute / Queue behavior handlers
  const handleVolumeChangeBackend = useCallback(
    (volume: number) => {
      if (volumeUpdateTimeoutRef.current) {
        clearTimeout(volumeUpdateTimeoutRef.current);
        volumeUpdateTimeoutRef.current = null;
      }
      volumeUpdateTimeoutRef.current = window.setTimeout(() => {
        updateAudio.mutate({
          spaceId: space.id,
          data: {
            volumePercent: Math.max(0, Math.min(100, Math.floor(volume))),
          },
        });
        volumeUpdateTimeoutRef.current = null;
      }, 400);
    },
    [space.id, updateAudio],
  );

  const handleToggleMute = useCallback(() => {
    updateAudio.mutate({
      spaceId: space.id,
      data: { isMuted: !spaceState?.isMuted },
    });
  }, [space.id, spaceState?.isMuted, updateAudio]);

  const handleQueueEndBehaviorChange = useCallback(
    (value: QueueEndBehavior) => {
      updateAudio.mutate({
        spaceId: space.id,
        data: { queueEndBehavior: value },
      });
    },
    [space.id, updateAudio],
  );

  // Override playlist handler (Mode 1: Playlist)
  const handlePlaylistChange = useCallback(
    (playlistId: string) => {
      if (!playlistId) {
        message.warning('Please select a playlist');
        return;
      }

      overridePlaylist.mutate({
        spaceId: space.id,
        playlistId,
      });
    },
    [space.id, overridePlaylist],
  );

  const handleOverrideToggle = useCallback(
    (checked: boolean) => {
      if (checked) {
        setIsOverrideDrawerOpen(true);
        return;
      }

      AppModal.confirm({
        title: 'Cancel Manual Override',
        content:
          'Are you sure you want to cancel manual override? AI scheduling will resume automatically.',
        okText: 'Cancel Override',
        cancelText: 'Keep Override',
        onOk: async () => {
          await cancelOverride.mutateAsync(space.id);
        },
      });
    },
    [cancelOverride, space.id],
  );

  // Playlist options for Select
  const playlistOptions = (playlistsData?.items || []).map((playlist) => ({
    label: playlist.name,
    value: playlist.id,
  }));

  return (
    <Card
      title={
        <Flex
          justify='space-between'
          align='center'
        >
          <Title level={5}>{space.name}</Title>
          <Button
            type='text'
            icon={<SettingOutlined />}
            onClick={() => setShowSettings(!showSettings)}
          />
        </Flex>
      }
      loading={isLoadingState}
    >
      <Space
        direction='vertical'
        style={{ width: '100%' }}
        size='middle'
      >
        <SettingSwitch
          label='Manual Override'
          description='Turn on to select tracks/playlist/mood manually. Turn off to resume AI control.'
          value={!!spaceState?.isManualOverride}
          onChange={handleOverrideToggle}
          disabled={overridePlaylist.isPending || cancelOverride.isPending}
        />

        {/* Playlist Selection (Settings) */}
        {showSettings && (
          <>
            <div>
              <Flex
                justify='space-between'
                align='center'
              >
                <Text
                  strong
                  style={{ display: 'block', marginBottom: 8 }}
                >
                  Select Playlist to Play
                </Text>
              </Flex>

              <Select
                size='large'
                placeholder='Choose a playlist'
                options={playlistOptions}
                value={spaceState?.currentQueueItemId || undefined}
                onChange={handlePlaylistChange}
                style={{ width: '100%' }}
                loading={overridePlaylist.isPending}
                disabled={
                  overridePlaylist.isPending || cancelOverride.isPending
                }
                showSearch
                optionFilterProp='label'
                allowClear={false}
              />
              {spaceState?.currentTrackName && (
                <Text
                  type='secondary'
                  style={{ fontSize: 12, marginTop: 4 }}
                >
                  Current: {spaceState.currentTrackName}
                  {spaceState.moodName && ` (${spaceState.moodName})`}
                </Text>
              )}

              {/* Audio controls in settings: volume, mute, queue behavior */}
              <div style={{ marginTop: 12 }}>
                <Flex
                  justify='space-between'
                  align='center'
                  style={{ marginBottom: 8 }}
                >
                  <Text strong>Audio</Text>
                  <Space>
                    <Text
                      type='secondary'
                      style={{ fontSize: 12 }}
                    >
                      Volume: {spaceState?.volumePercent ?? 0}%
                    </Text>
                    <Button
                      size='small'
                      type='text'
                      onClick={handleToggleMute}
                    >
                      {spaceState?.isMuted ? 'Unmute' : 'Mute'}
                    </Button>
                  </Space>
                </Flex>

                {/* Queue end behavior moved out of settings to a visible control below the player */}
              </div>
            </div>
            <Divider style={{ margin: '8px 0' }} />
          </>
        )}

        {/* Always show player controls per Rule 1 */}
        <SpacePlayer
          spaceId={space.id}
          hlsUrl={hlsUrl}
          state={spaceState}
          isPlaying={isPlaying}
          isLoading={
            isLoadingState ||
            playbackControl.isPending ||
            overridePlaylist.isPending
          }
          onPlayPause={handlePlayPause}
          onSkipNext={handleSkipNext}
          onSkipPrevious={handleSkipPrevious}
          onSeek={handleSeek}
          onRewind10={handleRewind10}
          onForward10={handleForward10}
          onVolumeChangeComplete={handleVolumeChangeBackend}
          onToggleMute={handleToggleMute}
          onQueueEndBehaviorChange={(next) =>
            handleQueueEndBehaviorChange(next as QueueEndBehavior)
          }
          // Button disable logic (Rule 3)
          isPreviousDisabled={
            queueItems.length === 0 ||
            queueItems.filter((it) => it.position < (currentItem.position ?? 0))
              .length === 0
          }
          isNextDisabled={
            queueItems.length === 0 ||
            (queueItems.filter(
              (it) => it.position > (currentItem.position ?? 0),
            ).length === 0 &&
              (spaceState?.queueEndBehavior ?? QueueEndBehavior.Stop) !==
                QueueEndBehavior.RepeatQueue)
          }
        />

        {/* Repeat button moved into the player component; no duplicate here */}

        {/* AI Explainability Panel */}
        {spaceState && !spaceState.isManualOverride && (
          <>
            <Divider style={{ margin: '8px 0' }} />
            <AIExplainabilityPanel spaceState={spaceState} />
          </>
        )}

        {/* Queue list (render all items sorted) */}
        <Divider style={{ margin: '8px 0' }} />
        <Flex
          justify='space-between'
          align='center'
        >
          <Text strong>Queue Management</Text>
          <Space>
            <Button
              size='large'
              icon={<DeleteOutlined />}
              danger
              onClick={handleClearQueue}
              loading={clearQueue.isPending}
              disabled={queueItems.length === 0 || clearQueue.isPending}
            >
              Clear Queue
            </Button>
            <Button
              size='large'
              type='primary'
              icon={<PlusOutlined />}
              onClick={() => setIsAddQueueModalOpen(true)}
              disabled={clearQueue.isPending}
            >
              Add to Queue
            </Button>
          </Space>
        </Flex>
        <QueueList
          items={queueItems}
          onRemove={handleRemoveQueueItem}
          onRemoveMany={handleRemoveQueueItems}
          onReorder={handleReorderQueue}
          onSkipToTrack={handleSkipToTrack}
        />

        <AddToQueueDrawer
          open={isAddQueueModalOpen}
          spaceId={space.id}
          storeId={storeId}
          onClose={() => setIsAddQueueModalOpen(false)}
        />

        <OverrideSpaceMusicDrawer
          open={isOverrideDrawerOpen}
          spaceId={space.id}
          storeId={storeId}
          onClose={() => setIsOverrideDrawerOpen(false)}
        />
      </Space>
    </Card>
  );
};
