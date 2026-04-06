import { Upload, Typography, Flex } from 'antd';
import type { UploadProps } from 'antd';

/**
 * Icons
 */
import { SoundOutlined } from '@ant-design/icons';

/**
 * Utils
 */
import { formatFileSize, formatDuration } from '@/shared/utils';

/**
 * Assets
 */
import filesImage from '@/assets/images/files.png';

const { Dragger } = Upload;
const { Text } = Typography;

type AudioDraggerProps = {
  /** Current audio file */
  audioFile?: File | null;
  /** Upload props from createAudioUploadProps */
  uploadProps: UploadProps;
  /** Custom upload hint text */
  hintText?: string;
  /** Show audio metadata (duration, size) */
  showMetadata?: boolean;
  /** Audio duration in seconds (if available) */
  duration?: number;
};

export const AudioDragger = ({
  audioFile,
  uploadProps,
  hintText = 'Click or drag audio file to this area to upload',
  showMetadata = true,
  duration,
}: AudioDraggerProps) => {
  return (
    <Dragger {...uploadProps}>
      <Flex
        vertical
        align='center'
        gap='middle'
      >
        {/* Icon& Images */}
        {audioFile ? (
          <div
            style={{
              fontSize: 48,
              color: audioFile ? '#1890ff' : '#d9d9d9',
            }}
          >
            <SoundOutlined />
          </div>
        ) : (
          <img
            src={filesImage}
            height={30}
            alt='Upload'
          />
        )}

        {/* File Info */}
        {audioFile ? (
          <Flex
            vertical
            gap='small'
            style={{ width: '100%' }}
          >
            <Text strong>{audioFile.name}</Text>
            {showMetadata && (
              <Flex
                justify='center'
                gap='large'
              >
                <Text type='secondary'>
                  Size: {formatFileSize(audioFile.size)}
                </Text>
                {duration && (
                  <Text type='secondary'>
                    Duration: {formatDuration(duration)}
                  </Text>
                )}
              </Flex>
            )}
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
            >
              Click or drag file to replace
            </Text>
          </Flex>
        ) : (
          <Flex vertical>
            <Text>{hintText}</Text>
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
            >
              Support: MP3, WAV, AAC, FLAC, OGG, M4A. Maximum size: 50MB
            </Text>
          </Flex>
        )}

        {/* Optional: Upload Progress Placeholder */}
        {/* You can add progress bar here if needed */}
      </Flex>
    </Dragger>
  );
};
