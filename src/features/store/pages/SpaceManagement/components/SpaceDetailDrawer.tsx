import { Drawer, Descriptions, Tag, Spin, Alert, Space, Badge } from 'antd';

/**
 * Icons
 */
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  PlayCircleOutlined,
  PauseCircleOutlined,
  StopOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { useSpace } from '@/shared/modules/spaces/hooks';
import { useSpaceState } from '@/shared/modules/cams/hooks';

/**
 * Constants
 */
import {
  SPACE_TYPE_LABELS,
  SPACE_TYPE_COLORS,
} from '@/features/store/constants';
import { ENTITY_STATUS_LABELS } from '@/shared/constants';

/**
 * Utils
 */
import { formatDate, formatDuration } from '@/shared/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

interface SpaceDetailDrawerProps {
  open: boolean;
  spaceId?: string;
  onClose: () => void;
}

const getPlaybackStatusTag = (isPaused?: boolean, hasPlaylist?: boolean) => {
  if (!hasPlaylist) {
    return (
      <Tag
        icon={<StopOutlined />}
        color='default'
      >
        No Playlist
      </Tag>
    );
  }
  if (isPaused) {
    return (
      <Tag
        icon={<PauseCircleOutlined />}
        color='warning'
      >
        Paused
      </Tag>
    );
  }
  return (
    <Tag
      icon={<PlayCircleOutlined />}
      color='processing'
    >
      Playing
    </Tag>
  );
};

export const SpaceDetailDrawer = ({
  open,
  spaceId,
  onClose,
}: SpaceDetailDrawerProps) => {
  const { data: space, isLoading, error } = useSpace(spaceId, open);
  const { data: spaceState, isLoading: isLoadingState } = useSpaceState(
    spaceId,
    open,
  );

  return (
    <Drawer
      closeIcon={null}
      title='Space Details'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={onClose}
    >
      {(isLoading || isLoadingState) && (
        <div style={{ textAlign: 'center', padding: 48 }}>
          <Spin size='large' />
        </div>
      )}

      {error && (
        <Alert
          message='Error'
          description='Failed to load space details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {space && (
        <Space
          direction='vertical'
          size='large'
          style={{ width: '100%' }}
        >
          {/* Basic Information */}
          <Descriptions
            title='Basic Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Name'>{space.name}</Descriptions.Item>
            <Descriptions.Item label='Type'>
              <Tag color={SPACE_TYPE_COLORS[space.type]}>
                {SPACE_TYPE_LABELS[space.type]}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Status'>
              <Tag
                icon={
                  space.status === 1 ? (
                    <CheckCircleOutlined />
                  ) : (
                    <CloseCircleOutlined />
                  )
                }
                color={space.status === 1 ? 'success' : 'default'}
              >
                {ENTITY_STATUS_LABELS[space.status]}
              </Tag>
            </Descriptions.Item>
            {space.description && (
              <Descriptions.Item label='Description'>
                {space.description}
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* Playback State */}
          <Descriptions
            title='Playback State'
            column={1}
            bordered
          >
            <Descriptions.Item label='Status'>
              {getPlaybackStatusTag(
                spaceState?.isPaused,
                !!spaceState?.currentQueueItemId,
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Current Track'>
              {spaceState?.currentTrackName ? (
                <Tag color='blue'>{spaceState.currentTrackName}</Tag>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Mood'>
              {spaceState?.moodName ? (
                <Tag color='purple'>{spaceState.moodName}</Tag>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Override'>
              {spaceState?.isManualOverride ? (
                <Tag color='orange'>Manual Override</Tag>
              ) : (
                <Tag color='default'>Auto Schedule</Tag>
              )}
            </Descriptions.Item>
            {spaceState?.isPaused &&
              spaceState.pausePositionSeconds != null && (
                <Descriptions.Item label='Paused At'>
                  {formatDuration(spaceState.pausePositionSeconds)}
                </Descriptions.Item>
              )}
            {!spaceState?.isPaused && spaceState?.startedAtUtc && (
              <Descriptions.Item label='Playing Since'>
                {formatDate(spaceState.startedAtUtc)}
              </Descriptions.Item>
            )}
            {spaceState?.expectedEndAtUtc && (
              <Descriptions.Item label='Expected End'>
                {formatDate(spaceState.expectedEndAtUtc)}
              </Descriptions.Item>
            )}
            {spaceState?.pendingQueueItemId && (
              <Descriptions.Item label='Pending Track'>
                <Badge
                  status='processing'
                  text={spaceState.pendingQueueItemId}
                />
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* Audio Mixer State */}
          <Descriptions
            title='Audio Mixer'
            column={1}
            bordered
          >
            <Descriptions.Item label='Volume'>
              {spaceState?.volumePercent ?? 100}%
            </Descriptions.Item>
            <Descriptions.Item label='Muted'>
              {spaceState?.isMuted ? (
                <Tag color='error'>Yes</Tag>
              ) : (
                <Tag color='success'>No</Tag>
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Queue End Behavior'>
              {spaceState?.queueEndBehavior === 0 && <Tag>Stop</Tag>}
              {spaceState?.queueEndBehavior === 1 && (
                <Tag color='blue'>Repeat Queue</Tag>
              )}
              {spaceState?.queueEndBehavior === 2 && (
                <Tag color='purple'>Return to Schedule</Tag>
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Queue Items'>
              {spaceState?.spaceQueueItems?.length || 0} track(s)
            </Descriptions.Item>
          </Descriptions>

          {/* Streaming Info */}
          {spaceState?.hlsUrl && (
            <Descriptions
              title='Streaming Info'
              column={1}
              bordered
            >
              <Descriptions.Item label='HLS URL'>
                <a
                  href={spaceState.hlsUrl}
                  target='_blank'
                  rel='noopener noreferrer'
                >
                  {spaceState.hlsUrl}
                </a>
              </Descriptions.Item>
            </Descriptions>
          )}

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Space ID'>
              <Tag>{space.id}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Created At'>
              {formatDate(space.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {space.updatedAt ? formatDate(space.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
