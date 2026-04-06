import { createStyles } from 'antd-style';
import { useEffect, useMemo, useState } from 'react';
import { Empty, Spin, Badge, Typography, Progress, Space } from 'antd';

/**
 * Icons
 */
import { SoundOutlined } from '@ant-design/icons';

/**
 * Hooks
 */
import {
  useCancelSunoGeneration,
  useUpdateGenerationFromSignalR,
  useSunoGenerationStatus,
  useSunoGenerationHistory,
} from '@/shared/modules/suno/hooks';
import { useAuth } from '@/providers';
import { useSignalR } from '@/shared/hooks';
import { useQueryClient } from '@tanstack/react-query';

/**
 * Types
 */
import type {
  SunoGenerationRealtimeDto,
  SunoGenerationStatusDto,
} from '@/shared/modules/suno/types';

/**
 * Utils
 */
import {
  getSunoStatusBadgeColor,
  getSunoStatusText,
  isGenerationInProgress,
} from '@/shared/modules/suno/utils';
import { formatDateTime } from '@/shared/utils';

/**
 * Components
 */
import { SunoGenerationLogDrawer } from './SunoGenerationLogDrawer';

const { Text } = Typography;

const useStyles = createStyles(({ css, token }) => ({
  logContainer: css`
    border: 1px solid ${token.colorBorder};
    border-radius: ${token.borderRadius}px;
    overflow: hidden;
  `,
  logRow: css`
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 16px;
    border-bottom: 1px solid ${token.colorBorderSecondary};
    cursor: pointer;
    transition: background 0.15s;
    &:last-child {
      border-bottom: none;
    }
    &:hover {
      background-color: ${token.colorFillQuaternary};
    }
  `,
  timestamp: css`
    font-family: monospace;
    font-size: 12px;
    color: ${token.colorTextSecondary};
    white-space: nowrap;
    min-width: 160px;
  `,
  statusCell: css`
    min-width: 110px;
    white-space: nowrap;
  `,
  title: css`
    font-size: 13px;
    font-weight: 500;
    min-width: 140px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  `,
  prompt: css`
    font-size: 12px;
    color: ${token.colorTextSecondary};
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  `,
  progressCell: css`
    min-width: 100px;
  `,
}));

interface SunoGenerationListProps {
  generationId?: string;
}

export const SunoGenerationList = ({
  generationId,
}: SunoGenerationListProps) => {
  const { styles } = useStyles();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const [selectedGeneration, setSelectedGeneration] =
    useState<SunoGenerationStatusDto | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const cancelGeneration = useCancelSunoGeneration();
  const updateFromSignalR = useUpdateGenerationFromSignalR();

  const { data: historyResponse, isLoading: isHistoryLoading } =
    useSunoGenerationHistory(1, 50);

  const { data: polledGeneration } = useSunoGenerationStatus(generationId, {
    enabled: !!generationId,
    refetchInterval: 5000,
  });

  const { connection, isConnected } = useSignalR('/hubs/store');

  useEffect(() => {
    if (isConnected && connection && user?.brandId) {
      connection
        .invoke('JoinBrandManagerRoomAsync', user.brandId)
        .catch((err) => console.error('Failed to join brand room:', err));
    }
  }, [isConnected, connection, user?.brandId]);

  useEffect(() => {
    if (!connection) return;

    const handleStatusChanged = (data: SunoGenerationRealtimeDto) => {
      updateFromSignalR(data as SunoGenerationStatusDto);
      queryClient.invalidateQueries({
        queryKey: ['suno', 'generations', 'history'],
      });
    };

    connection.on('SunoGenerationStatusChanged', handleStatusChanged);
    return () => {
      connection.off('SunoGenerationStatusChanged', handleStatusChanged);
    };
  }, [connection, updateFromSignalR, queryClient]);

  const generations = useMemo(() => {
    const base = historyResponse?.items ? [...historyResponse.items] : [];

    if (!polledGeneration) return base;

    const index = base.findIndex((g) => g.id === polledGeneration.id);
    if (index >= 0) {
      base[index] = { ...base[index], ...polledGeneration };
    } else {
      base.unshift(polledGeneration);
    }

    return base;
  }, [historyResponse, polledGeneration]);

  // Keep selected generation in sync with live data
  useEffect(() => {
    if (selectedGeneration) {
      const updated = generations.find((g) => g.id === selectedGeneration.id);
      // eslint-disable-next-line react-hooks/set-state-in-effect
      if (updated) setSelectedGeneration(updated);
    }
  }, [generations, selectedGeneration]);

  const handleCancel = async (id: string) => {
    await cancelGeneration.mutateAsync(id);
  };

  const handleViewTrack = (trackId: string) => {
    window.open(`/brand/tracks?id=${trackId}`, '_blank');
  };

  const handleRowClick = (generation: SunoGenerationStatusDto) => {
    setSelectedGeneration(generation);
    setDrawerOpen(true);
  };

  if (isHistoryLoading && generations.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: 48 }}>
        <Spin size='large' />
      </div>
    );
  }

  if (generations.length === 0) {
    return (
      <Empty
        image={<SoundOutlined style={{ fontSize: 64, color: '#999' }} />}
        description='No generations yet. Start by generating your first AI music!'
      />
    );
  }

  return (
    <>
      <div className={styles.logContainer}>
        {generations.map((generation) => {
          const inProgress = isGenerationInProgress(
            generation.generationStatus,
          );

          return (
            <div
              key={generation.id}
              className={styles.logRow}
              onClick={() => handleRowClick(generation)}
            >
              <span className={styles.timestamp}>
                {formatDateTime(generation.createdAt)}
              </span>

              <span className={styles.statusCell}>
                <Badge
                  status={getSunoStatusBadgeColor(generation.generationStatus)}
                  text={
                    <Text style={{ fontSize: 12 }}>
                      {getSunoStatusText(generation.generationStatus)}
                    </Text>
                  }
                />
              </span>

              <span className={styles.title}>
                {generation.title || (
                  <Text
                    type='secondary'
                    italic
                  >
                    Untitled
                  </Text>
                )}
              </span>

              <span className={styles.prompt}>{generation.prompt ?? '—'}</span>

              {inProgress && (
                <Space className={styles.progressCell}>
                  <Progress
                    percent={generation.progressPercent}
                    size='small'
                    style={{ width: 90 }}
                    showInfo={false}
                    status='active'
                  />
                  <Text
                    style={{ fontSize: 11 }}
                    type='secondary'
                  >
                    {generation.progressPercent}%
                  </Text>
                </Space>
              )}
            </div>
          );
        })}
      </div>

      <SunoGenerationLogDrawer
        generation={selectedGeneration}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        onCancel={handleCancel}
        onViewTrack={handleViewTrack}
      />
    </>
  );
};
