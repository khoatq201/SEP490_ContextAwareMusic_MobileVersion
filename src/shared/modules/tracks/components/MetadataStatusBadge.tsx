import { Badge, Space, Tag, Tooltip } from 'antd';
import {
  CheckCircleOutlined,
  ClockCircleOutlined,
  ExclamationCircleOutlined,
  WarningOutlined,
  LoadingOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import type { TrackDetailResponse, TrackListItem } from '../types';
import { TrackMetadataStatus, TranscodeStatusEnum } from '../types';
import {
  getTrackMetadataStatus,
  getMetadataStatusText,
  formatBpm,
  formatEnergyLevel,
  formatValence,
} from '../utils';

interface MetadataStatusBadgeProps {
  track: TrackListItem | TrackDetailResponse;
  showDetails?: boolean; // Show BPM, Energy, Valence tags when ready
}

export const MetadataStatusBadge = ({
  track,
  showDetails = false,
}: MetadataStatusBadgeProps) => {
  const status = getTrackMetadataStatus(track);
  const detailTrack = track as TrackDetailResponse;

  // Show transcode status if available (list view)
  const transcodeStatus = track.transcodeStatus;
  const showTranscodeInfo =
    transcodeStatus !== undefined &&
    transcodeStatus !== TranscodeStatusEnum.Ready;

  // Ready status with details (detail view only)
  if (status === TrackMetadataStatus.Ready && showDetails) {
    return (
      <Space size='small'>
        <Tooltip title='Metadata extraction completed'>
          <Tag
            icon={<CheckCircleOutlined />}
            color='success'
          >
            BPM: {formatBpm(detailTrack.bpm)}
          </Tag>
        </Tooltip>
        <Tooltip title='Energy level (0.0 = calm, 1.0 = energetic)'>
          <Tag color='blue'>
            Energy: {formatEnergyLevel(detailTrack.energyLevel)}
          </Tag>
        </Tooltip>
        <Tooltip title='Valence (0.0 = sad, 1.0 = happy)'>
          <Tag color='cyan'>Valence: {formatValence(detailTrack.valence)}</Tag>
        </Tooltip>
      </Space>
    );
  }

  // Ready status without details
  if (status === TrackMetadataStatus.Ready) {
    return (
      <Tooltip title={getMetadataStatusText(status)}>
        <Badge
          status='success'
          text='Ready'
        />
      </Tooltip>
    );
  }

  // Pending status - show transcode info if available
  if (status === TrackMetadataStatus.Pending) {
    if (showTranscodeInfo) {
      // Show specific transcode status
      if (transcodeStatus === TranscodeStatusEnum.Pending) {
        return (
          <Tooltip title='Track is queued for transcoding'>
            <Badge
              status='processing'
              text={
                <Space size={4}>
                  <ClockCircleOutlined />
                  <span>Queued</span>
                </Space>
              }
            />
          </Tooltip>
        );
      }
      if (transcodeStatus === TranscodeStatusEnum.Processing) {
        return (
          <Tooltip title='Track is being transcoded (may take 1-3 minutes)'>
            <Badge
              status='processing'
              text={
                <Space size={4}>
                  <LoadingOutlined />
                  <span>Transcoding...</span>
                </Space>
              }
            />
          </Tooltip>
        );
      }
    }

    // Generic pending message
    return (
      <Tooltip title='Metadata extraction in progress (may take 30-120 seconds)'>
        <Badge
          status='processing'
          text={
            <Space size={4}>
              <ClockCircleOutlined />
              <span>Processing...</span>
            </Space>
          }
        />
      </Tooltip>
    );
  }

  // Partial status
  if (status === TrackMetadataStatus.Partial) {
    return (
      <Tooltip title='Some metadata fields are missing'>
        <Badge
          status='warning'
          text={
            <Space size={4}>
              <WarningOutlined />
              <span>Partial</span>
            </Space>
          }
        />
      </Tooltip>
    );
  }

  // Unknown/Failed status - check transcode status
  if (showTranscodeInfo && transcodeStatus === TranscodeStatusEnum.Failed) {
    return (
      <Tooltip title='Transcode failed - metadata unavailable'>
        <Badge
          status='error'
          text={
            <Space size={4}>
              <CloseCircleOutlined />
              <span>Failed</span>
            </Space>
          }
        />
      </Tooltip>
    );
  }

  // Unknown status (default)
  return (
    <Tooltip title='Metadata extraction failed or not yet started'>
      <Badge
        status='error'
        text={
          <Space size={4}>
            <ExclamationCircleOutlined />
            <span>Unavailable</span>
          </Space>
        }
      />
    </Tooltip>
  );
};
