import { useState } from 'react';
import {
  Drawer,
  Form,
  Input,
  Button,
  Flex,
  Row,
  Col,
  Typography,
  InputNumber,
  Slider,
  Select,
  Tag,
} from 'antd';

/**
 * Components
 */
import { ImageDragger, AudioDragger } from '@/shared/components';

/**
 * Utils
 */
import {
  createImageUploadProps,
  createAudioUploadProps,
  getAudioDuration,
} from '@/shared/utils';

/**
 * Hooks
 */
import { useMoodOptions } from '@/shared/modules/moods/hooks';
import { useCreateTrack } from '@/shared/modules/tracks/hooks';

/**
 * Validations
 */
import { createTrackValidation } from '@/shared/modules/tracks/validations';

/**
 * Constants
 */
import {
  GENRE_OPTIONS,
  MUSIC_PROVIDER_OPTIONS,
} from '@/shared/modules/tracks/constants';
import { MOOD_TYPE_COLORS } from '@/shared/modules/moods/constants';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import type { CreateTrackRequest } from '@/shared/modules/tracks/types';
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

interface CreateTrackDrawerProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const CreateTrackDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateTrackDrawerProps) => {
  const [form] = Form.useForm<CreateTrackRequest>();
  const createTrack = useCreateTrack();

  const [coverImageFile, setCoverImageFile] = useState<UploadFile | null>(null);
  const [audioFile, setAudioFile] = useState<UploadFile | null>(null);
  const [audioDuration, setAudioDuration] = useState<number>();
  const [energyLevel, setEnergyLevel] = useState(0.5);
  const [valence, setValence] = useState(0.5);

  const { options: moodOptions, isLoading: moodsLoading } = useMoodOptions();
  console.log(moodOptions);

  const imageUploadProps = createImageUploadProps<CreateTrackRequest>(
    setCoverImageFile,
    (field, value) => form.setFieldValue(field, value),
  );

  const audioUploadProps = createAudioUploadProps<CreateTrackRequest>(
    async (file) => {
      setAudioFile(file);

      // Auto-extract duration
      if (file?.originFileObj) {
        try {
          const duration = await getAudioDuration(file.originFileObj);
          setAudioDuration(duration);
          form.setFieldValue('durationSec', Math.floor(duration));
        } catch (error) {
          console.error('Failed to get audio duration:', error);
        }
      }
    },
    (field, value) => form.setFieldValue(field, value),
  );

  const getCoverPreviewUrl = () => {
    if (coverImageFile?.originFileObj) {
      return URL.createObjectURL(coverImageFile.originFileObj);
    }
    return null;
  };

  const handleSubmit = async (values: CreateTrackRequest) => {
    if (!audioFile?.originFileObj) {
      return;
    }

    const payload: CreateTrackRequest = {
      title: values.title,
      artist: values.artist,
      moodId: values.moodId,
      genre: values.genre,
      durationSec: values.durationSec,
      bpm: values.bpm,
      energyLevel,
      valence,
      provider: values.provider,
      audioFile: audioFile.originFileObj,
      coverImageFile: coverImageFile?.originFileObj,
    };

    createTrack.mutate(payload, {
      onSuccess: () => {
        handleCancel();
        onSuccess();
      },
    });
  };

  const handleCancel = () => {
    form.resetFields();
    setCoverImageFile(null);
    setAudioFile(null);
    setAudioDuration(undefined);
    setEnergyLevel(0.5);
    setValence(0.5);
    onClose();
  };

  return (
    <Drawer
      title='Upload New Track'
      placement='right'
      width={DRAWER_WIDTHS.medium}
      open={open}
      onClose={handleCancel}
      closeIcon={null}
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
            loading={createTrack.isPending}
          >
            Upload
          </Button>
        </Flex>
      }
    >
      <Form
        size='large'
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
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
            label='Track Title'
            name='title'
            rules={createTrackValidation.title}
          >
            <Input placeholder='e.g., Summer Vibes' />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label='Artist'
                name='artist'
                rules={createTrackValidation.artist}
              >
                <Input placeholder='e.g., John Doe' />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='Genre'
                name='genre'
                rules={createTrackValidation.genre}
              >
                <Select
                  placeholder='Select genre'
                  options={GENRE_OPTIONS}
                  showSearch
                  allowClear
                />
              </Form.Item>
            </Col>
          </Row>
        </div>

        {/* Audio File */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Audio File
          </Title>

          <Form.Item
            label='Audio File'
            name='audioFile'
            rules={createTrackValidation.audioFile}
            valuePropName='file'
          >
            <AudioDragger
              audioFile={audioFile?.originFileObj}
              uploadProps={audioUploadProps}
              duration={audioDuration}
            />
          </Form.Item>
        </div>

        {/* Cover Image */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Cover Image (Optional)
          </Title>

          <Form.Item
            label='Cover Image'
            name='coverImageFile'
            valuePropName='file'
          >
            <ImageDragger
              previewUrl={getCoverPreviewUrl()}
              uploadProps={imageUploadProps}
            />
          </Form.Item>
        </div>

        {/* Audio Metadata */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Audio Metadata
          </Title>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label='Duration (seconds)'
                name='durationSec'
                rules={createTrackValidation.durationSec}
              >
                <InputNumber
                  min={1}
                  placeholder='Auto-detected'
                  style={{ width: '100%' }}
                  disabled={!!audioDuration}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='BPM'
                name='bpm'
                rules={createTrackValidation.bpm}
              >
                <InputNumber
                  min={20}
                  max={300}
                  placeholder='e.g., 120'
                  style={{ width: '100%' }}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label='Energy Level (0.0 - 1.0)'>
            <Slider
              min={0}
              max={1}
              step={0.1}
              value={energyLevel}
              onChange={setEnergyLevel}
              marks={{ 0: '0.0', 0.5: '0.5', 1: '1.0' }}
            />
          </Form.Item>

          <Form.Item label='Valence (0.0 - 1.0)'>
            <Slider
              min={0}
              max={1}
              step={0.1}
              value={valence}
              onChange={setValence}
              marks={{ 0: '0.0', 0.5: '0.5', 1: '1.0' }}
            />
          </Form.Item>
        </div>

        {/* Additional Settings */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Additional Settings
          </Title>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label='Mood'
                name='moodId'
                help={moodsLoading ? 'Loading moods...' : undefined}
              >
                <Select
                  placeholder='Select mood'
                  options={moodOptions}
                  loading={moodsLoading}
                  optionRender={(option) => (
                    <Flex
                      justify='space-between'
                      align='center'
                    >
                      <span>{option.label}</span>
                      {option.data.moodType && (
                        <Tag color={MOOD_TYPE_COLORS[option.data.moodType]}>
                          {option.data.moodType}
                        </Tag>
                      )}
                    </Flex>
                  )}
                  allowClear
                  showSearch
                  filterOption={(input, option) =>
                    (option?.label ?? '')
                      .toLowerCase()
                      .includes(input.toLowerCase())
                  }
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='Provider'
                name='provider'
                initialValue={0}
              >
                <Select options={MUSIC_PROVIDER_OPTIONS} />
              </Form.Item>
            </Col>
          </Row>
        </div>
      </Form>
    </Drawer>
  );
};
