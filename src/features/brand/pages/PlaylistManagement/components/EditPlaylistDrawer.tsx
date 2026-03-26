import { useEffect } from 'react';
import {
  Drawer,
  Form,
  Input,
  Select,
  Switch,
  Button,
  Flex,
  Spin,
  Typography,
  Alert,
} from 'antd';

/**
 * Icons
 */
import { InfoCircleOutlined } from '@ant-design/icons';

/**
 * Hooks
 */
import {
  usePlaylist,
  useUpdatePlaylist,
} from '@/shared/modules/playlists/hooks';
import { useMoods } from '@/shared/modules/moods/hooks';

/**
 * Validations
 */
import { updatePlaylistValidation } from '@/shared/modules/playlists/validations';

/**
 * Types
 */
import type { UpdatePlaylistRequest } from '@/shared/modules/playlists/types';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title, Text } = Typography;

interface EditPlaylistDrawerProps {
  open: boolean;
  playlistId?: string;
  onClose: () => void;
  onSuccess?: () => void;
}

export const EditPlaylistDrawer = ({
  open,
  playlistId,
  onClose,
  onSuccess,
}: EditPlaylistDrawerProps) => {
  const [form] = Form.useForm<UpdatePlaylistRequest>();
  const { data: playlist, isLoading } = usePlaylist(playlistId, open);
  const updatePlaylist = useUpdatePlaylist();

  const { data: moodsData } = useMoods();

  useEffect(() => {
    if (open && playlist) {
      form.setFieldsValue({
        name: playlist.name,
        moodId: playlist.moodId || undefined,
        description: playlist.description || undefined,
        isDefault: playlist.isDefault,
      });
    }
  }, [open, playlist, form]);

  const handleSubmit = async (values: UpdatePlaylistRequest) => {
    if (!playlistId) return;

    updatePlaylist.mutate(
      { id: playlistId, data: values },
      {
        onSuccess: () => {
          handleCancel();
          onSuccess?.();
        },
      },
    );
  };

  const handleCancel = () => {
    form.resetFields();
    onClose();
  };

  const moodOptions = (moodsData || []).map((mood) => ({
    label: mood.name || 'Unnamed Mood',
    value: mood.id,
  }));

  return (
    <Drawer
      closeIcon={null}
      title='Edit Playlist'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={handleCancel}
      footer={
        <Flex
          justify='end'
          gap='small'
        >
          <Button
            size='large'
            onClick={handleCancel}
          >
            Cancel
          </Button>
          <Button
            size='large'
            type='primary'
            onClick={() => form.submit()}
            loading={updatePlaylist.isPending}
            disabled={isLoading}
          >
            Save Changes
          </Button>
        </Flex>
      }
    >
      {isLoading ? (
        <div className='flex h-96 items-center justify-center'>
          <Spin size='large' />
        </div>
      ) : (
        <Form
          size='large'
          form={form}
          layout='vertical'
          onFinish={handleSubmit}
          autoComplete='off'
          styles={{
            label: {
              height: 22,
            },
          }}
        >
          {/* Basic Information */}
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Basic Information
            </Title>

            <Form.Item
              label='Playlist Name'
              name='name'
              rules={updatePlaylistValidation.name}
            >
              <Input
                placeholder='Enter playlist name'
                maxLength={255}
                showCount
              />
            </Form.Item>

            <Alert
              message='Store Cannot Be Changed'
              description='Playlists are permanently assigned to a store and cannot be moved.'
              type='info'
              icon={<InfoCircleOutlined />}
              showIcon
              style={{ marginBottom: 16 }}
            />

            <Form.Item
              label='Mood'
              name='moodId'
            >
              <Select
                placeholder='Select mood (optional)'
                options={moodOptions}
                showSearch
                optionFilterProp='label'
                allowClear
                loading={!moodsData}
              />
            </Form.Item>

            <Form.Item
              label='Description'
              name='description'
              rules={updatePlaylistValidation.description}
            >
              <Input.TextArea
                placeholder='Enter playlist description (optional)'
                rows={4}
                maxLength={2000}
                showCount
              />
            </Form.Item>
          </div>

          {/* Configuration */}
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Configuration
            </Title>

            <Form.Item
              label='Default Playlist'
              name='isDefault'
              valuePropName='checked'
            >
              <Switch
                checkedChildren='Yes'
                unCheckedChildren='No'
              />
            </Form.Item>
          </div>

          {/* Read-only Info */}
          {playlist && (
            <div style={{ marginTop: 16 }}>
              <Text type='secondary'>
                Store: <strong>{playlist.storeName || 'N/A'}</strong>
              </Text>
              <br />
              <Text type='secondary'>
                Tracks: <strong>{playlist.trackCount}</strong>
              </Text>
            </div>
          )}
        </Form>
      )}
    </Drawer>
  );
};
