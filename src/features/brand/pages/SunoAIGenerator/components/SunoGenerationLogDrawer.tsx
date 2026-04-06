import {
  Drawer,
  Tabs,
  Descriptions,
  Badge,
  Button,
  Space,
  Tag,
  Tooltip,
  message,
} from 'antd';
import { Light as SyntaxHighlighter } from 'react-syntax-highlighter';
import json from 'react-syntax-highlighter/dist/esm/languages/hljs/json';
import { atomOneLight } from 'react-syntax-highlighter/dist/esm/styles/hljs';

SyntaxHighlighter.registerLanguage('json', json);

/**
 * Icons
 */
import { CopyOutlined, EyeOutlined, StopOutlined } from '@ant-design/icons';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

/**
 * Utils
 */
import { formatDateTime } from '@/shared/utils';
import {
  getSunoStatusBadgeColor,
  getSunoStatusText,
  isGenerationInProgress,
} from '@/shared/modules/suno/utils';

/**
 * Types
 */
import {
  SunoGenerationStatus,
  AiGenerationMode,
} from '@/shared/modules/suno/types';
import type { SunoGenerationStatusDto } from '@/shared/modules/suno/types';
import { createStyles } from 'antd-style';

interface SunoGenerationLogDrawerProps {
  generation: SunoGenerationStatusDto | null;
  open: boolean;
  onClose: () => void;
  onCancel?: (id: string) => void;
  onViewTrack?: (trackId: string) => void;
}

const modeLabel = (mode: AiGenerationMode) =>
  mode === AiGenerationMode.Suno ? 'Suno' : 'Brand Model';

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    customTabs: css`
      .${prefixCls}-tabs-nav {
        margin-bottom: 0;
        .${prefixCls}-tabs-nav-wrap {
          .${prefixCls}-tabs-nav-list {
            width: 100%;
            .${prefixCls}-tabs-tab {
              justify-content: center;
              &:hover {
                background-color: var(--ant-blue-1);
                color: var(--ant-tabs-item-selected-color);
              }
            }
          }
        }
      }
    `,
  };
});

