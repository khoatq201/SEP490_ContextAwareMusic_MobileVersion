import { useState, useCallback } from 'react';
import {
  Card,
  Button,
  Space,
  Select,
  Typography,
  Divider,
  Flex,
  message,
  Empty,
  Tag,
} from 'antd';
import { SettingOutlined, PlayCircleOutlined } from '@ant-design/icons';
import {
  SpacePlayer,
  AIExplainabilityPanel,
} from '@/shared/modules/cams/components';
import {
  useSpaceState,
  usePlaybackControl,
  useOverridePlaylist,
} from '@/shared/modules/cams/hooks';
import { PlaybackCommand } from '@/shared/modules/cams/types';
import { isSpacePlaying } from '@/shared/modules/cams/utils';
import { usePlaylists } from '@/shared/modules/playlists/hooks';
import type { SpaceListItem } from '@/shared/modules/spaces/types';

const { Title, Text } = Typography;

interface SpacePlayerCardProps {
  space: SpaceListItem;
  storeId: string;
}

export const SpacePlayerCard = ({ space, storeId }: SpacePlayerCardProps) => {
  const [showSettings, setShowSettings] = useState(false);

  // Fetch space state from API (initial load only)
  const { data: spaceState, isLoading: isLoadingState } = useSpaceState(
    space.id,
    true,
  );

  console.log(spaceState);

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

  // ✅ Use spaceState directly from React Query
  const hlsUrl = spaceState?.hlsUrl || null;
  const hasPlaylist = !!spaceState?.currentQueueItemId;
  const isPending = !!spaceState?.pendingQueueItemId;

  // ✅ Calculate if currently playing - prioritize isPaused flag from server
  const isPlaying = spaceState
    ? !spaceState.isPaused && isSpacePlaying(spaceState)
    : false;

  // Playback control handlers
  const handlePlayPause = useCallback(() => {
    if (!hasPlaylist) {
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
  }, [space.id, isPlaying, hasPlaylist, isPending, playbackControl]);

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
    playbackControl.mutate({
      spaceId: space.id,
      command: PlaybackCommand.SkipPrevious,
    });
  }, [space.id, isPending, playbackControl]);

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
                {spaceState?.isManualOverride && (
                  <Tag color='warning'>Manual Override</Tag>
                )}
              </Flex>
              <Select
                size='large'
                placeholder='Choose a playlist'
                options={playlistOptions}
                value={spaceState?.currentQueueItemId || undefined}
                onChange={handlePlaylistChange}
                style={{ width: '100%' }}
                loading={overridePlaylist.isPending}
                disabled={overridePlaylist.isPending}
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
            </div>
            <Divider style={{ margin: '8px 0' }} />
          </>
        )}

        {/* Music Player or Empty State */}
        {!hasPlaylist ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={
              <Space
                direction='vertical'
                size='small'
              >
                <Text type='secondary'>No playlist selected</Text>
                <Button
                  size='large'
                  type='primary'
                  icon={<PlayCircleOutlined />}
                  onClick={() => setShowSettings(true)}
                >
                  Select Playlist
                </Button>
              </Space>
            }
            style={{ padding: '40px 0' }}
          />
        ) : isPending ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={
              <Space
                direction='vertical'
                size='small'
              >
                <Text type='secondary'>⏳ Đang chuẩn bị...</Text>
                <Text
                  type='secondary'
                  style={{ fontSize: 12 }}
                >
                  {spaceState?.pendingOverrideReason ||
                    'Playlist is being transcoded'}
                </Text>
              </Space>
            }
            style={{ padding: '40px 0' }}
          />
        ) : (
          <>
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
            />

            {/* AI Explainability Panel */}
            {spaceState && !spaceState.isManualOverride && (
              <>
                <Divider style={{ margin: '8px 0' }} />
                <AIExplainabilityPanel spaceState={spaceState} />
              </>
            )}
          </>
        )}
      </Space>
    </Card>
  );
};
