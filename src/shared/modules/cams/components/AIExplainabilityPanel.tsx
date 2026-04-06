import { Card, Descriptions, Tag, Alert, Space, Tooltip } from 'antd';
import {
  ThunderboltOutlined,
  FireOutlined,
  EyeOutlined,
  InfoCircleOutlined,
  SoundOutlined,
} from '@ant-design/icons';
import type { SpaceStateDto, SpaceStateResponse } from '../types';

interface AIExplainabilityPanelProps {
  spaceState: SpaceStateDto | SpaceStateResponse;
  compact?: boolean; // Compact mode for smaller displays
}

/**
 * AI Explainability Panel
 * Shows fuzzy logic decisions and BPM-based selection transparency
 * See: docs/cams/FE_IMPLEMENTATION_METADATA_TO_FUZZY_AI.md §4
 */
export const AIExplainabilityPanel = ({
  spaceState,
  compact = false,
}: AIExplainabilityPanelProps) => {
  const hasBpmRange = spaceState.bpmMin !== null && spaceState.bpmMax !== null;
  const hasFuzzyInfo = spaceState.fuzzyRule || spaceState.fuzzyReason;
  const isFallback = spaceState.isBpmFallback === true;

  // Don't show panel if no AI info available
  if (!hasBpmRange && !hasFuzzyInfo && !isFallback) {
    return null;
  }

  // Get mood icon
  const getMoodIcon = (moodName?: string | null) => {
    const mood = moodName?.toLowerCase();
    if (mood?.includes('energetic')) return <ThunderboltOutlined />;
    if (mood?.includes('chill')) return <FireOutlined />;
    if (mood?.includes('focus')) return <EyeOutlined />;
    return <SoundOutlined />;
  };

  // Format fuzzy rule name for display
  const formatRuleName = (rule?: string | null): string => {
    if (!rule) return '';

    // Remove "RULE_X_" prefix
    const cleaned = rule.replace(/^RULE_\d+_/, '');

    // Convert SNAKE_CASE to Title Case
    return cleaned
      .split('_')
      .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
      .join(' ');
  };

  // Compact mode - single line display
  if (compact) {
    return (
      <Alert
        type='info'
        showIcon
        icon={getMoodIcon(spaceState.moodName)}
        message={
          <Space
            size='small'
            wrap
          >
            {spaceState.moodName && (
              <Tag
                color='blue'
                icon={getMoodIcon(spaceState.moodName)}
              >
                {spaceState.moodName}
              </Tag>
            )}
            {hasBpmRange && (
              <Tag color='cyan'>
                BPM: {spaceState.bpmMin}-{spaceState.bpmMax}
                {spaceState.bpmTarget && ` (target: ${spaceState.bpmTarget})`}
              </Tag>
            )}
            {isFallback && (
              <Tag
                color='warning'
                icon={<InfoCircleOutlined />}
              >
                Mood-only
              </Tag>
            )}
          </Space>
        }
      />
    );
  }

  // Full mode - detailed card
  return (
    <Card
      title={
        <Space>
          <SoundOutlined />
          <span>AI Music Selection</span>
        </Space>
      }
      size='small'
    >
      <Space
        direction='vertical'
        style={{ width: '100%' }}
        size='middle'
      >
        <Descriptions
          column={1}
          size='small'
        >
          {/* Current Mood */}
          {spaceState.moodName && (
            <Descriptions.Item label='Current Mood'>
              <Tag
                color='blue'
                icon={getMoodIcon(spaceState.moodName)}
              >
                {spaceState.moodName}
              </Tag>
            </Descriptions.Item>
          )}

          {/* BPM Range */}
          {hasBpmRange && (
            <Descriptions.Item
              label={
                <Tooltip title='AI selects tracks within this BPM range based on context analysis'>
                  <Space size={4}>
                    <span>BPM Range</span>
                    <InfoCircleOutlined style={{ color: '#999' }} />
                  </Space>
                </Tooltip>
              }
            >
              <Space size='small'>
                <Tag color='cyan'>
                  {spaceState.bpmMin} - {spaceState.bpmMax} BPM
                </Tag>
                {spaceState.bpmTarget && (
                  <Tooltip title='Target BPM within the range'>
                    <Tag color='geekblue'>Target: {spaceState.bpmTarget}</Tag>
                  </Tooltip>
                )}
              </Space>
            </Descriptions.Item>
          )}

          {/* Fuzzy Rule */}
          {spaceState.fuzzyRule && (
            <Descriptions.Item
              label={
                <Tooltip title='The fuzzy logic rule that determined current mood and BPM'>
                  <Space size={4}>
                    <span>Context Rule</span>
                    <InfoCircleOutlined style={{ color: '#999' }} />
                  </Space>
                </Tooltip>
              }
            >
              <Tag color='purple'>{formatRuleName(spaceState.fuzzyRule)}</Tag>
            </Descriptions.Item>
          )}

          {/* Fuzzy Reason */}
          {spaceState.fuzzyReason && (
            <Descriptions.Item label='Reason'>
              <span style={{ fontSize: 13, color: '#666' }}>
                {spaceState.fuzzyReason}
              </span>
            </Descriptions.Item>
          )}
        </Descriptions>

        {/* Fallback Warning */}
        {isFallback && (
          <Alert
            type='info'
            showIcon
            message='Using mood-only selection'
            description='Not enough tracks with BPM metadata in the selected range. AI is using mood-only selection to maintain queue stability.'
            style={{ fontSize: 12 }}
          />
        )}

        {/* Manual Override Notice */}
        {spaceState.isManualOverride && (
          <Alert
            type='warning'
            showIcon
            message='Manual Override Active'
            description='Manager has manually selected music. AI recommendations are paused.'
            style={{ fontSize: 12 }}
          />
        )}
      </Space>
    </Card>
  );
};
