import { Alert, Progress, Space, Typography } from 'antd';
import { ClockCircleOutlined, LoadingOutlined } from '@ant-design/icons';
import { TrackMetadataStatus } from '../types';

const { Text } = Typography;

interface MetadataPollingProgressProps {
  isPolling: boolean;
  attempts: number;
  maxAttempts: number;
  status: TrackMetadataStatus | null;
}

/**
 * Component to display metadata extraction polling progress
 * Shows progress bar and status message during polling
 */
export const MetadataPollingProgress = ({
  isPolling,
  attempts,
  maxAttempts,
  status,
}: MetadataPollingProgressProps) => {
  if (!isPolling && status !== TrackMetadataStatus.Pending) {
    return null;
  }

  const percent = Math.round((attempts / maxAttempts) * 100);
  const remainingAttempts = maxAttempts - attempts;
  const estimatedSeconds = remainingAttempts * 10; // 10s per attempt

  return (
    <Alert
      type='info'
      showIcon
      icon={<LoadingOutlined />}
      message={
        <Space
          direction='vertical'
          size='small'
          style={{ width: '100%' }}
        >
          <Space
            align='center'
            style={{ width: '100%', justifyContent: 'space-between' }}
          >
            <Text strong>Extracting metadata...</Text>
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
            >
              <ClockCircleOutlined /> ~{estimatedSeconds}s remaining
            </Text>
          </Space>

          <Progress
            percent={percent}
            size='small'
            status='active'
            showInfo={false}
          />

          <Text
            type='secondary'
            style={{ fontSize: 12 }}
          >
            Attempt {attempts} of {maxAttempts} • Analyzing audio with AI...
          </Text>
        </Space>
      }
      style={{ marginBottom: 16 }}
    />
  );
};
