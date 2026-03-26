import { useState, useEffect } from 'react';
import {
  Drawer,
  Button,
  Space,
  Typography,
  Divider,
  message,
  Popconfirm,
} from 'antd';
import {
  PlusOutlined,
  DeleteOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import { DRAWER_WIDTHS } from '@/config';
import {
  useSpaceQueue,
  useSpaceState,
  useClearQueue,
  useRemoveQueueItem,
  useUpdateAudioState,
  useReorderQueue,
} from '../hooks';
import { QueueList } from './QueueList';
import { AudioMixerControls } from './AudioMixerControls';
import { AddToQueueModal } from './AddToQueueModal';
import type { QueueEndBehavior } from '../types';

const { Title, Text } = Typography;

interface QueueManagementDrawerProps {
  open: boolean;
  spaceId: string;
  storeId: string;
  onClose: () => void;
}

export const QueueManagementDrawer = ({
  open,
  spaceId,
  storeId,
  onClose,
}: QueueManagementDrawerProps) => {
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [localVolume, setLocalVolume] = useState<number>(100);

  // Fetch queue data
  const { data: queueData, isLoading, refetch } = useSpaceQueue(spaceId, open);

  // Fetch space state for audio mixer
  const { data: spaceState } = useSpaceState(spaceId, open);

  // Mutations
  const clearQueue = useClearQueue();
  const removeQueueItem = useRemoveQueueItem();
  const updateAudioState = useUpdateAudioState();
  const reorderQueue = useReorderQueue();

  // Get current audio state from space state or defaults
  const volumePercent = spaceState?.volumePercent ?? 100;
  const isMuted = spaceState?.isMuted ?? false;
  const queueEndBehavior = spaceState?.queueEndBehavior ?? 0;

  // Sync local volume with server state when spaceState changes
  useEffect(() => {
    if (spaceState?.volumePercent !== undefined) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setLocalVolume(spaceState.volumePercent);
    }
  }, [spaceState?.volumePercent]);

  const handleClearQueue = async () => {
    try {
      await clearQueue.mutateAsync(spaceId);
      message.success('Queue cleared successfully');
    } catch (error) {
      // Error handled by mutation hook
      console.error('Failed to clear queue:', error);
    }
  };

  const handleRemoveItem = async (queueItemId: string) => {
    try {
      await removeQueueItem.mutateAsync({ spaceId, queueItemId });
    } catch (error) {
      // Error handled by mutation hook
      console.error('Failed to remove queue item:', error);
    }
  };

  // Update local state while dragging (no API call)
  const handleVolumeChange = (volume: number) => {
    setLocalVolume(volume);
  };

  // Only call API when user releases the slider
  const handleVolumeChangeComplete = async (volume: number) => {
    try {
      await updateAudioState.mutateAsync({
        spaceId,
        data: { volumePercent: volume },
      });
    } catch (error) {
      console.error('Failed to update volume:', error);
      // Revert to server value on error
      setLocalVolume(volumePercent);
    }
  };

  const handleMuteToggle = async (muted: boolean) => {
    try {
      await updateAudioState.mutateAsync({
        spaceId,
        data: { isMuted: muted },
      });
    } catch (error) {
      console.error('Failed to toggle mute:', error);
    }
  };

  const handleQueueEndBehaviorChange = async (behavior: QueueEndBehavior) => {
    try {
      await updateAudioState.mutateAsync({
        spaceId,
        data: { queueEndBehavior: behavior },
      });
    } catch (error) {
      console.error('Failed to update queue end behavior:', error);
    }
  };

  const handleReorder = async (queueItemIds: string[]) => {
    try {
      await reorderQueue.mutateAsync({
        spaceId,
        data: { queueItemIds },
      });
    } catch (error) {
      console.error('Failed to reorder queue:', error);
    }
  };

  return (
    <>
      <Drawer
        title={
          <Space
            direction='vertical'
            size={0}
          >
            <Title
              level={4}
              style={{ margin: 0 }}
            >
              Queue Management
            </Title>
          </Space>
        }
        closeIcon={null}
        placement='right'
        width={DRAWER_WIDTHS.medium}
        open={open}
        onClose={onClose}
        extra={
          <Space>
            <Button
              icon={<ReloadOutlined />}
              onClick={() => refetch()}
              loading={isLoading}
            >
              Refresh
            </Button>
            <Popconfirm
              title='Clear Queue'
              description='Are you sure you want to clear the entire queue?'
              onConfirm={handleClearQueue}
              okText='Yes, Clear'
              cancelText='Cancel'
              okButtonProps={{ danger: true }}
            >
              <Button
                danger
                icon={<DeleteOutlined />}
                loading={clearQueue.isPending}
                disabled={!queueData || queueData.length === 0}
              >
                Clear All
              </Button>
            </Popconfirm>
            <Button
              type='primary'
              icon={<PlusOutlined />}
              onClick={() => setAddModalOpen(true)}
            >
              Add to Queue
            </Button>
          </Space>
        }
      >
        <Space
          direction='vertical'
          style={{ width: '100%' }}
          size='large'
        >
          {/* Audio Mixer Controls */}
          <AudioMixerControls
            volumePercent={localVolume}
            isMuted={isMuted}
            queueEndBehavior={queueEndBehavior}
            loading={updateAudioState.isPending}
            onVolumeChange={handleVolumeChange}
            onVolumeChangeComplete={handleVolumeChangeComplete}
            onMuteToggle={handleMuteToggle}
            onQueueEndBehaviorChange={handleQueueEndBehaviorChange}
          />

          <Divider style={{ margin: 0 }} />

          {/* Queue List */}
          <div>
            <Space
              direction='vertical'
              size='small'
              style={{ width: '100%' }}
            >
              <Space
                align='center'
                style={{ width: '100%', justifyContent: 'space-between' }}
              >
                <Title
                  level={5}
                  style={{ margin: 0 }}
                >
                  Queue Items
                </Title>
                <Text type='secondary'>
                  {queueData?.length || 0} track
                  {queueData?.length !== 1 ? 's' : ''}
                </Text>
              </Space>
              <QueueList
                items={queueData || []}
                loading={isLoading}
                onRemove={handleRemoveItem}
                onReorder={handleReorder}
              />
            </Space>
          </div>
        </Space>
      </Drawer>

      <AddToQueueModal
        open={addModalOpen}
        spaceId={spaceId}
        storeId={storeId}
        onClose={() => setAddModalOpen(false)}
        onSuccess={() => refetch()}
      />
    </>
  );
};
