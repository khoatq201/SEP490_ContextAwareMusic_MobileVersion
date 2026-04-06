import { Upload, Typography, Flex } from 'antd';
import type { UploadProps } from 'antd';

/**
 * Assets
 */
import filesImage from '@/assets/images/files.png';

const { Dragger } = Upload;
const { Text } = Typography;

type ImageDraggerProps = {
  /** Current image preview URL (existing or new) */
  previewUrl?: string | null;
  /** Upload props from createImageUploadProps */
  uploadProps: UploadProps;
  /** Custom upload hint text */
  hintText?: string;
};

export const ImageDragger = ({
  previewUrl,
  uploadProps,
  hintText = 'Click or drag file to this area to upload',
}: ImageDraggerProps) => {
  return (
    <Dragger {...uploadProps}>
      <Flex justify='center'>
        {previewUrl ? (
          <img
            src={previewUrl}
            height={60}
            alt='Preview'
            style={{ objectFit: 'contain' }}
          />
        ) : (
          <img
            src={filesImage}
            height={30}
            alt='Upload'
          />
        )}
      </Flex>
      <Flex vertical>
        <Text>{previewUrl ? 'Click or drag file to replace' : hintText}</Text>
        <Text type='secondary'>
          Support for image files (JPG, PNG, GIF, WEBP, BMP, SVG). Maximum size:
          5MB
        </Text>
      </Flex>
    </Dragger>
  );
};
