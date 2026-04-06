import { Collapse, Slider, Radio, Space, Typography, Row, Col } from 'antd';
import {
  SoundOutlined,
  MutedOutlined,
  RetweetOutlined,
  ControlOutlined,
} from '@ant-design/icons';
import { QueueEndBehavior } from '../types';
import { SettingSwitch } from '@/shared/components';
import { createStyles } from 'antd-style';

const { Text } = Typography;

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    queueBehaviorRadio: css`
      .${prefixCls}-radio-button-wrapper-checked {
        .${prefixCls}-typography {
          color: #fff !important;
        }
        .anticon {
          color: #fff !important;
        }
      }
    `,
  };
});

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
  {
    label: 'Stop',
    value: QueueEndBehavior.Stop,
    icon: <MutedOutlined />,
  },
  {
    label: 'Repeat Queue',
    value: QueueEndBehavior.RepeatQueue,
    icon: <RetweetOutlined />,
  },
  {
    label: 'Return to Schedule',
    value: QueueEndBehavior.ReturnToSchedule,
    icon: <ControlOutlined />,
  },
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
  const { styles } = useStyle();

  return (
    <Collapse
      items={[
        {
          key: 'audio',
          label: 'Audio Mixer',
          children: (
            <Space
              vertical
              style={{ width: '100%' }}
              size={2}
            >
              {/* Volume Control with Mute */}
              <div>
                <Row
                  align='middle'
                  gutter={12}
                  style={{ marginBottom: 12 }}
                >
                  <Col flex='none'>
                    <Text strong>Volume</Text>
                  </Col>
                  <Col flex='auto'>
                    {isMuted ? (
                      <MutedOutlined
                        style={{
                          fontSize: 16,
                          color: '#ff4d4f',
                          paddingTop: 4,
                        }}
                      />
                    ) : (
                      <SoundOutlined style={{ fontSize: 16, paddingTop: 4 }} />
                    )}
                  </Col>
                  <Col flex='none'>
                    <Text
                      type='secondary'
                      style={{
                        minWidth: 45,
                        display: 'inline-block',
                        textAlign: 'right',
                        fontSize: 13,
                      }}
                    >
                      {isMuted ? '0%' : `${volumePercent}%`}
                    </Text>
                  </Col>
                </Row>

                <Row
                  align='middle'
                  gutter={12}
                >
                  <Col flex='auto'>
                    <Slider
                      min={0}
                      max={100}
                      value={isMuted ? 0 : volumePercent}
                      onChange={onVolumeChange}
                      onChangeComplete={onVolumeChangeComplete}
                      disabled={loading || isMuted}
                      style={{ margin: 0 }}
                      tooltip={{ formatter: (value) => `${value}%` }}
                    />
                  </Col>
                </Row>

                <SettingSwitch
                  label='Mute'
                  description='Temporarily silence audio output'
                  value={isMuted}
                  onChange={onMuteToggle}
                  disabled={loading}
                  checkedChildren={<MutedOutlined />}
                  unCheckedChildren={<SoundOutlined />}
                />
              </div>

              {/* Queue End Behavior */}
              <Space
                direction='vertical'
                size='small'
                style={{ width: '100%' }}
              >
                <Text strong>Queue End Behavior</Text>
                <Radio.Group
                  className={styles.queueBehaviorRadio}
                  value={queueEndBehavior}
                  onChange={(e) => onQueueEndBehaviorChange(e.target.value)}
                  disabled={loading}
                  style={{ width: '100%' }}
                  options={queueEndBehaviorOptions.map((option) => ({
                    label: (
                      <Space>
                        {option.icon}
                        <Text>{option.label}</Text>
                      </Space>
                    ),
                    value: option.value,
                  }))}
                  size='large'
                  optionType='button'
                  buttonStyle='solid'
                />
              </Space>
            </Space>
          ),
        },
      ]}
      styles={{
        root: {
          border: '1px solid var(--ant-blue-3)',
          borderRadius: 2,
        },
        header: {
          backgroundColor: 'var(--ant-blue-1)',
        },
      }}
    />
  );
};
