import { useEffect } from 'react';
import {
  Form,
  Input,
  Select,
  Button,
  Card,
  Space,
  Alert,
  Spin,
  Divider,
} from 'antd';
import { InfoCircleOutlined } from '@ant-design/icons';
import { useSunoConfig, useUpdateSunoConfig } from '../hooks';
import { usePlaylistOptions } from '@/shared/modules/playlists/hooks';
import type { SunoConfigUpdateRequest } from '../types';
import { AiGenerationMode } from '../types';

const { TextArea } = Input;

export const SunoConfigForm = () => {
  const [form] = Form.useForm<SunoConfigUpdateRequest>();
  const { data: config, isLoading } = useSunoConfig();
  const updateConfig = useUpdateSunoConfig();
  const { data: playlistOptions, isLoading: isLoadingPlaylists } =
    usePlaylistOptions();

  // Initialize form with config data
  useEffect(() => {
    if (config) {
      form.setFieldsValue({
        sunoPromptTemplate: config.sunoPromptTemplate,
        sunoDefaultPlaylistId: config.sunoDefaultPlaylistId,
        aiGenerationMode: config.aiGenerationMode,
      });
    }
  }, [config, form]);

  const handleSubmit = async (values: SunoConfigUpdateRequest) => {
    await updateConfig.mutateAsync(values);
  };

  if (isLoading) {
    return (
      <Card>
        <Spin />
      </Card>
    );
  }

  return (
    <Card
      title='Suno AI Configuration'
      extra={
        <Button
          type='primary'
          onClick={() => form.submit()}
        >
          Save Configuration
        </Button>
      }
    >
      <Form
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
        size='large'
        styles={{
          label: {
            height: 22,
          },
        }}
      >
        <Alert
          message='Prompt Template Variables'
          description={
            <Space
              direction='vertical'
              size='small'
            >
              <div>You can use these placeholders in your prompt template:</div>
              <div>
                <code>{'{mood}'}</code> - Mood name (e.g., "Energetic", "Calm")
              </div>
              <div>
                <code>{'{genre}'}</code> - Music genre
              </div>
              <div>
                <code>{'{title}'}</code> - Track title
              </div>
              <div>
                <code>{'{artist}'}</code> - Artist name
              </div>
              <Divider style={{ margin: '8px 0' }} />
              <div>
                When using <strong>Generate → Brand music profile</strong>,
                these are also filled from your CAMS fuzzy profile:
              </div>
              <div>
                <code>{'{fuzzyTemplate}'}</code>, <code>{'{bpmBand}'}</code>,{' '}
                <code>{'{chillBpm}'}</code>, <code>{'{focusBpm}'}</code>,{' '}
                <code>{'{energeticBpm}'}</code>
              </div>
              <div>
                <code>{'{pressureLowMax}'}</code>,{' '}
                <code>{'{pressureCriticalMin}'}</code>,{' '}
                <code>{'{stressComfortableMax}'}</code>,{' '}
                <code>{'{stressHighMin}'}</code>,{' '}
                <code>{'{densitySparseMax}'}</code>,{' '}
                <code>{'{densityCrowdedMin}'}</code>,{' '}
                <code>{'{spaceCapacity}'}</code>
              </div>
            </Space>
          }
          type='info'
          icon={<InfoCircleOutlined />}
          style={{ marginBottom: 24 }}
        />

        <Form.Item
          name='aiGenerationMode'
          label='Generation Mode'
          tooltip='Select which AI provider mode this brand will use for generation jobs.'
          initialValue={AiGenerationMode.Suno}
        >
          <Select
            options={[
              { label: 'Suno', value: AiGenerationMode.Suno },
              { label: 'Brand Model URL', value: AiGenerationMode.BrandModel },
            ]}
          />
        </Form.Item>

        <Form.Item
          name='sunoPromptTemplate'
          label='Prompt Template'
          tooltip='Template for generating AI music prompts. Use placeholders like {mood}, {genre}, etc.'
        >
          <TextArea
            rows={6}
            placeholder='Example: Create a {mood} {genre} track titled "{title}" by {artist}'
            maxLength={4000}
            showCount
          />
        </Form.Item>

        <Form.Item
          name='sunoDefaultPlaylistId'
          label='Default Playlist'
          tooltip='Generated tracks will be automatically added to this playlist'
        >
          <Select
            placeholder='Select default playlist'
            loading={isLoadingPlaylists}
            options={playlistOptions}
            allowClear
            showSearch
            filterOption={(input, option) =>
              (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
            }
          />
        </Form.Item>
      </Form>
    </Card>
  );
};