export const SunoGenerationLogDrawer = ({
  generation,
  open,
  onClose,
  onCancel,
  onViewTrack,
}: SunoGenerationLogDrawerProps) => {
  const { styles } = useStyle();

  if (!generation) return null;

  const jsonString = JSON.stringify(generation, null, 2);

  const handleCopyJson = async () => {
    try {
      await navigator.clipboard.writeText(jsonString);
      message.success('Copied to clipboard');
    } catch {
      message.error('Failed to copy');
    }
  };

  const inProgress = isGenerationInProgress(generation.generationStatus);
  const isCompleted =
    generation.generationStatus === SunoGenerationStatus.Completed;

  const detailsContent = (
    <Descriptions
      column={1}
      bordered
      size='default'
    >
      <Descriptions.Item label='ID'>
        <code>{generation.id}</code>
      </Descriptions.Item>
      <Descriptions.Item label='Status'>
        <Badge
          status={getSunoStatusBadgeColor(generation.generationStatus)}
          text={getSunoStatusText(generation.generationStatus)}
        />
        {inProgress && (
          <Tag
            style={{ marginLeft: 8 }}
            color='blue'
          >
            {generation.progressPercent}%
          </Tag>
        )}
      </Descriptions.Item>
      <Descriptions.Item label='Title'>
        {generation.title || <span style={{ color: '#999' }}>—</span>}
      </Descriptions.Item>
      <Descriptions.Item label='Artist'>
        {generation.artist || <span style={{ color: '#999' }}>—</span>}
      </Descriptions.Item>
      <Descriptions.Item label='Generation Mode'>
        {modeLabel(generation.generationMode)}
      </Descriptions.Item>
      <Descriptions.Item label='Custom Mode'>
        {generation.customMode ? 'Yes' : 'No'}
      </Descriptions.Item>
      <Descriptions.Item label='Instrumental'>
        {generation.instrumental ? 'Yes' : 'No'}
      </Descriptions.Item>
      <Descriptions.Item label='Duration'>
        {generation.duration ? (
          `${generation.duration}s`
        ) : (
          <span style={{ color: '#999' }}>—</span>
        )}
      </Descriptions.Item>
      <Descriptions.Item label='Style'>
        {generation.style || <span style={{ color: '#999' }}>—</span>}
      </Descriptions.Item>
      <Descriptions.Item label='Prompt'>
        <span style={{ whiteSpace: 'pre-wrap' }}>
          {generation.prompt || <span style={{ color: '#999' }}>—</span>}
        </span>
      </Descriptions.Item>
      {generation.lyrics && (
        <Descriptions.Item label='Lyrics'>
          <span style={{ whiteSpace: 'pre-wrap' }}>{generation.lyrics}</span>
        </Descriptions.Item>
      )}
      {generation.errorMessage && (
        <Descriptions.Item label='Error'>
          <span style={{ color: 'var(--ant-color-error)' }}>
            {generation.errorMessage}
          </span>
        </Descriptions.Item>
      )}
      {generation.externalTaskId && (
        <Descriptions.Item label='External Task ID'>
          <code style={{ fontSize: 12 }}>{generation.externalTaskId}</code>
        </Descriptions.Item>
      )}
      {generation.generatedTrackId && (
        <Descriptions.Item label='Generated Track ID'>
          <code style={{ fontSize: 12 }}>{generation.generatedTrackId}</code>
        </Descriptions.Item>
      )}
      {generation.outputAudioUrl && (
        <Descriptions.Item label='Audio URL'>
          <a
            href={generation.outputAudioUrl}
            target='_blank'
            rel='noopener noreferrer'
            style={{ fontSize: 12, wordBreak: 'break-all' }}
          >
            {generation.outputAudioUrl}
          </a>
        </Descriptions.Item>
      )}
      <Descriptions.Item label='Created At'>
        {formatDateTime(generation.createdAt)}
      </Descriptions.Item>
      {generation.completedAtUtc && (
        <Descriptions.Item label='Completed At'>
          {formatDateTime(generation.completedAtUtc)}
        </Descriptions.Item>
      )}
      {generation.lastPolledAtUtc && (
        <Descriptions.Item label='Last Polled At'>
          {formatDateTime(generation.lastPolledAtUtc)}
        </Descriptions.Item>
      )}
    </Descriptions>
  );

  const rawContent = (
    <SyntaxHighlighter
      language='json'
      style={atomOneLight}
      customStyle={{
        borderRadius: 8,
        border: '1px solid #E6EBF1',
        lineHeight: 1.6,
        margin: 0,
        padding: 12,
        paddingInline: 20,
      }}
      wrapLongLines
    >
      {jsonString}
    </SyntaxHighlighter>
  );

  const tabItems = [
    { key: 'details', label: 'Details', children: detailsContent },
    { key: 'raw', label: 'Raw', children: rawContent },
  ];

  return (
    <Drawer
      open={open}
      onClose={onClose}
      closeIcon={null}
      width={DRAWER_WIDTHS.medium}
      destroyOnHidden
      title={
        <Space>
          <Badge
            status={getSunoStatusBadgeColor(generation.generationStatus)}
          />
          {generation.title || 'Untitled Generation'}
        </Space>
      }
      extra={
        <Space>
          {inProgress && onCancel && (
            <Button
              size='large'
              danger
              icon={<StopOutlined />}
              onClick={() => {
                onCancel(generation.id);
                onClose();
              }}
            >
              Cancel
            </Button>
          )}
          {isCompleted && generation.generatedTrackId && onViewTrack && (
            <Button
              size='large'
              type='primary'
              icon={<EyeOutlined />}
              onClick={() => onViewTrack(generation.generatedTrackId!)}
            >
              View Track
            </Button>
          )}
        </Space>
      }
    >
      <Tabs
        size='small'
        defaultActiveKey='details'
        className={styles.customTabs}
        styles={{
          item: {
            width: 'fit-content',
            paddingInline: 20,
          },
          content: {
            paddingTop: 20,
          },
        }}
        items={tabItems}
        tabBarExtraContent={
          <Tooltip title='Copy as JSON'>
            <Button
              type='text'
              icon={<CopyOutlined />}
              onClick={handleCopyJson}
            />
          </Tooltip>
        }
      />
    </Drawer>
  );
};
