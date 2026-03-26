import { useState, useEffect } from 'react';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import {
  Button,
  Space,
  Typography,
  Card,
  Tag,
  Descriptions,
  Spin,
  Alert,
} from 'antd';

/**
 * Icons
 */
import {
  QrcodeOutlined,
  ReloadOutlined,
  DisconnectOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';

/**
 * Hooks
 */
import {
  useGeneratePairCode,
  useRevokePairCode,
  useUnpairDevice,
  usePairDeviceInfo,
} from '../hooks';

/**
 * Components
 */
import { AppModal } from '@/shared/components';

/**
 * Configs
 */
import { MODAL_WIDTHS } from '@/config';

dayjs.extend(relativeTime);

const { Title, Text, Paragraph } = Typography;

interface PairDeviceModalProps {
  open: boolean;
  spaceId: string | null;
  onClose: () => void;
}

/**
 * PairDeviceModal - Modal to manage device pairing for a space
 * Features:
 * - Generate pair code (6-character code with expiry)
 * - Display pair code with countdown timer
 * - Show paired device info
 * - Unpair device
 * - Revoke pair code
 */
export const PairDeviceModal = ({
  open,
  spaceId,
  onClose,
}: PairDeviceModalProps) => {
  const [pairCode, setPairCode] = useState<string | null>(null);
  const [expiresAt, setExpiresAt] = useState<string | null>(null);
  const [currentTime, setCurrentTime] = useState<number>(() => Date.now());

  const generatePairCode = useGeneratePairCode();
  const revokePairCode = useRevokePairCode();
  const unpairDevice = useUnpairDevice();

  const { data: deviceInfo, isLoading: isLoadingDeviceInfo } =
    usePairDeviceInfo(spaceId || undefined, open && !!spaceId);

  // Handle generate pair code
  const handleGeneratePairCode = async () => {
    if (!spaceId) return;

    const response = await generatePairCode.mutateAsync(spaceId);
    if (response.data.isSuccess && response.data.data) {
      setPairCode(response.data.data.displayCode);
      setExpiresAt(response.data.data.expiresAt);
    }
  };

  // Handle revoke pair code
  const handleRevokePairCode = async () => {
    if (!spaceId) return;

    await revokePairCode.mutateAsync(spaceId);
    setPairCode(null);
    setExpiresAt(null);
  };

  // Handle unpair device
  const handleUnpairDevice = async () => {
    if (!spaceId) return;

    AppModal.confirm({
      title: 'Unpair Device',
      content:
        'Are you sure you want to unpair this device? The device will need to pair again to continue playback.',
      okText: 'Yes, Unpair',
      cancelText: 'Cancel',
      okButtonProps: { danger: true },
      onOk: async () => {
        await unpairDevice.mutateAsync(spaceId);
      },
    });
  };

  // Update current time every second for countdown
  useEffect(() => {
    if (!expiresAt) return;

    const interval = setInterval(() => {
      const now = Date.now();
      const expires = dayjs(expiresAt).valueOf();

      // Check if expired and clear pair code
      if (now >= expires) {
        setPairCode(null);
        setExpiresAt(null);
      } else {
        setCurrentTime(now);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [expiresAt]);

  // Calculate countdown from expiresAt and currentTime
  const countdown = expiresAt
    ? Math.max(0, dayjs(expiresAt).diff(dayjs(currentTime), 'second'))
    : 0;

  // Format countdown as MM:SS
  const formatCountdown = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const hasPairedDevice = !!deviceInfo?.deviceSessionId;

  return (
    <AppModal
      title={
        <Space>
          <QrcodeOutlined />
          <span>Device Pairing</span>
        </Space>
      }
      open={open}
      onCancel={onClose}
      footer={
        <Button
          key='close'
          size='large'
          onClick={onClose}
        >
          Close
        </Button>
      }
      width={MODAL_WIDTHS.large}
      destroyOnClose
    >
      <Spin spinning={isLoadingDeviceInfo}>
        <Space
          direction='vertical'
          style={{ width: '100%' }}
          size='large'
        >
          {/* Paired Device Info */}
          {hasPairedDevice ? (
            <Card
              title='Paired Device'
              extra={
                <Button
                  size='large'
                  danger
                  icon={<DisconnectOutlined />}
                  onClick={handleUnpairDevice}
                  loading={unpairDevice.isPending}
                >
                  Unpair
                </Button>
              }
            >
              <Descriptions
                column={1}
                size='small'
              >
                <Descriptions.Item label='Manufacturer'>
                  {deviceInfo.manufacturer || '-'}
                </Descriptions.Item>
                <Descriptions.Item label='Model'>
                  {deviceInfo.model || '-'}
                </Descriptions.Item>
                <Descriptions.Item label='OS Version'>
                  {deviceInfo.osVersion || '-'}
                </Descriptions.Item>
                <Descriptions.Item label='App Version'>
                  {deviceInfo.appVersion || '-'}
                </Descriptions.Item>
                <Descriptions.Item label='Paired At'>
                  {deviceInfo.pairedAtUtc
                    ? dayjs(deviceInfo.pairedAtUtc).format('MMM D, YYYY HH:mm')
                    : '-'}
                </Descriptions.Item>
                <Descriptions.Item label='Last Active'>
                  {deviceInfo.lastActiveAtUtc ? (
                    <Tag color='success'>
                      {dayjs(deviceInfo.lastActiveAtUtc).fromNow()}
                    </Tag>
                  ) : (
                    '-'
                  )}
                </Descriptions.Item>
              </Descriptions>
            </Card>
          ) : (
            <Alert
              title='No Device Paired'
              type='info'
              showIcon
            />
          )}

          {/* Pair Code Section */}
          {!hasPairedDevice && (
            <div>
              <Title
                level={5}
                style={{ marginBottom: 16 }}
              >
                Pair Code
              </Title>
              {pairCode ? (
                <Card>
                  <Space
                    direction='vertical'
                    style={{ width: '100%', textAlign: 'center' }}
                    size='middle'
                  >
                    <Text type='secondary'>Enter this code on the tablet:</Text>
                    <Title
                      level={1}
                      style={{
                        margin: 0,
                        fontFamily: 'monospace',
                        letterSpacing: '0.2em',
                      }}
                    >
                      {pairCode}
                    </Title>
                    <Space>
                      <Tag color='warning'>
                        Expires in: {formatCountdown(countdown)}
                      </Tag>
                    </Space>
                    <Paragraph
                      type='secondary'
                      style={{ fontSize: 12, margin: 0 }}
                    >
                      The code will expire in 15 minutes. The tablet must enter
                      this code to pair with the space.
                    </Paragraph>
                    <Button
                      size='large'
                      danger
                      icon={<CloseCircleOutlined />}
                      onClick={handleRevokePairCode}
                      loading={revokePairCode.isPending}
                    >
                      Revoke Code
                    </Button>
                  </Space>
                </Card>
              ) : (
                <Space
                  direction='vertical'
                  style={{ width: '100%' }}
                >
                  <Paragraph type='secondary'>
                    Generate a 6-character pair code that the tablet can use to
                    connect to this space. The code will be valid for 15
                    minutes.
                  </Paragraph>
                  <Button
                    size='large'
                    type='primary'
                    icon={<ReloadOutlined />}
                    onClick={handleGeneratePairCode}
                    loading={generatePairCode.isPending}
                    block
                  >
                    Generate Pair Code
                  </Button>
                </Space>
              )}
            </div>
          )}
        </Space>
      </Spin>
    </AppModal>
  );
};
