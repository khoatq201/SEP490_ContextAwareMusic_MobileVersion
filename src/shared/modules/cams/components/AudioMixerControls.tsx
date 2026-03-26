import {
  Card,
  Slider,
  Switch,
  Select,
  Space,
  Typography,
  Row,
  Col,
} from 'antd';
import {
  SoundOutlined,
  MutedOutlined,
  RetweetOutlined,
} from '@ant-design/icons';
import { QueueEndBehavior } from '../types';

const { Text } = Typography;

interface AudioMixerControlsProps {
  volumePercent: number;
  isMuted: boolean;
  queueEndBehavior: QueueEndBehavior;
  loading?: boolean;
  onVolumeChange: (volume: number) => void;
  onVolumeChangeComplete: (volume: number) => void;
  onMuteToggle: (muted: boolean) => void;
  onQueueEndBehaviorChange: (behavior: QueueEndBehavior) => void;
}

const queueEndBehaviorOptions = [
  { label: 'Stop', value: QueueEndBehavior.Stop },
  { label: 'Repeat Queue', value: QueueEndBehavior.RepeatQueue },
  { label: 'Return to Schedule', value: QueueEndBehavior.ReturnToSchedule },
];

export const AudioMixerControls = ({
  volumePercent,
  isMuted,
  queueEndBehavior,
  loading,
  onVolumeChange,
  onVolumeChangeComplete,
  onMuteToggle,
  onQueueEndBehaviorChange,
}: AudioMixerControlsProps) => {
  return (
    <Card
      title='Audio Mixer'
      size='small'
    >
      <Space
        direction='vertical'
        style={{ width: '100%' }}
        size='middle'
      >
        {/* Volume Control */}
        <div>
          <Row
            align='middle'
            gutter={12}
          >
            <Col flex='none'>
              {isMuted ? (
                <MutedOutlined style={{ fontSize: 16, color: '#ff4d4f' }} />
              ) : (
                <SoundOutlined style={{ fontSize: 16 }} />
              )}
            </Col>
            <Col flex='auto'>
              <Slider
                min={0}
                max={100}
                value={isMuted ? 0 : volumePercent}
                onChange={onVolumeChange}
                onAfterChange={onVolumeChangeComplete}
                disabled={loading || isMuted}
                style={{ margin: 0 }}
                tooltip={{ formatter: (value) => `${value}%` }}
              />
            </Col>
            <Col flex='none'>
              <Text
                type='secondary'
                style={{
                  minWidth: 45,
                  display: 'inline-block',
                  textAlign: 'right',
                }}
              >
                {isMuted ? '0%' : `${volumePercent}%`}
              </Text>
            </Col>
          </Row>
        </div>

        {/* Mute Toggle */}
        <Row
          align='middle'
          justify='space-between'
        >
          <Text>Mute</Text>
          <Switch
            checked={isMuted}
            onChange={onMuteToggle}
            disabled={loading}
            checkedChildren={<MutedOutlined />}
            unCheckedChildren={<SoundOutlined />}
          />
        </Row>

        {/* Queue End Behavior */}
        <div>
          <Space
            direction='vertical'
            size='small'
            style={{ width: '100%' }}
          >
            <Text>
              <RetweetOutlined /> Queue End Behavior
            </Text>
            <Select
              value={queueEndBehavior}
              onChange={onQueueEndBehaviorChange}
              options={queueEndBehaviorOptions}
              disabled={loading}
              style={{ width: '100%' }}
            />
          </Space>
        </div>
      </Space>
    </Card>
  );
};
