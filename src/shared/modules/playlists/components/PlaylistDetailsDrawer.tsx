import {
  Drawer,
  Descriptions,
  Tag,
  Spin,
  Alert,
  Space,
  List,
  Button,
  Popconfirm,
  Typography,
} from 'antd';

/**
 * Icons
 */
import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  DeleteOutlined,
  PlayCircleOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import { usePlaylist, useRemoveTrackFromPlaylist } from '../hooks';

/**
 * Constants
 */
import { ENTITY_STATUS_LABELS } from '@/shared/constants';

/**
 * Utils
 */
import { formatDuration, formatDate } from '@/shared/utils';

/**
 * Types
 */
import type { PlaylistTrackItem } from '../types';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Text } = Typography;

interface PlaylistDetailsDrawerProps {
  open: boolean;
  playlistId?: string;
  onClose: () => void;
  readOnly?: boolean;
}

export const PlaylistDetailsDrawer = ({
  open,
  playlistId,
  onClose,
  readOnly = false,
}: PlaylistDetailsDrawerProps) => {
  const {
    data: playlist,
    isLoading,
    error,
    refetch,
  } = usePlaylist(playlistId, open);

  const removeTrack = useRemoveTrackFromPlaylist();

  const handleRemoveTrack = (trackId: string) => {
    if (!playlistId) return;

    removeTrack.mutate(
      { id: playlistId, trackId },
      {
        onSuccess: () => refetch(),
      },
    );
  };

  return (
    <Drawer
      closeIcon={null}
      title='Playlist Details'
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
          description='Failed to load playlist details. Please try again.'
          type='error'
          showIcon
        />
      )}

      {playlist && (
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
            <Descriptions.Item label='Name'>{playlist.name}</Descriptions.Item>
            <Descriptions.Item label='Store'>
              {playlist.storeName || '—'}
            </Descriptions.Item>
            <Descriptions.Item label='Mood'>
              {playlist.moodName ? (
                <Tag color='blue'>{playlist.moodName}</Tag>
              ) : (
                '—'
              )}
            </Descriptions.Item>
            <Descriptions.Item label='Default Playlist'>
              {playlist.isDefault ? <Tag color='gold'>Yes</Tag> : <Tag>No</Tag>}
            </Descriptions.Item>
            <Descriptions.Item label='Status'>
              <Tag
                icon={
                  playlist.status === 1 ? (
                    <CheckCircleOutlined />
                  ) : (
                    <CloseCircleOutlined />
                  )
                }
                color={playlist.status === 1 ? 'success' : 'default'}
              >
                {ENTITY_STATUS_LABELS[playlist.status]}
              </Tag>
            </Descriptions.Item>
            {playlist.description && (
              <Descriptions.Item label='Description'>
                {playlist.description}
              </Descriptions.Item>
            )}
          </Descriptions>

          {/* Playlist Statistics */}
          <Descriptions
            title='Statistics'
            column={1}
            bordered
          >
            <Descriptions.Item label='Total Tracks'>
              {playlist.trackCount}
            </Descriptions.Item>
          </Descriptions>

          {/* Track List */}
          <Descriptions
            title={`Tracks (${playlist.tracks.length})`}
            column={1}
            bordered
            layout='vertical'
          >
            <Descriptions.Item label='Tracks'>
              {playlist.tracks.length > 0 ? (
                <List
                  dataSource={playlist.tracks}
                  renderItem={(track: PlaylistTrackItem, index) => (
                    <List.Item
                      actions={
                        !readOnly
                          ? [
                              <Popconfirm
                                title='Remove track from playlist?'
                                description='This action cannot be undone.'
                                onConfirm={() =>
                                  handleRemoveTrack(track.trackId)
                                }
                                okText='Remove'
                                cancelText='Cancel'
                                okButtonProps={{ danger: true }}
                              >
                                <Button
                                  type='text'
                                  danger
                                  icon={<DeleteOutlined />}
                                  loading={removeTrack.isPending}
                                />
                              </Popconfirm>,
                            ]
                          : []
                      }
                    >
                      <List.Item.Meta
                        avatar={
                          track.coverImageUrl ? (
                            <img
                              src={track.coverImageUrl}
                              alt={track.title}
                              style={{
                                width: 48,
                                height: 48,
                                borderRadius: 4,
                                objectFit: 'cover',
                              }}
                            />
                          ) : (
                            <div
                              style={{
                                width: 48,
                                height: 48,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                background: '#f0f0f0',
                                borderRadius: 4,
                              }}
                            >
                              <PlayCircleOutlined style={{ fontSize: 20 }} />
                            </div>
                          )
                        }
                        title={
                          <Space>
                            <Text strong>#{index + 1}</Text>
                            <Text>{track.title}</Text>
                          </Space>
                        }
                        description={
                          <Space split='•'>
                            {track.artist && (
                              <Text type='secondary'>{track.artist}</Text>
                            )}
                            {track.durationSec && (
                              <Text type='secondary'>
                                {formatDuration(track.durationSec)}
                              </Text>
                            )}
                            <Text type='secondary'>
                              Offset: {formatDuration(track.seekOffsetSeconds)}
                            </Text>
                          </Space>
                        }
                      />
                    </List.Item>
                  )}
                />
              ) : (
                <Alert
                  message='No tracks in this playlist'
                  description='Add tracks to start building your playlist.'
                  type='info'
                  showIcon
                />
              )}
            </Descriptions.Item>
          </Descriptions>

          {/* System Information */}
          <Descriptions
            title='System Information'
            column={1}
            bordered
          >
            <Descriptions.Item label='Created At'>
              {formatDate(playlist.createdAt)}
            </Descriptions.Item>
            <Descriptions.Item label='Updated At'>
              {playlist.updatedAt ? formatDate(playlist.updatedAt) : '—'}
            </Descriptions.Item>
          </Descriptions>
        </Space>
      )}
    </Drawer>
  );
};
