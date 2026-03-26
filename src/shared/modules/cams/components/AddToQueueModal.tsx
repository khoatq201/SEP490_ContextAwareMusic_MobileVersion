import { useState } from 'react';
import {
  Modal,
  Tabs,
  Select,
  Radio,
  Space,
  Typography,
  Form,
  Switch,
  Input,
  message,
} from 'antd';
import {
  PlayCircleOutlined,
  OrderedListOutlined,
  PlusOutlined,
} from '@ant-design/icons';
import { usePlaylists } from '@/shared/modules/playlists/hooks';
import { useTracks } from '@/shared/modules/tracks/hooks';
import { useAddTracksToQueue, useAddPlaylistToQueue } from '../hooks';
import { QueueInsertMode } from '../types';

const { Text } = Typography;
const { TextArea } = Input;

interface AddToQueueModalProps {
  open: boolean;
  spaceId: string;
  storeId: string;
  onClose: () => void;
  onSuccess?: () => void;
}

const queueModeOptions = [
  {
    label: 'Play Now',
    value: QueueInsertMode.PlayNow,
    icon: <PlayCircleOutlined />,
    description: 'Switch to this track immediately',
  },
  {
    label: 'Play Next',
    value: QueueInsertMode.PlayNext,
    icon: <OrderedListOutlined />,
    description: 'Add after current track',
  },
  {
    label: 'Add to Queue',
    value: QueueInsertMode.AddToQueue,
    icon: <PlusOutlined />,
    description: 'Add to end of queue',
  },
];

export const AddToQueueModal = ({
  open,
  spaceId,
  storeId,
  onClose,
  onSuccess,
}: AddToQueueModalProps) => {
  const [form] = Form.useForm();
  const [activeTab, setActiveTab] = useState<'tracks' | 'playlist'>('tracks');

  // Fetch data
  const { data: playlistsData, isLoading: isLoadingPlaylists } = usePlaylists({
    page: 1,
    pageSize: 100,
    status: 1,
    storeId,
  });

  const { data: tracksData, isLoading: isLoadingTracks } = useTracks({
    page: 1,
    pageSize: 100,
    status: 1,
  });

  // Mutations
  const addTracks = useAddTracksToQueue();
  const addPlaylist = useAddPlaylistToQueue();

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields();

      if (activeTab === 'tracks') {
        if (!values.trackIds || values.trackIds.length === 0) {
          message.warning('Please select at least one track');
          return;
        }

        await addTracks.mutateAsync({
          spaceId,
          data: {
            trackIds: values.trackIds,
            mode: values.mode || QueueInsertMode.AddToQueue,
            isClearExistingQueue: values.isClearExistingQueue || false,
            reason: values.reason || undefined,
          },
        });
      } else {
        if (!values.playlistId) {
          message.warning('Please select a playlist');
          return;
        }

        await addPlaylist.mutateAsync({
          spaceId,
          data: {
            playlistId: values.playlistId,
            mode: values.mode || QueueInsertMode.AddToQueue,
            isClearExistingQueue: values.isClearExistingQueue || false,
            reason: values.reason || undefined,
          },
        });
      }

      form.resetFields();
      onSuccess?.();
      onClose();
    } catch (error) {
      // Error handled by mutation hooks
      console.error('Failed to add to queue:', error);
    }
  };

  const handleCancel = () => {
    form.resetFields();
    onClose();
  };

  const playlistOptions = (playlistsData?.items || []).map((playlist) => ({
    label: playlist.name,
    value: playlist.id,
  }));

  const trackOptions = (tracksData?.items || []).map((track) => ({
    label: track.title,
    value: track.id,
  }));

  return (
    <Modal
      title='Add to Queue'
      open={open}
      onOk={handleSubmit}
      onCancel={handleCancel}
      confirmLoading={addTracks.isPending || addPlaylist.isPending}
      width={600}
      okText='Add to Queue'
    >
      <Form
        form={form}
        layout='vertical'
        initialValues={{
          mode: QueueInsertMode.AddToQueue,
          isClearExistingQueue: false,
        }}
      >
        <Tabs
          activeKey={activeTab}
          onChange={(key) => setActiveTab(key as 'tracks' | 'playlist')}
          items={[
            {
              key: 'tracks',
              label: 'Tracks',
              children: (
                <Form.Item
                  name='trackIds'
                  label='Select Tracks'
                  rules={[
                    {
                      required: activeTab === 'tracks',
                      message: 'Please select at least one track',
                    },
                  ]}
                >
                  <Select
                    mode='multiple'
                    placeholder='Choose tracks'
                    options={trackOptions}
                    loading={isLoadingTracks}
                    showSearch
                    optionFilterProp='label'
                    maxTagCount='responsive'
                  />
                </Form.Item>
              ),
            },
            {
              key: 'playlist',
              label: 'Playlist',
              children: (
                <Form.Item
                  name='playlistId'
                  label='Select Playlist'
                  rules={[
                    {
                      required: activeTab === 'playlist',
                      message: 'Please select a playlist',
                    },
                  ]}
                >
                  <Select
                    placeholder='Choose a playlist'
                    options={playlistOptions}
                    loading={isLoadingPlaylists}
                    showSearch
                    optionFilterProp='label'
                  />
                </Form.Item>
              ),
            },
          ]}
        />

        <Form.Item
          name='mode'
          label='Queue Mode'
        >
          <Radio.Group
            options={queueModeOptions.map((option) => ({
              label: (
                <Space direction='vertical'>
                  <Space>
                    {option.icon}
                    <Text strong>{option.label}</Text>
                  </Space>
                  <Text
                    type='secondary'
                    style={{ fontSize: 12 }}
                  >
                    {option.description}
                  </Text>
                </Space>
              ),
              value: option.value,
            }))}
            optionType='button'
            buttonStyle='solid'
          />
        </Form.Item>

        <Form.Item
          name='isClearExistingQueue'
          valuePropName='checked'
        >
          <Space>
            <Switch />
            <Text>Clear existing queue before adding</Text>
          </Space>
        </Form.Item>

        <Form.Item
          name='reason'
          label='Reason (Optional)'
        >
          <TextArea
            placeholder='Why are you adding this to the queue?'
            rows={2}
            maxLength={500}
            showCount
          />
        </Form.Item>
      </Form>
    </Modal>
  );
};
