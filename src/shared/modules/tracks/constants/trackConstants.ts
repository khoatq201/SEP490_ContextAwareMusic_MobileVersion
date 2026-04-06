import type { SelectProps } from 'antd';
import { MusicProviderEnum } from '../types';

/**
 * Music Provider Options (for Select dropdown)
 */
export const MUSIC_PROVIDER_OPTIONS: SelectProps['options'] = [
  { label: 'Custom Upload', value: MusicProviderEnum.Custom },
  { label: 'AI Generated (Suno)', value: MusicProviderEnum.Suno },
];

/**
 * Music Provider Labels (for display)
 */
export const MUSIC_PROVIDER_LABELS: Record<MusicProviderEnum, string> = {
  [MusicProviderEnum.Custom]: 'Custom',
  [MusicProviderEnum.Suno]: 'Suno AI',
};

/**
 * Music Provider Colors (for Tag component)
 */
export const MUSIC_PROVIDER_COLORS: Record<MusicProviderEnum, string> = {
  [MusicProviderEnum.Custom]: 'blue',
  [MusicProviderEnum.Suno]: 'purple',
};

/**
 * Allowed Audio File Extensions (from API_Tracks.md §4.1)
 */
export const AUDIO_FILE_EXTENSIONS = [
  '.mp3',
  '.wav',
  '.aac',
  '.flac',
  '.ogg',
  '.m4a',
];

/**
 * Allowed Image File Extensions (from API_Tracks.md §4.1)
 */
export const IMAGE_FILE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];

/**
 * Max File Sizes (from API_Tracks.md §4.1)
 */
export const MAX_AUDIO_SIZE = 50 * 1024 * 1024; // 50MB in bytes
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB in bytes

/**
 * Common Genre Options (preset list for convenience)
 */
export const GENRE_OPTIONS: SelectProps['options'] = [
  { label: 'Pop', value: 'Pop' },
  { label: 'Rock', value: 'Rock' },
  { label: 'Jazz', value: 'Jazz' },
  { label: 'Classical', value: 'Classical' },
  { label: 'Electronic', value: 'Electronic' },
  { label: 'Hip Hop', value: 'Hip Hop' },
  { label: 'R&B', value: 'R&B' },
  { label: 'Country', value: 'Country' },
  { label: 'Folk', value: 'Folk' },
  { label: 'Latin', value: 'Latin' },
  { label: 'Ambient', value: 'Ambient' },
  { label: 'Lo-fi', value: 'Lo-fi' },
  { label: 'Indie', value: 'Indie' },
  { label: 'Blues', value: 'Blues' },
  { label: 'Reggae', value: 'Reggae' },
];

/**
 * Audio File Type MIME mapping
 */
export const AUDIO_MIME_TYPES: Record<string, string> = {
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.aac': 'audio/aac',
  '.flac': 'audio/flac',
  '.ogg': 'audio/ogg',
  '.m4a': 'audio/mp4',
};

/**
 * Image File Type MIME mapping
 */
export const IMAGE_MIME_TYPES: Record<string, string> = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};
