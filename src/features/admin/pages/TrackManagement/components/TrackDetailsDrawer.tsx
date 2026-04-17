import {
  Drawer,
  Descriptions,
  Tag,
  Spin,
  Alert,
  Space,
  Button,
  Flex,
} from 'antd';

/**
 * Icons
 */
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  RobotOutlined,
  UserOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import {
  useTrack,
  useSetTrackCopyrightClearance,
  useTrackMetadataPolling,
} from '@/shared/modules/tracks/hooks';
import { AppModal } from '@/shared/components';

/**
 * Components
 */
import {
  HLSAudioPlayer,
  MetadataStatusBadge,
  MetadataPollingProgress,
} from '@/shared/modules/tracks/components';

/**
 * Constants
 */
import {
  COPYRIGHT_CLEARANCE_COLORS,
  COPYRIGHT_CLEARANCE_LABELS,
  MUSIC_PROVIDER_LABELS,
  MUSIC_PROVIDER_COLORS,
} from '@/shared/modules/tracks/constants';
import { ENTITY_STATUS_LABELS } from '@/shared/constants';
import { TrackCopyrightClearanceStatus } from '@/shared/modules/tracks/types';

/**
 * Utils
 */
import { formatDate } from '@/shared/utils';
import {
  getTrackPlaybackBlockedMessage,
  isTrackPlaybackBlockedByCopyright,
} from '@/shared/modules/tracks/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

interface TrackDetailsDrawerProps {
  open: boolean;
  trackId?: string;
  onClose: () => void;
}

