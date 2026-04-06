import type { TrackDetailResponse, TrackListItem } from '../types';
import { TrackMetadataStatus, TranscodeStatusEnum } from '../types';

/**
 * Determine metadata extraction status based on track fields
 * See: docs/cams/FE_IMPLEMENTATION_METADATA_TO_FUZZY_AI.md §2.3
 *
 * IMPORTANT: In list view, backend only returns transcodeStatus (not metadata fields).
 * Metadata fields (bpm, energyLevel, valence) are only available in detail view.
 *
 * @param track - Track object (list item or detail)
 * @returns Metadata status enum
 */
export const getTrackMetadataStatus = (
  track: TrackListItem | TrackDetailResponse,
): TrackMetadataStatus => {
  // Check if this is a detail response with metadata fields
  const detailTrack = track as TrackDetailResponse;

  const hasBpm =
    detailTrack.bpm !== null &&
    detailTrack.bpm !== undefined &&
    detailTrack.bpm > 0;
  const hasEnergyLevel =
    detailTrack.energyLevel !== null && detailTrack.energyLevel !== undefined;
  const hasValence =
    detailTrack.valence !== null && detailTrack.valence !== undefined;

  // If we have metadata fields (detail view), use them
  if (hasBpm || hasEnergyLevel || hasValence) {
    // Ready: has all three metadata fields
    if (hasBpm && hasEnergyLevel && hasValence) {
      return TrackMetadataStatus.Ready;
    }
    // Partial: has some but not all metadata
    return TrackMetadataStatus.Partial;
  }

  // For list view, use transcodeStatus as proxy for metadata status
  // transcodeStatus: 0=None, 1=Pending, 2=Processing, 3=Ready, 4=Failed
  if (track.transcodeStatus !== undefined && track.transcodeStatus !== null) {
    switch (track.transcodeStatus) {
      case TranscodeStatusEnum.Ready:
        // Transcode complete, but we don't know metadata status in list view
        // Assume Ready if transcode is done (metadata extraction happens during transcode)
        return TrackMetadataStatus.Ready;

      case TranscodeStatusEnum.Pending:
      case TranscodeStatusEnum.Processing:
        // Still transcoding, metadata not ready yet
        return TrackMetadataStatus.Pending;

      case TranscodeStatusEnum.Failed:
        // Transcode failed, metadata likely unavailable
        return TrackMetadataStatus.Unknown;

      case TranscodeStatusEnum.None:
      default:
        // Not yet transcoded, check age
        break;
    }
  }

  // Fallback: check track age for newly created tracks
  const createdAt = new Date(track.createdAt);
  const now = new Date();
  const ageInMinutes = (now.getTime() - createdAt.getTime()) / 1000 / 60;

  // Pending if created within last 2 minutes
  if (ageInMinutes < 2) {
    return TrackMetadataStatus.Pending;
  }

  // Unknown if older than 2 minutes and still no metadata
  return TrackMetadataStatus.Unknown;
};

/**
 * Format BPM value for display
 * @param bpm - BPM value
 * @returns Formatted string or fallback
 */
export const formatBpm = (bpm?: number | null): string => {
  if (bpm === null || bpm === undefined || bpm === 0) {
    return '—';
  }
  return `${Math.round(bpm)} BPM`;
};

/**
 * Format energy level for display (0.0 - 1.0)
 * @param energyLevel - Energy level value
 * @returns Formatted string or fallback
 */
export const formatEnergyLevel = (energyLevel?: number | null): string => {
  if (energyLevel === null || energyLevel === undefined) {
    return '—';
  }
  return energyLevel.toFixed(2);
};

/**
 * Format valence for display (0.0 - 1.0)
 * @param valence - Valence value
 * @returns Formatted string or fallback
 */
export const formatValence = (valence?: number | null): string => {
  if (valence === null || valence === undefined) {
    return '—';
  }
  return valence.toFixed(2);
};

/**
 * Get metadata status badge color
 * @param status - Metadata status
 * @returns Ant Design badge status
 */
export const getMetadataStatusBadgeColor = (
  status: TrackMetadataStatus,
): 'success' | 'processing' | 'warning' | 'error' => {
  switch (status) {
    case TrackMetadataStatus.Ready:
      return 'success';
    case TrackMetadataStatus.Pending:
      return 'processing';
    case TrackMetadataStatus.Partial:
      return 'warning';
    case TrackMetadataStatus.Unknown:
      return 'error';
    default:
      return 'error';
  }
};

/**
 * Get metadata status display text
 * @param status - Metadata status
 * @returns Display text
 */
export const getMetadataStatusText = (status: TrackMetadataStatus): string => {
  switch (status) {
    case TrackMetadataStatus.Ready:
      return 'Metadata Ready';
    case TrackMetadataStatus.Pending:
      return 'Extracting Metadata...';
    case TrackMetadataStatus.Partial:
      return 'Partial Metadata';
    case TrackMetadataStatus.Unknown:
      return 'Metadata Unavailable';
    default:
      return 'Unknown';
  }
};

/**
 * Get transcode status display text
 * @param status - Transcode status enum value
 * @returns Display text
 */
export const getTranscodeStatusText = (
  status?: TranscodeStatusEnum,
): string => {
  if (status === undefined || status === null) {
    return 'Unknown';
  }

  switch (status) {
    case TranscodeStatusEnum.None:
      return 'Not Transcoded';
    case TranscodeStatusEnum.Pending:
      return 'Queued';
    case TranscodeStatusEnum.Processing:
      return 'Transcoding...';
    case TranscodeStatusEnum.Ready:
      return 'Ready';
    case TranscodeStatusEnum.Failed:
      return 'Failed';
    default:
      return 'Unknown';
  }
};
