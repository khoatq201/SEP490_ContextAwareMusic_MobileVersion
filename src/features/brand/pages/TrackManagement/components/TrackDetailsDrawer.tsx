import {
  Drawer,
  Descriptions,
  Tag,
  Progress,
  Space,
  Spin,
  Flex,
  Typography,
} from 'antd';

/**
 * Hooks
 */
import {
  useTrack,
  useTrackMetadataPolling,
} from '@/shared/modules/tracks/hooks';

/**
 * Components
 */
import {
  HLSAudioPlayer,
  MetadataStatusBadge,
  MetadataPollingProgress,
} from '@/shared/modules/tracks/components';

/**
 * Utils
 */
import { formatDateTime, formatDuration } from '@/shared/utils';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS, ENTITY_STATUS_COLORS } from '@/shared/constants';
import {
  MUSIC_PROVIDER_LABELS,
  MUSIC_PROVIDER_COLORS,
} from '@/shared/modules/tracks/constants';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

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
  const { data: track, isLoading } = useTrack(trackId, open);

  // Auto-poll metadata status for newly uploaded tracks
  const { isPolling, attempts, maxAttempts, status } = useTrackMetadataPolling(
    trackId,
    {
      enabled: open && !!trackId,
    },
  );

  return (
    <Drawer
      closeIcon={null}
      title='Track Details'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={onClose}
    >
      {isLoading ? (
        <Flex
          justify='center'
          align='center'
          style={{ minHeight: 400 }}
        >
          <Spin size='large' />
        </Flex>
      ) : track ? (
        <Space
          direction='vertical'
          style={{ width: '100%' }}
          size='large'
        >
          {/* Metadata Polling Progress */}
          <MetadataPollingProgress
            isPolling={isPolling}
            attempts={attempts}
            maxAttempts={maxAttempts}
            status={status}
          />

          {/* Audio Player */}
          {track.hlsUrl && (
            <div>
              <Title
                level={5}
                className='mb-4!'
              >
                Audio Player
              </Title>
              <HLSAudioPlayer
                hlsUrl={track.hlsUrl}
                title={track.title}
                artist={track.artist}
                coverImageUrl={track.coverImageUrl}
              />
            </div>
          )}

          {/* Basic Info */}
          <Descriptions
            title='Basic Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Title'>{track.title}</Descriptions.Item>
            <Descriptions.Item label='Artist'>
              {track.artist || '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Genre'>
              {track.genre ? <Tag>{track.genre}</Tag> : '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Mood'>
              {track.moodName ? <Tag color='blue'>{track.moodName}</Tag> : '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Provider'>
              {track.provider !== undefined ? (
                <Tag color={MUSIC_PROVIDER_COLORS[track.provider]}>
                  {MUSIC_PROVIDER_LABELS[track.provider]}
                </Tag>
              ) : (
                '-'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Status'>
              <Tag color={ENTITY_STATUS_COLORS[track.status]}>
                {ENTITY_STATUS_LABELS[track.status]}
              </Tag>
            </Descriptions.Item>
          </Descriptions>

          {/* Audio Metadata */}
          <Descriptions
            title='Audio Metadata'
            column={1}
            bordered
            extra={
              <MetadataStatusBadge
                track={track}
                showDetails
              />
            }
          >
            <Descriptions.Item label='Duration'>
              {formatDuration(track.durationSec)}
            </Descriptions.Item>
            <Descriptions.Item label='BPM'>
              {track.bpm || '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Energy Level'>
              {track.energyLevel !== undefined ? (
                <div>
                  <Progress
                    percent={track.energyLevel * 100}
                    format={(percent) => `${(percent! / 100).toFixed(1)}`}
                    strokeColor='#52c41a'
                  />
                </div>
              ) : (
                '-'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Valence'>
              {track.valence !== undefined ? (
                <div>
                  <Progress
                    percent={track.valence * 100}
                    format={(percent) => `${(percent! / 100).toFixed(1)}`}
                    strokeColor='#1890ff'
                  />
                </div>
              ) : (
                '-'
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* Statistics */}
          <Descriptions
            title='Statistics'
            column={1}
            bordered
          >
            <Descriptions.Item label='Play Count'>
              {track.playCount}
            </Descriptions.Item>
            <Descriptions.Item label='Last Played'>
              {track.lastPlayedAt
                ? formatDateTime(track.lastPlayedAt)
                : 'Never'}
            </Descriptions.Item>
          </Descriptions>

          {/* AI Generated Info */}
          {track.isAiGenerated && (
            <Descriptions
              title='AI Generation Info'
              column={1}
              bordered
            >
              <Descriptions.Item label='Suno Clip ID'>
                {track.sunoClipId || '-'}
              </Descriptions.Item>
              <Descriptions.Item label='Generation Prompt'>
                {track.generationPrompt || '-'}
              </Descriptions.Item>
              <Descriptions.Item label='Generated At'>
                {track.generatedAt ? formatDateTime(track.generatedAt) : '-'}
              </Descriptions.Item>
              <Descriptions.Item label='Lyrics URL'>
                {track.lyricsUrl ? (
                  <a
                    href={track.lyricsUrl}
                    target='_blank'
                    rel='noreferrer'
                  >
                    View Lyrics
                  </a>
                ) : (
                  '-'
                )}
              </Descriptions.Item>
            </Descriptions>
          )}

          {/* Timestamps */}
          <Descriptions
            title='Timestamps'
            column={1}
            bordered
          >
            <Descriptions.Item label='Created At'>
              {formatDateTime(track.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {track.updatedAt ? formatDateTime(track.updatedAt) : '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Created By'>
              {track.createdBy || '-'}
            </Descriptions.Item>
            <Descriptions.Item label='Updated By'>
              {track.updatedBy || '-'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      ) : (
        <div style={{ textAlign: 'center', padding: 40 }}>Track not found</div>
      )}
    </Drawer>
  );
};
