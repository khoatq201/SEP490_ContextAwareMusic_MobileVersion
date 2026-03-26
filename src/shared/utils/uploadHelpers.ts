import { Upload, message } from 'antd';
import type { UploadFile, UploadProps, RcFile } from 'antd/es/upload/interface';
import {
  AUDIO_FILE_EXTENSIONS,
  MAX_AUDIO_SIZE,
} from '@/shared/modules/tracks/constants';

/**
 * Allowed image MIME types
 */
export const ALLOWED_IMAGE_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/bmp',
  'image/svg+xml',
] as const;

/**
 * Max file size: 5MB
 */
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024;

/**
 * Accept attribute for Upload component
 */
export const IMAGE_ACCEPT = ALLOWED_IMAGE_TYPES.join(',');

/**
 * Validate image file type
 */
export const validateImageType = (file: File): boolean => {
  if (!ALLOWED_IMAGE_TYPES.includes(file.type as any)) {
    message.error(
      'File must be an image (jpg, jpeg, png, gif, webp, bmp, svg)',
    );
    return false;
  }
  return true;
};

/**
 * Validate image file size
 */
export const validateImageSize = (
  file: File,
  maxSize = MAX_IMAGE_SIZE,
): boolean => {
  if (file.size > maxSize) {
    message.error(`File size must not exceed ${maxSize / (1024 * 1024)}MB`);
    return false;
  }
  return true;
};

/**
 * Complete image validation
 */
export const validateImageFile = (file: File): boolean => {
  return validateImageType(file) && validateImageSize(file);
};

/**
 * Create upload props for image dragger
 */
export const createImageUploadProps = <T extends Record<string, any>>(
  onFileChange: (file: UploadFile | null) => void,
  onFormFieldChange?: (fieldName: keyof T, value: any) => void, // ✅ Keep generic string type
): UploadProps => ({
  maxCount: 1,
  beforeUpload: (file: RcFile) => {
    // ✅ Use RcFile instead of File
    if (!validateImageFile(file)) {
      return Upload.LIST_IGNORE;
    }

    // RcFile already has uid property
    onFileChange({
      uid: file.uid,
      name: file.name,
      originFileObj: file,
    } as UploadFile);

    return false; // Prevent auto upload
  },
  onRemove: () => {
    onFileChange(null);
    if (onFormFieldChange) {
      onFormFieldChange('logo', undefined);
    }
  },
  accept: IMAGE_ACCEPT,
  listType: 'picture',
});

/**
 * Validate audio file (extension + size)
 */
export const validateAudioFile = (file: File): boolean => {
  const extension = file.name.slice(file.name.lastIndexOf('.')).toLowerCase();

  if (!AUDIO_FILE_EXTENSIONS.includes(extension)) {
    message.error(
      `Invalid audio format. Allowed: ${AUDIO_FILE_EXTENSIONS.join(', ')}`,
    );
    return false;
  }

  if (file.size > MAX_AUDIO_SIZE) {
    message.error('Audio file size cannot exceed 50MB!');
    return false;
  }

  return true;
};

/**
 * Create audio upload props with validation
 */
export const createAudioUploadProps = <T extends Record<string, any>>(
  setFile: (file: UploadFile | null) => void,
  setFieldValue: (field: keyof T, value: any) => void,
): UploadProps => ({
  name: 'audioFile',
  accept: AUDIO_FILE_EXTENSIONS.join(','),
  maxCount: 1,
  beforeUpload: (file) => {
    if (validateAudioFile(file)) {
      const uploadFile: UploadFile = {
        uid: file.uid,
        name: file.name,
        status: 'done',
        originFileObj: file,
      };
      setFile(uploadFile);
      setFieldValue('audioFile' as keyof T, file);
    }
    return false;
  },
  onRemove: () => {
    setFile(null);
    setFieldValue('audioFile' as keyof T, null);
  },
});

/**
 * Format audio duration (seconds to mm:ss)
 */
export const formatDuration = (seconds?: number): string => {
  if (!seconds) return '--:--';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

/**
 * Format file size (bytes to human-readable)
 */
export const formatFileSize = (bytes?: number): string => {
  if (!bytes) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
};

/**
 * Get audio duration from file (async)
 */
export const getAudioDuration = (file: File): Promise<number> => {
  return new Promise((resolve, reject) => {
    const audio = document.createElement('audio');
    audio.preload = 'metadata';

    audio.onloadedmetadata = () => {
      window.URL.revokeObjectURL(audio.src);
      resolve(audio.duration);
    };

    audio.onerror = () => {
      reject(new Error('Failed to load audio metadata'));
    };

    audio.src = URL.createObjectURL(file);
  });
};