export const TrackDetailsDrawer = ({
  open,
  trackId,
  onClose,
}: TrackDetailsDrawerProps) => {
  const { data: track, isLoading, error } = useTrack(trackId, open);
  const setTrackCopyrightClearance = useSetTrackCopyrightClearance();
  const isCopyrightBlocked = isTrackPlaybackBlockedByCopyright(
    track?.copyrightClearanceStatus,
  );
  const blockedMessage = getTrackPlaybackBlockedMessage(
    track?.copyrightClearanceStatus,
  );

  // Auto-poll metadata status for newly uploaded tracks
  const { isPolling, attempts, maxAttempts, status } = useTrackMetadataPolling(
    trackId,
    {
      enabled: open && !!trackId,
    },
  );

  const canReviewCopyright =
    track?.copyrightClearanceStatus ===
      TrackCopyrightClearanceStatus.PendingScan ||
    track?.copyrightClearanceStatus ===
      TrackCopyrightClearanceStatus.PendingReview;

  const handleSetCopyrightClearance = (approve: boolean) => {
    if (!track?.id || setTrackCopyrightClearance.isPending) {
      return;
    }

    AppModal.confirm({
      title: approve
        ? 'Approve Copyright Clearance'
        : 'Reject Copyright Clearance',
      content: approve
        ? 'Approve this track so it can be streamed again?'
        : 'Reject this track and keep it blocked from playback?',
      okText: approve ? 'Approve' : 'Reject',
      okButtonProps: { danger: !approve },
      onOk: () =>
        setTrackCopyrightClearance.mutate({
          id: track.id,
          approve,
        }),
    });
  };

  return (
    <Drawer
      closeIcon={null}
      title='Track Details'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={onClose}
    >
      {isLoading && (
        <div style={{ textAlign: 'center', padding: 48 }}>
          <Spin size='large' />
        </div>
      )}

      {error && (
        <Alert
          message='Error'
          description='Failed to load track details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {track && (
        <Space
          direction='vertical'
          size='large'
          style={{ width: '100%' }}
        >
          {/* Metadata Polling Progress */}
          <MetadataPollingProgress
            isPolling={isPolling}
            attempts={attempts}
            maxAttempts={maxAttempts}
            status={status}
          />

          {isCopyrightBlocked && (
            <Alert
              type={
                track?.copyrightClearanceStatus ===
                TrackCopyrightClearanceStatus.PendingScan
                  ? 'warning'
                  : 'error'
              }
              showIcon
              message='Playback blocked by copyright policy'
              description={blockedMessage}
            />
          )}

          {canReviewCopyright && (
            <Flex
              justify='end'
              gap='small'
            >
              <Button
                size='large'
                danger
                onClick={() => handleSetCopyrightClearance(false)}
                loading={setTrackCopyrightClearance.isPending}
              >
                Reject Track
              </Button>
              <Button
                size='large'
                type='primary'
                onClick={() => handleSetCopyrightClearance(true)}
                loading={setTrackCopyrightClearance.isPending}
              >
                Approve Track
              </Button>
            </Flex>
          )}

          {/* Audio Player */}
          <HLSAudioPlayer
            hlsUrl={track.hlsUrl}
            title={track.title}
            artist={track.artist}
            coverImageUrl={track.coverImageUrl}
            unavailableMessage={isCopyrightBlocked ? blockedMessage : undefined}
            disabled={isCopyrightBlocked}
          />

          {/* Basic Information */}

          <Descriptions
            title='Basic Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Title'>{track.title}</Descriptions.Item>
            <Descriptions.Item label='Artist'>
              {track.artist || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Genre'>
              {track.genre || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Mood'>
              {track.moodName || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Provider'>
              <Tag color={MUSIC_PROVIDER_COLORS[track.provider || 0]}>
                {MUSIC_PROVIDER_LABELS[track.provider || 0]}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Type'>
              <Tag
                icon={
                  track.isAiGenerated ? <RobotOutlined /> : <UserOutlined />
                }
                color={track.isAiGenerated ? 'purple' : 'blue'}
              >
                {track.isAiGenerated ? 'AI Generated' : 'Custom Upload'}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Status'>
              <Tag
                icon={
                  track.status === 1 ? (
                    <CheckCircleOutlined />
                  ) : (
                    <CloseCircleOutlined />
                  )
                }
                color={track.status === 1 ? 'success' : 'default'}
              >
                {ENTITY_STATUS_LABELS[track.status]}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label='Copyright'>
              <Tag
                color={
                  COPYRIGHT_CLEARANCE_COLORS[
                    track.copyrightClearanceStatus ??
                      TrackCopyrightClearanceStatus.Cleared
                  ]
                }
              >
                {
                  COPYRIGHT_CLEARANCE_LABELS[
                    track.copyrightClearanceStatus ??
                      TrackCopyrightClearanceStatus.Cleared
                  ]
                }
              </Tag>
            </Descriptions.Item>
          </Descriptions>

          {/* Audio Metadata */}
          <Descriptions
            title='Audio Metadata'
            column={2}
            bordered
            extra={
              <MetadataStatusBadge
                track={track}
                showDetails
              />
            }
          >
            <Descriptions.Item label='Duration'>
              {track.durationSec
                ? `${Math.floor(track.durationSec / 60)}:${(
                    track.durationSec % 60
                  )
                    .toString()
                    .padStart(2, '0')}`
                : '—'}
            </Descriptions.Item>
            <Descriptions.Item label='BPM'>
              {track.bpm || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Energy Level'>
              {track.energyLevel?.toFixed(2) || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Valence'>
              {track.valence?.toFixed(2) || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Play Count'>
              {track.playCount}
            </Descriptions.Item>
            <Descriptions.Item label='Last Played'>
              {track.lastPlayedAt ? formatDate(track.lastPlayedAt) : 'Never'}
            </Descriptions.Item>
          </Descriptions>

          {/* AI Generation Info (if applicable) */}
          {track.isAiGenerated && (
            <Descriptions
              title='AI Generation Info'
              column={1}
              bordered
            >
              <Descriptions.Item label='Suno Clip ID'>
                {track.sunoClipId || '—'}
              </Descriptions.Item>
              <Descriptions.Item label='Generation Prompt'>
                {track.generationPrompt || '—'}
              </Descriptions.Item>
              <Descriptions.Item label='Generated At'>
                {track.generatedAt ? formatDate(track.generatedAt) : '—'}
              </Descriptions.Item>
            </Descriptions>
          )}

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Created At'>
              {formatDate(track.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {track.updatedAt ? formatDate(track.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
