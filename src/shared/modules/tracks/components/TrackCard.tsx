import { Card, Space, Typography, Tag, Image } from 'antd';
import { MusicIcon } from 'lucide-react';

/**
 * Utils
 */
import { formatDuration } from '@/shared/utils';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS, ENTITY_STATUS_COLORS } from '@/shared/constants';
import {
  MUSIC_PROVIDER_LABELS,
  MUSIC_PROVIDER_COLORS,
} from '@/shared/modules/tracks/constants';

/**
 * Types
 */
import type { TrackListItem } from '@/shared/modules/tracks/types';

const { Text, Title } = Typography;

interface TrackCardProps {
  track: TrackListItem;
  onClick?: () => void;
}

export const TrackCard = ({ track, onClick }: TrackCardProps) => {
  return (
    <Card
      hoverable={!!onClick}
      onClick={onClick}
      cover={
        <div
          style={{
            width: '100%',
            height: 200,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            background: '#f0f0f0',
          }}
        >
          {track.coverImageUrl ? (
            <Image
              src={track.coverImageUrl}
              alt={track.title}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              preview={false}
            />
          ) : (
            <MusicIcon style={{ fontSize: 48, color: '#999' }} />
          )}
        </div>
      }
    >
      <Space
        direction='vertical'
        style={{ width: '100%' }}
        size='small'
      >
        <Title
          level={5}
          style={{ margin: 0 }}
          ellipsis
        >
          {track.title}
        </Title>

        {track.artist && (
          <Text
            type='secondary'
            ellipsis
          >
            {track.artist}
          </Text>
        )}

        <Space wrap>
          {track.genre && <Tag>{track.genre}</Tag>}
          {track.moodName && <Tag color='blue'>{track.moodName}</Tag>}
          {track.provider !== undefined && (
            <Tag color={MUSIC_PROVIDER_COLORS[track.provider]}>
              {MUSIC_PROVIDER_LABELS[track.provider]}
            </Tag>
          )}
        </Space>

        <Space style={{ width: '100%', justifyContent: 'space-between' }}>
          <Text type='secondary'>{formatDuration(track.durationSec)}</Text>
          <Tag color={ENTITY_STATUS_COLORS[track.status]}>
            {ENTITY_STATUS_LABELS[track.status]}
          </Tag>
        </Space>
      </Space>
    </Card>
  );
};
