import { useMemo, useState } from 'react';
import {
  Alert,
  Button,
  Card,
  Col,
  DatePicker,
  Empty,
  Flex,
  Row,
  Segmented,
  Select,
  Skeleton,
  Space,
  Spin,
  Statistic,
  Table,
  Tag,
  Tooltip,
  Typography,
} from 'antd';
import {
  LockOutlined,
  ReloadOutlined,
  SoundOutlined,
  TableOutlined,
  WalletOutlined,
} from '@ant-design/icons';
import { useQueries, useQuery } from '@tanstack/react-query';
import dayjs from 'dayjs';

import { STALE_TIME } from '@/config';
import { useAuth } from '@/providers';
import { spaceService } from '@/shared/modules/spaces/services';
import type { SpaceListItem } from '@/shared/modules/spaces/types';
import type { ColumnsType } from 'antd/es/table';
import type {
  MetricTrend,
  StoreContextRawLogItem,
  StoreContextTimeSeriesPoint,
} from '@/features/brand/types';
import { billingService, storeService } from '@/features/brand/services';
import type { BillingUsageView } from '@/shared/modules/billing';
import { camsService } from '@/shared/modules/cams/services';
import type { SpaceStateResponse } from '@/shared/modules/cams/types';
import { EntityStatusEnum } from '@/shared/types';
import { PageHeader } from '@/shared/components';

type PeriodOption = 'day' | 'week' | 'month' | 'custom';
type GranularityOption = 'hour' | 'day';
type DashboardMetricKey = 'noise' | 'crowdDensity';

type RangeValue = [dayjs.Dayjs, dayjs.Dayjs];

const LIVE_POLL_MS = 5000;
const LIVE_PAGE_SIZE = 300;

/** Map telemetry group key (id or name) to space GUID for CAMS state API */
const resolveSpaceIdForPlayback = (
  blockKey: string,
  blockTitle: string,
  spaceList: SpaceListItem[] | undefined,
): string | undefined => {
  if (!spaceList?.length) return undefined;
  if (spaceList.some((s) => s.id === blockKey)) return blockKey;
  const byTitle = spaceList.find((s) => s.name === blockTitle);
  if (byTitle) return byTitle.id;
  const byNameAsKey = spaceList.find((s) => s.name === blockKey);
  if (byNameAsKey) return byNameAsKey.id;
  return undefined;
};

type PlaybackPollSlot = {
  state: SpaceStateResponse | null;
  isPending: boolean;
  isFetching: boolean;
};

const NowPlayingBanner = ({
  spaceLabel,
  slot,
}: {
  spaceLabel: string;
  slot?: PlaybackPollSlot;
}) => {
  if (!slot) {
    return (
      <Typography.Paragraph
        type='secondary'
        style={{ marginBottom: 14 }}
      >
        Playback: could not resolve space id for &quot;{spaceLabel}&quot;.
      </Typography.Paragraph>
    );
  }

  if (slot.isPending) {
    return (
      <div style={{ marginBottom: 14 }}>
        <Typography.Text
          type='secondary'
          style={{ fontSize: 12 }}
        >
          {spaceLabel}
        </Typography.Text>
        <Skeleton
          active
          title={{ width: '55%' }}
          paragraph={{ rows: 1 }}
        />
      </div>
    );
  }

  const s = slot.state;
  const hasStream = Boolean(s?.hlsUrl);
  const trackTitle = s?.currentTrackName?.trim();
  const idle = !hasStream && !trackTitle;

  if (idle) {
    return (
      <Flex
        align='center'
        gap={10}
        style={{
          marginBottom: 14,
          padding: '10px 12px',
          background: '#f5f5f5',
          borderRadius: 8,
          border: '1px dashed #d9d9d9',
        }}
      >
        <SoundOutlined style={{ fontSize: 20, color: '#bfbfbf' }} />
        <div>
          <Typography.Text strong>{spaceLabel}</Typography.Text>
          <div>
            <Typography.Text type='secondary'>No track playing</Typography.Text>
          </div>
        </div>
      </Flex>
    );
  }

  return (
    <Flex
      align='flex-start'
      gap={12}
      wrap='wrap'
      style={{
        marginBottom: 14,
        padding: '12px 14px',
        borderRadius: 10,
        background:
          'linear-gradient(120deg, #f9f0ff 0%, #f6ffed 55%, #e6fffb 100%)',
        border: '1px solid #efdbff',
        boxShadow: slot.isFetching ? '0 0 0 2px rgba(114,46,209,0.12)' : 'none',
        transition: 'box-shadow 0.35s ease',
      }}
    >
      <SoundOutlined
        className='store-now-playing-icon'
        style={{ fontSize: 26, color: '#722ed1', marginTop: 2 }}
      />
      <div style={{ flex: 1, minWidth: 200 }}>
        <Typography.Text
          type='secondary'
          style={{ fontSize: 11 }}
        >
          Now playing · {spaceLabel}
        </Typography.Text>
        <Typography.Title
          level={5}
          style={{ margin: '4px 0 6px', fontWeight: 700 }}
        >
          {trackTitle || 'Playing (stream active)'}
        </Typography.Title>
        <Space
          size={[6, 6]}
          wrap
        >
          {s?.moodName && <Tag color='purple'>{s.moodName}</Tag>}
          {s?.isPaused ? (
            <Tag color='warning'>Paused</Tag>
          ) : (
            <Tag color='success'>Playing</Tag>
          )}
          {s?.isMuted && <Tag>Muted</Tag>}
          {s?.isManualOverride && <Tag color='magenta'>Manual override</Tag>}
          {s?.fuzzyRule && (
            <Tooltip title={s.fuzzyReason || undefined}>
              <Tag>{s.fuzzyRule}</Tag>
            </Tooltip>
          )}
        </Space>
      </div>
    </Flex>
  );
};

const getRangeByPeriod = (period: PeriodOption): RangeValue => {
  const now = dayjs();

  if (period === 'day') {
    return [now.startOf('day'), now.endOf('day')];
  }

  if (period === 'week') {
    return [now.startOf('week'), now.endOf('week')];
  }

  if (period === 'month') {
    return [now.startOf('month'), now.endOf('month')];
  }

  return [now.startOf('day'), now.endOf('day')];
};

const formatValue = (value?: number | null, digits = 2) => {
  if (value === null || value === undefined) {
    return '--';
  }

  return value.toFixed(digits);
};

const getErrorMessage = (error: unknown) => {
  if (error instanceof Error && error.message) {
    return error.message;
  }

  return 'Something went wrong while loading data.';
};

const formatTrend = (trend: MetricTrend) => {
  if (trend.deltaPercent === null || trend.deltaPercent === undefined) {
    return <Tag color='default'>No baseline</Tag>;
  }

  const positive = trend.deltaPercent >= 0;
  const sign = positive ? '+' : '';

  return (
    <Tag color={positive ? 'success' : 'error'}>
      {sign}
      {trend.deltaPercent.toFixed(2)}%
    </Tag>
  );
};

const metricCards: Array<{
  key: DashboardMetricKey;
  title: string;
  unit: string;
  lineColor: string;
  dataKey: 'avgNoise' | 'avgCrowdDensity';
}> = [
  {
    key: 'noise',
    title: 'Noise',
    unit: 'dB',
    lineColor: '#059669',
    dataKey: 'avgNoise' as const,
  },
  {
    key: 'crowdDensity',
    title: 'Crowd',
    unit: '',
    lineColor: '#7c3aed',
    dataKey: 'avgCrowdDensity' as const,
  },
];

type MiniLineChartProps = {
  data: StoreContextTimeSeriesPoint[];
  dataKey: 'avgNoise' | 'avgCrowdDensity';
  color: string;
  granularity: GranularityOption;
};

const MiniLineChart = ({
  data,
  dataKey,
  color,
  granularity,
}: MiniLineChartProps) => {
  const width = 360;
  const height = 160;
  const padding = 12;
  const chartLeft = padding + 6;
  const chartRight = width - padding;
  const chartTop = padding;
  const chartBottom = height - 34;
  const chartWidth = chartRight - chartLeft;
  const chartHeight = chartBottom - chartTop;

  const points = data
    .map((point, index) => {
      const value = point[dataKey];
      if (value === null || value === undefined) {
        return null;
      }

      return {
        index,
        value,
        label: dayjs(point.bucketStartUtc).format(
          granularity === 'day' ? 'YYYY-MM-DD' : 'MM-DD HH:00',
        ),
      };
    })
    .filter(
      (point): point is { index: number; value: number; label: string } =>
        !!point,
    );

  const values = points.map((point) => point.value);

  if (values.length < 2) {
    return (
      <Empty
        image={Empty.PRESENTED_IMAGE_SIMPLE}
        description='No chart data'
      />
    );
  }

  const min = Math.min(...values);
  const max = Math.max(...values);
  const diff = max - min || 1;

  const projectedPoints = points.map((point) => {
    const x =
      chartLeft + (point.index / Math.max(data.length - 1, 1)) * chartWidth;
    const normalized = (point.value - min) / diff;
    const y = chartBottom - normalized * chartHeight;

    return {
      ...point,
      x,
      y,
    };
  });

  const polylinePoints = projectedPoints
    .map((point) => `${point.x},${point.y}`)
    .join(' ');

  const areaPoints = [
    `${projectedPoints[0].x},${chartBottom}`,
    ...projectedPoints.map((point) => `${point.x},${point.y}`),
    `${projectedPoints[projectedPoints.length - 1].x},${chartBottom}`,
  ].join(' ');

  const latest = projectedPoints[projectedPoints.length - 1]?.value;

  return (
    <Space
      direction='vertical'
      size={8}
      style={{ width: '100%' }}
    >
      <svg
        width='100%'
        viewBox={`0 0 ${width} ${height}`}
      >
        {[0, 1, 2, 3].map((tick) => {
          const y = chartTop + (tick / 3) * chartHeight;
          return (
            <line
              key={tick}
              x1={chartLeft}
              y1={y}
              x2={chartRight}
              y2={y}
              stroke='#e5e7eb'
              strokeWidth='1'
              strokeDasharray='3 3'
            />
          );
        })}

        <polyline
          fill='rgba(0,0,0,0.05)'
          stroke='none'
          points={areaPoints}
          style={{ color }}
        />

        <polyline
          fill='none'
          stroke={color}
          strokeWidth='2.5'
          points={polylinePoints}
          strokeLinecap='round'
        />

        {projectedPoints.map((point) => (
          <g key={`${point.index}-${point.value}`}>
            <circle
              cx={point.x}
              cy={point.y}
              r='2.6'
              fill={color}
            >
              <title>
                {point.label}: {point.value.toFixed(2)}
              </title>
            </circle>
          </g>
        ))}

        <text
          x={chartLeft}
          y={height - 12}
          fontSize='10'
          fill='#6b7280'
        >
          {projectedPoints[0].label}
        </text>
        <text
          x={chartRight}
          y={height - 12}
          fontSize='10'
          fill='#6b7280'
          textAnchor='end'
        >
          {projectedPoints[projectedPoints.length - 1].label}
        </text>
      </svg>

      <Flex justify='space-between'>
        <Typography.Text type='secondary'>
          Min: {formatValue(min)}
        </Typography.Text>
        <Typography.Text type='secondary'>
          Max: {formatValue(max)}
        </Typography.Text>
        <Typography.Text strong>Latest: {formatValue(latest)}</Typography.Text>
      </Flex>
    </Space>
  );
};

type LiveNoiseCrowdChartProps = {
  chartId: string;
  spaceTitle: string;
  rows: StoreContextRawLogItem[];
  isFetching: boolean;
  showSpaceHeading?: boolean;
};

const LiveNoiseCrowdChart = ({
  chartId,
  spaceTitle,
  rows,
  isFetching,
  showSpaceHeading = true,
}: LiveNoiseCrowdChartProps) => {
  const gradId = `live-${chartId.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
  const sorted = useMemo(
    () =>
      [...rows].sort(
        (a, b) =>
          dayjs(a.measuredAtUtc).valueOf() - dayjs(b.measuredAtUtc).valueOf(),
      ),
    [rows],
  );

  const { crowdPts, noisePts, crowdMin, crowdMax, noiseMin, noiseMax } =
    useMemo(() => {
      const cVals: number[] = [];
      const nVals: number[] = [];
      const c: { t: number; v: number }[] = [];
      const n: { t: number; v: number }[] = [];
      for (const r of sorted) {
        const t = dayjs(r.measuredAtUtc).valueOf();
        if (r.crowdDensity != null) {
          c.push({ t, v: r.crowdDensity });
          cVals.push(r.crowdDensity);
        }
        if (r.avgNoise != null) {
          n.push({ t, v: r.avgNoise });
          nVals.push(r.avgNoise);
        }
      }
      return {
        crowdPts: c,
        noisePts: n,
        crowdMin: cVals.length ? Math.min(...cVals) : 0,
        crowdMax: cVals.length ? Math.max(...cVals) : 1,
        noiseMin: nVals.length ? Math.min(...nVals) : 0,
        noiseMax: nVals.length ? Math.max(...nVals) : 1,
      };
    }, [sorted]);

  const width = 520;
  const height = 200;
  const padL = 44;
  const padR = 44;
  const padT = 16;
  const padB = 36;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;

  const tMin = sorted.length
    ? dayjs(sorted[0].measuredAtUtc).valueOf()
    : dayjs().valueOf();
  const tMax = sorted.length
    ? dayjs(sorted[sorted.length - 1].measuredAtUtc).valueOf()
    : tMin + 1;
  const tSpan = Math.max(tMax - tMin, 1);

  const scaleX = (t: number) => padL + ((t - tMin) / tSpan) * innerW;
  const scaleCrowd = (v: number) => {
    const span = Math.max(crowdMax - crowdMin, 1e-6);
    return padT + innerH - ((v - crowdMin) / span) * innerH;
  };
  const scaleNoise = (v: number) => {
    const span = Math.max(noiseMax - noiseMin, 1e-6);
    return padT + innerH - ((v - noiseMin) / span) * innerH;
  };

  const crowdLine =
    crowdPts.length > 0
      ? crowdPts.map((p) => `${scaleX(p.t)},${scaleCrowd(p.v)}`).join(' ')
      : '';
  const noiseLine =
    noisePts.length > 0
      ? noisePts.map((p) => `${scaleX(p.t)},${scaleNoise(p.v)}`).join(' ')
      : '';

  const lastCrowd = crowdPts[crowdPts.length - 1];
  const lastNoise = noisePts[noisePts.length - 1];

  if (sorted.length === 0) {
    return (
      <Empty
        image={Empty.PRESENTED_IMAGE_SIMPLE}
        description='No samples in this window yet.'
      />
    );
  }

  if (!crowdLine && !noiseLine) {
    return (
      <Empty
        image={Empty.PRESENTED_IMAGE_SIMPLE}
        description='No crowd / noise values in these rows.'
      />
    );
  }

  return (
    <div style={{ position: 'relative' }}>
      {isFetching && (
        <Tag
          color='processing'
          style={{ position: 'absolute', right: 0, top: 0, zIndex: 1 }}
        >
          Updating…
        </Tag>
      )}
      {showSpaceHeading && (
        <Typography.Text
          strong
          style={{ display: 'block', marginBottom: 8 }}
        >
          {spaceTitle}
        </Typography.Text>
      )}
      <svg
        width='100%'
        viewBox={`0 0 ${width} ${height}`}
        style={{
          filter: isFetching ? 'opacity(0.92)' : 'none',
          transition: 'filter 0.35s ease',
        }}
      >
        <defs>
          <linearGradient
            id={`${gradId}-crowd`}
            x1='0'
            y1='0'
            x2='0'
            y2='1'
          >
            <stop
              offset='0%'
              stopColor='#7c3aed'
              stopOpacity='0.35'
            />
            <stop
              offset='100%'
              stopColor='#7c3aed'
              stopOpacity='0.02'
            />
          </linearGradient>
          <linearGradient
            id={`${gradId}-noise`}
            x1='0'
            y1='0'
            x2='0'
            y2='1'
          >
            <stop
              offset='0%'
              stopColor='#059669'
              stopOpacity='0.3'
            />
            <stop
              offset='100%'
              stopColor='#059669'
              stopOpacity='0.02'
            />
          </linearGradient>
        </defs>

        {[0, 1, 2, 3].map((i) => {
          const y = padT + (i / 3) * innerH;
          return (
            <line
              key={i}
              x1={padL}
              y1={y}
              x2={width - padR}
              y2={y}
              stroke='#f0f0f0'
              strokeWidth='1'
            />
          );
        })}

        {crowdLine && crowdPts.length > 1 && (
          <polyline
            fill={`url(#${gradId}-crowd)`}
            stroke='none'
            points={`${scaleX(crowdPts[0].t)},${padT + innerH} ${crowdLine} ${scaleX(crowdPts[crowdPts.length - 1].t)},${padT + innerH}`}
          />
        )}
        {noiseLine && noisePts.length > 1 && (
          <polyline
            fill={`url(#${gradId}-noise)`}
            stroke='none'
            points={`${scaleX(noisePts[0].t)},${padT + innerH} ${noiseLine} ${scaleX(noisePts[noisePts.length - 1].t)},${padT + innerH}`}
          />
        )}

        {crowdLine && (
          <polyline
            fill='none'
            stroke='#7c3aed'
            strokeWidth='2.8'
            strokeLinecap='round'
            strokeLinejoin='round'
            points={crowdLine}
            style={{
              strokeDasharray: 800,
              strokeDashoffset: isFetching ? 40 : 0,
              transition:
                'stroke-dashoffset 0.6s ease, stroke-width 0.25s ease',
            }}
          />
        )}
        {noiseLine && (
          <polyline
            fill='none'
            stroke='#059669'
            strokeWidth='2.8'
            strokeLinecap='round'
            strokeLinejoin='round'
            points={noiseLine}
            style={{
              strokeDasharray: 800,
              strokeDashoffset: isFetching ? 40 : 0,
              transition:
                'stroke-dashoffset 0.6s ease, stroke-width 0.25s ease',
            }}
          />
        )}

        {lastCrowd && (
          <circle
            cx={scaleX(lastCrowd.t)}
            cy={scaleCrowd(lastCrowd.v)}
            r='5'
            fill='#7c3aed'
            className='store-live-dot'
            style={{ animationDelay: '0s' }}
          />
        )}
        {lastNoise && (
          <circle
            cx={scaleX(lastNoise.t)}
            cy={scaleNoise(lastNoise.v)}
            r='5'
            fill='#059669'
            className='store-live-dot'
            style={{ animationDelay: '0.25s' }}
          />
        )}

        <text
          x={4}
          y={padT + 12}
          fontSize='10'
          fill='#7c3aed'
        >
          Crowd
        </text>
        <text
          x={width - padR + 4}
          y={padT + 12}
          fontSize='10'
          fill='#059669'
          textAnchor='end'
        >
          Noise (dB)
        </text>
        <text
          x={padL}
          y={height - 8}
          fontSize='10'
          fill='#8c8c8c'
        >
          {dayjs(tMin).format('HH:mm:ss')}
        </text>
        <text
          x={width - padR}
          y={height - 8}
          fontSize='10'
          fill='#8c8c8c'
          textAnchor='end'
        >
          {dayjs(tMax).format('HH:mm:ss')}
        </text>
      </svg>
      <Flex
        gap={16}
        wrap='wrap'
        style={{ marginTop: 8 }}
      >
        <Typography.Text type='secondary'>
          Crowd:{' '}
          <Typography.Text
            strong
            style={{ color: '#7c3aed' }}
          >
            {lastCrowd ? lastCrowd.v : '—'}
          </Typography.Text>
        </Typography.Text>
        <Typography.Text type='secondary'>
          Noise:{' '}
          <Typography.Text
            strong
            style={{ color: '#059669' }}
          >
            {lastNoise ? `${lastNoise.v.toFixed(1)} dB` : '—'}
          </Typography.Text>
        </Typography.Text>
        <Typography.Text type='secondary'>
          Points: {sorted.length}
        </Typography.Text>
      </Flex>
    </div>
  );
};

export const StoreDashboard = () => {
  const { user } = useAuth();
  const storeId = user?.storeId || undefined;

  const [period, setPeriod] = useState<PeriodOption>('day');
  const [granularity, setGranularity] = useState<GranularityOption>('hour');
  const [spaceId, setSpaceId] = useState<string | undefined>(undefined);
  const [range, setRange] = useState<RangeValue>(() => getRangeByPeriod('day'));
  const [rawPage, setRawPage] = useState(1);
  const [rawPageSize, setRawPageSize] = useState(10);
  const [showRawLogs, setShowRawLogs] = useState(false);

  const effectiveRange = useMemo(() => {
    if (period === 'custom') {
      return range;
    }

    return getRangeByPeriod(period);
  }, [period, range]);

  const fromUtc = effectiveRange[0].toDate().toISOString();
  const toUtc = effectiveRange[1].toDate().toISOString();

  const walletQuery = useQuery({
    queryKey: ['store-dashboard', 'wallet'],
    queryFn: async () => {
      const response = await billingService.getWallet();
      return response.data.data ?? null;
    },
    staleTime: STALE_TIME.medium,
  });

  const usageTodayQuery = useQuery({
    queryKey: ['store-dashboard', 'usage-today', storeId],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const today = dayjs().format('YYYY-MM-DD');
      const response = await billingService.getUsage({
        storeId,
        fromBusinessDate: today,
        toBusinessDate: today,
        limit: 200,
      });
      return response.data.data ?? [];
    },
    enabled: !!storeId,
    staleTime: STALE_TIME.short,
  });

  const usageLogQuery = useQuery({
    queryKey: ['store-dashboard', 'usage-log', storeId],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const response = await billingService.getUsage({ storeId, limit: 40 });
      return response.data.data ?? [];
    },
    enabled: !!storeId,
    staleTime: STALE_TIME.short,
  });

  const { data: spaces, isLoading: isLoadingSpaces } = useQuery({
    queryKey: ['store-dashboard', 'spaces', storeId],
    queryFn: async () => {
      if (!storeId) return [] as SpaceListItem[];

      const response = await spaceService.getList({
        page: 1,
        pageSize: 200,
        status: EntityStatusEnum.Active,
      });
      return response.data.items || [];
    },
    enabled: !!storeId,
    staleTime: STALE_TIME.medium,
  });

  const spaceNameById = useMemo(() => {
    const m = new Map<string, string>();
    (spaces ?? []).forEach((s) => m.set(s.id, s.name));
    return m;
  }, [spaces]);

  const liveLogsQuery = useQuery({
    queryKey: [
      'store-dashboard',
      'live-logs',
      storeId,
      spaceId,
      fromUtc,
      toUtc,
    ],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const response = await storeService.getContextRawLogs(storeId, {
        page: 1,
        pageSize: LIVE_PAGE_SIZE,
        spaceId,
        fromUtc,
        toUtc,
      });
      return response.data;
    },
    enabled: !!storeId,
    staleTime: 0,
    refetchInterval: LIVE_POLL_MS,
    refetchIntervalInBackground: true,
  });

  const rawLogsQuery = useQuery({
    queryKey: [
      'store-dashboard',
      'raw-logs',
      storeId,
      spaceId,
      fromUtc,
      toUtc,
      rawPage,
      rawPageSize,
    ],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const response = await storeService.getContextRawLogs(storeId, {
        page: rawPage,
        pageSize: rawPageSize,
        spaceId,
        fromUtc,
        toUtc,
      });
      return response.data;
    },
    enabled: !!storeId && showRawLogs,
    staleTime: STALE_TIME.short,
  });

  const timeSeriesQuery = useQuery({
    queryKey: [
      'store-dashboard',
      'time-series',
      storeId,
      spaceId,
      granularity,
      fromUtc,
      toUtc,
    ],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const response = await storeService.getContextTimeSeries(storeId, {
        spaceId,
        fromUtc,
        toUtc,
        granularity,
      });
      return response.data.data;
    },
    enabled: !!storeId,
    staleTime: STALE_TIME.short,
  });

  const aggregateQuery = useQuery({
    queryKey: [
      'store-dashboard',
      'aggregate',
      storeId,
      spaceId,
      fromUtc,
      toUtc,
    ],
    queryFn: async () => {
      if (!storeId) throw new Error('Store ID is required.');
      const response = await storeService.getContextAggregate(storeId, {
        spaceId,
        fromUtc,
        toUtc,
      });
      return response.data.data;
    },
    enabled: !!storeId,
    staleTime: STALE_TIME.short,
  });

  const liveChartsBySpace = useMemo(() => {
    const items = liveLogsQuery.data?.items ?? [];
    if (items.length === 0) {
      return [] as {
        key: string;
        title: string;
        rows: StoreContextRawLogItem[];
      }[];
    }

    if (spaceId) {
      const filtered = items.filter((r) => r.spaceId === spaceId);
      const title =
        filtered[0]?.spaceName ||
        spaces?.find((s) => s.id === spaceId)?.name ||
        'Selected space';
      return [{ key: spaceId, title, rows: filtered }];
    }

    const map = new Map<
      string,
      { title: string; rows: StoreContextRawLogItem[] }
    >();
    for (const r of items) {
      const key = r.spaceId || r.spaceName;
      if (!map.has(key)) {
        map.set(key, { title: r.spaceName, rows: [] });
      }
      map.get(key)!.rows.push(r);
    }

    return Array.from(map.entries()).map(([key, v]) => ({
      key,
      title: v.title,
      rows: v.rows,
    }));
  }, [liveLogsQuery.data?.items, spaceId, spaces]);

  const idsToPollPlayback = useMemo(() => {
    const fromCharts = liveChartsBySpace
      .map((b) => resolveSpaceIdForPlayback(b.key, b.title, spaces))
      .filter((id): id is string => !!id);
    if (fromCharts.length > 0) {
      return [...new Set(fromCharts)];
    }
    if (spaceId) return [spaceId];
    return (spaces ?? []).map((s) => s.id);
  }, [liveChartsBySpace, spaceId, spaces]);

  const playbackStateQueries = useQueries({
    queries: idsToPollPlayback.map((id) => ({
      queryKey: ['store-dashboard', 'space-playback-state', id] as const,
      queryFn: async (): Promise<SpaceStateResponse | null> => {
        const res = await camsService.getSpaceState(id);
        const body = res.data;
        if (!body?.isSuccess || !body.data) return null;
        return body.data;
      },
      enabled: !!storeId && idsToPollPlayback.length > 0,
      staleTime: 0,
      refetchInterval: LIVE_POLL_MS,
      refetchIntervalInBackground: true,
    })),
  });

  const playbackStateBySpaceId = useMemo(() => {
    const m = new Map<string, PlaybackPollSlot>();
    idsToPollPlayback.forEach((sid, i) => {
      const q = playbackStateQueries[i];
      m.set(sid, {
        state: q?.data ?? null,
        isPending: q?.isPending ?? false,
        isFetching: q?.isFetching ?? false,
      });
    });
    return m;
  }, [idsToPollPlayback, playbackStateQueries]);

  const handlePeriodChange = (value: string | number) => {
    const nextPeriod = value as PeriodOption;
    setPeriod(nextPeriod);
    if (nextPeriod !== 'custom') {
      setRange(getRangeByPeriod(nextPeriod));
    }
    setRawPage(1);
  };

  const handleResetFilters = () => {
    setPeriod('day');
    setRange(getRangeByPeriod('day'));
    setGranularity('hour');
    setSpaceId(undefined);
    setRawPage(1);
    setRawPageSize(10);
  };

  const tokenUsageColumns: ColumnsType<BillingUsageView> = [
    {
      title: 'Time (UTC)',
      dataIndex: 'chargedAtUtc',
      key: 'chargedAtUtc',
      render: (value: string) => dayjs(value).format('YYYY-MM-DD HH:mm'),
      width: 155,
    },
    {
      title: 'Type',
      dataIndex: 'usageType',
      key: 'usageType',
      width: 140,
    },
    {
      title: 'Tokens',
      dataIndex: 'tokensCharged',
      key: 'tokensCharged',
      width: 80,
    },
    {
      title: 'Space',
      dataIndex: 'spaceId',
      key: 'spaceId',
      width: 168,
      ellipsis: true,
      render: (id: string | null) =>
        id ? (spaceNameById.get(id) ?? `${id.slice(0, 8)}…`) : '—',
    },
    {
      title: 'Source',
      dataIndex: 'source',
      key: 'source',
      ellipsis: true,
    },
  ];

  const rawColumns: ColumnsType<StoreContextRawLogItem> = [
    {
      title: 'Measured At (UTC)',
      dataIndex: 'measuredAtUtc',
      key: 'measuredAtUtc',
      render: (value: string) => dayjs(value).format('YYYY-MM-DD HH:mm:ss'),
      width: 180,
    },
    {
      title: 'Space',
      dataIndex: 'spaceName',
      key: 'spaceName',
      width: 160,
    },
    {
      title: 'Mood',
      dataIndex: 'moodName',
      key: 'moodName',
      width: 140,
    },
    {
      title: 'Noise',
      dataIndex: 'avgNoise',
      key: 'avgNoise',
      render: (value?: number | null) => `${formatValue(value)} dB`,
      width: 120,
    },
    {
      title: 'Crowd',
      dataIndex: 'crowdDensity',
      key: 'crowdDensity',
      render: (value?: number | null) => formatValue(value, 0),
      width: 100,
    },
    {
      title: 'Weather',
      dataIndex: 'currentWeather',
      key: 'currentWeather',
      render: (value?: string | null) => value || '--',
      width: 140,
    },
  ];

  const summary = aggregateQuery.data;
  const hasAnyTrendData = !!summary && summary.current.samples > 0;

  const isAnyRefreshing =
    liveLogsQuery.isFetching ||
    timeSeriesQuery.isFetching ||
    aggregateQuery.isFetching ||
    (showRawLogs && rawLogsQuery.isFetching);

  return (
    <div>
      <style>
        {`
          @keyframes store-live-pulse {
            0%, 100% { opacity: 1; filter: drop-shadow(0 0 4px currentColor); }
            50% { opacity: 0.35; filter: drop-shadow(0 0 10px currentColor); }
          }
          .store-live-dot {
            animation: store-live-pulse 1.5s ease-in-out infinite;
          }
          @keyframes store-now-playing-beat {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.08); opacity: 0.85; }
          }
          .store-now-playing-icon {
            animation: store-now-playing-beat 1.4s ease-in-out infinite;
          }
        `}
      </style>
      <PageHeader
        title='Store Context Analytics'
        breadcrumbs={[{ title: 'Store' }, { title: 'Dashboard' }]}
        seo={{
          description:
            'Live crowd & noise telemetry, token wallet, and optional raw context logs.',
          keywords: 'store dashboard, crowd, noise, telemetry',
        }}
      />

      {!storeId && (
        <Alert
          type='warning'
          showIcon
          message='Store scope is missing. Please re-login.'
          className='mb-4!'
        />
      )}

      {/* ── Token Wallet Overview ── */}
      <Card
        style={{ marginBottom: 16 }}
        title={
          <Flex
            align='center'
            gap={8}
          >
            <WalletOutlined />
            <span>Token Wallet</span>
            {walletQuery.data?.isLocked && (
              <Tooltip
                title={`Locked from ${walletQuery.data.lockedFromBusinessDate ?? ''}`}
              >
                <Tag
                  icon={<LockOutlined />}
                  color='error'
                >
                  Locked
                </Tag>
              </Tooltip>
            )}
          </Flex>
        }
        extra={
          <Button
            size='small'
            icon={<ReloadOutlined />}
            onClick={() => {
              walletQuery.refetch();
              usageTodayQuery.refetch();
              usageLogQuery.refetch();
            }}
          >
            Refresh
          </Button>
        }
      >
        {walletQuery.isLoading ? (
          <Skeleton
            active
            paragraph={{ rows: 1 }}
          />
        ) : walletQuery.isError ? (
          <Alert
            type='error'
            showIcon
            message='Failed to load wallet'
          />
        ) : (
          <Row
            gutter={[24, 16]}
            align='middle'
          >
            <Col
              xs={24}
              sm={8}
            >
              <Statistic
                title='Token Balance'
                value={walletQuery.data?.balanceTokens ?? 0}
                valueStyle={{
                  color:
                    (walletQuery.data?.balanceTokens ?? 0) < 0
                      ? '#cf1322'
                      : '#3f8600',
                  fontWeight: 700,
                }}
                suffix='tokens'
              />
            </Col>
            <Col
              xs={24}
              sm={8}
            >
              <Statistic
                title='Status'
                value={walletQuery.data?.lockStatus ?? '--'}
                valueStyle={{
                  color: walletQuery.data?.isLocked ? '#cf1322' : '#3f8600',
                  fontSize: 16,
                }}
              />
            </Col>
            <Col
              xs={24}
              sm={8}
            >
              <Statistic
                title="Today's Usage (streams)"
                loading={usageTodayQuery.isLoading}
                value={(usageTodayQuery.data ?? [])
                  .filter((u) => u.usageType === 'StreamingSpaceDaily')
                  .reduce((sum, u) => sum + u.tokensCharged, 0)}
                suffix='tokens'
              />
            </Col>
          </Row>
        )}
      </Card>

      {walletQuery.data?.isLocked && (
        <Alert
          type='error'
          showIcon
          className='mb-4!'
          icon={<LockOutlined />}
          message='Playback & AI generation are locked'
          description={`Wallet is locked from ${walletQuery.data.lockedFromBusinessDate ?? 'an earlier date'}. Please top up tokens to resume.`}
        />
      )}

      <Card
        style={{ marginBottom: 16 }}
        title='Token deductions (this store)'
        extra={
          <Button
            size='small'
            icon={<ReloadOutlined />}
            loading={usageLogQuery.isFetching || usageTodayQuery.isFetching}
            disabled={!storeId}
            onClick={() => {
              usageLogQuery.refetch();
              usageTodayQuery.refetch();
            }}
          >
            Refresh
          </Button>
        }
      >
        {!storeId ? (
          <Typography.Text type='secondary'>
            Store scope is required to list per-store token charges.
          </Typography.Text>
        ) : usageLogQuery.isLoading ? (
          <Skeleton active />
        ) : usageLogQuery.isError ? (
          <Alert
            type='error'
            showIcon
            message={getErrorMessage(usageLogQuery.error)}
          />
        ) : (
          <Table<BillingUsageView>
            size='small'
            rowKey={(r, i) => `${r.chargedAtUtc}-${i}`}
            pagination={false}
            dataSource={usageLogQuery.data ?? []}
            columns={tokenUsageColumns}
            locale={{ emptyText: 'No token charges for this store yet.' }}
          />
        )}
      </Card>

      <Card style={{ marginBottom: 16 }}>
        <Space
          direction='vertical'
          size='middle'
          style={{ width: '100%' }}
        >
          <Flex
            justify='space-between'
            wrap='wrap'
            gap={12}
          >
            <Space wrap>
              <Segmented
                size='large'
                value={period}
                onChange={handlePeriodChange}
                options={[
                  { label: 'Day', value: 'day' },
                  { label: 'Week', value: 'week' },
                  { label: 'Month', value: 'month' },
                  { label: 'Custom', value: 'custom' },
                ]}
              />

              <DatePicker.RangePicker
                size='large'
                value={range}
                onChange={(value) => {
                  if (!value || !value[0] || !value[1]) return;
                  setRange([value[0], value[1]]);
                  if (period !== 'custom') {
                    setPeriod('custom');
                  }
                  setRawPage(1);
                }}
                showTime
                allowClear={false}
              />
            </Space>

            <Space wrap>
              <Select
                size='large'
                style={{ width: 260 }}
                placeholder='Filter by space'
                value={spaceId}
                onChange={(value) => {
                  setSpaceId(value);
                  setRawPage(1);
                }}
                allowClear
                loading={isLoadingSpaces}
                showSearch
                optionFilterProp='label'
                options={(spaces || []).map((space) => ({
                  label: space.name,
                  value: space.id,
                }))}
              />

              <Select
                size='large'
                style={{ width: 180 }}
                placeholder='Chart granularity'
                value={granularity}
                onChange={(value: GranularityOption) => setGranularity(value)}
                options={[
                  { label: 'By Hour', value: 'hour' },
                  { label: 'By Day', value: 'day' },
                ]}
              />

              <Button
                size='large'
                icon={<ReloadOutlined />}
                onClick={() => {
                  liveLogsQuery.refetch();
                  timeSeriesQuery.refetch();
                  aggregateQuery.refetch();
                  if (showRawLogs) rawLogsQuery.refetch();
                }}
              >
                Refresh
              </Button>

              <Button
                size='large'
                onClick={handleResetFilters}
              >
                Reset Filters
              </Button>
            </Space>
          </Flex>

          <Typography.Text type='secondary'>
            Window: {dayjs(fromUtc).format('YYYY-MM-DD HH:mm')} -{' '}
            {dayjs(toUtc).format('YYYY-MM-DD HH:mm')} (UTC)
          </Typography.Text>

          <Typography.Text type='secondary'>
            Live charts refresh every {LIVE_POLL_MS / 1000}s (up to{' '}
            {LIVE_PAGE_SIZE} recent rows per request).
          </Typography.Text>

          {isAnyRefreshing &&
            !liveLogsQuery.isLoading &&
            !timeSeriesQuery.isLoading &&
            !aggregateQuery.isLoading && (
              <Tag color='processing'>Updating…</Tag>
            )}
        </Space>
      </Card>

      {aggregateQuery.isError && (
        <Alert
          type='error'
          showIcon
          className='mb-4!'
          message='Failed to load aggregate analytics'
          description={getErrorMessage(aggregateQuery.error)}
        />
      )}

      {timeSeriesQuery.isError && (
        <Alert
          type='error'
          showIcon
          className='mb-4!'
          message='Failed to load time-series analytics'
          description={getErrorMessage(timeSeriesQuery.error)}
        />
      )}

      {liveLogsQuery.isError && (
        <Alert
          type='error'
          showIcon
          className='mb-4!'
          message='Failed to load live telemetry'
          description={getErrorMessage(liveLogsQuery.error)}
        />
      )}

      <Row gutter={[16, 16]}>
        <Col
          xs={24}
          lg={6}
        >
          <Card>
            {aggregateQuery.isLoading ? (
              <Skeleton
                active
                paragraph={{ rows: 2 }}
                title={false}
              />
            ) : (
              <>
                <Statistic
                  title='Current Samples'
                  value={summary?.current.samples ?? 0}
                />
                <div style={{ marginTop: 8 }}>
                  {formatTrend(summary?.trend.samples || {})}
                </div>
              </>
            )}
          </Card>
        </Col>

        <Col
          xs={24}
          lg={18}
        >
          <Card title='Aggregate — Crowd & Noise'>
            {aggregateQuery.isLoading ? (
              <Skeleton
                active
                paragraph={{ rows: 4 }}
              />
            ) : !hasAnyTrendData ? (
              <Empty
                image={Empty.PRESENTED_IMAGE_SIMPLE}
                description='No aggregate data for the selected filters.'
              />
            ) : (
              <Row gutter={[16, 16]}>
                {metricCards.map((metric) => {
                  const aggregate = summary?.current[metric.key];
                  const trend = summary?.trend[metric.key];

                  return (
                    <Col
                      xs={24}
                      sm={12}
                      key={metric.key}
                    >
                      <Card size='small'>
                        <Flex
                          justify='space-between'
                          align='center'
                        >
                          <Typography.Text strong>
                            {metric.title}
                          </Typography.Text>
                          {formatTrend((trend || {}) as MetricTrend)}
                        </Flex>
                        <div style={{ marginTop: 12 }}>
                          <Typography.Text type='secondary'>
                            Min: {formatValue(aggregate?.min)} {metric.unit}
                          </Typography.Text>
                          <br />
                          <Typography.Text type='secondary'>
                            Max: {formatValue(aggregate?.max)} {metric.unit}
                          </Typography.Text>
                          <br />
                          <Typography.Text>
                            Avg: <b>{formatValue(aggregate?.avg)}</b>{' '}
                            {metric.unit}
                          </Typography.Text>
                        </div>
                      </Card>
                    </Col>
                  );
                })}
              </Row>
            )}
          </Card>
        </Col>
      </Row>

      <Card
        title='Live telemetry — Crowd, Noise & playback'
        style={{ marginTop: 16 }}
        extra={
          <Space>
            <Tag color='blue'>Telemetry + track · {LIVE_POLL_MS / 1000}s</Tag>
          </Space>
        }
      >
        {liveLogsQuery.isLoading && !liveLogsQuery.data ? (
          <Flex
            justify='center'
            style={{ padding: '28px 0' }}
          >
            <Spin size='large' />
          </Flex>
        ) : liveChartsBySpace.length === 0 ? (
          <Space
            direction='vertical'
            size='large'
            style={{ width: '100%' }}
          >
            <Empty
              image={Empty.PRESENTED_IMAGE_SIMPLE}
              description='No telemetry in this window. Adjust filters or wait for new samples.'
            />
            {idsToPollPlayback.length > 0 && (
              <>
                <Typography.Title
                  level={5}
                  style={{ marginBottom: 0 }}
                >
                  Now playing (realtime)
                </Typography.Title>
                <Typography.Paragraph
                  type='secondary'
                  style={{ marginTop: 0 }}
                >
                  Track name updates every {LIVE_POLL_MS / 1000}s from CAMS
                  state.
                </Typography.Paragraph>
                <Row gutter={[16, 16]}>
                  {idsToPollPlayback.map((sid) => {
                    const label =
                      spaces?.find((s) => s.id === sid)?.name ?? sid;
                    return (
                      <Col
                        xs={24}
                        md={12}
                        key={sid}
                      >
                        <Card
                          size='small'
                          styles={{ body: { background: '#fafafa' } }}
                        >
                          <NowPlayingBanner
                            spaceLabel={label}
                            slot={playbackStateBySpaceId.get(sid)}
                          />
                        </Card>
                      </Col>
                    );
                  })}
                </Row>
              </>
            )}
          </Space>
        ) : (
          <Row gutter={[20, 24]}>
            {liveChartsBySpace.map((block) => {
              const sid = resolveSpaceIdForPlayback(
                block.key,
                block.title,
                spaces,
              );
              const playbackSlot = sid
                ? playbackStateBySpaceId.get(sid)
                : undefined;
              return (
                <Col
                  xs={24}
                  lg={spaceId ? 24 : 12}
                  key={block.key}
                >
                  <Card
                    size='small'
                    styles={{
                      body: { background: '#fafafa', borderRadius: 8 },
                    }}
                  >
                    <NowPlayingBanner
                      spaceLabel={block.title}
                      slot={playbackSlot}
                    />
                    <LiveNoiseCrowdChart
                      chartId={block.key}
                      spaceTitle={block.title}
                      rows={block.rows}
                      isFetching={liveLogsQuery.isFetching}
                      showSpaceHeading={false}
                    />
                  </Card>
                </Col>
              );
            })}
          </Row>
        )}
      </Card>

      <Card
        title='Context time-series (bucketed)'
        style={{ marginTop: 16 }}
      >
        {timeSeriesQuery.isLoading ? (
          <Flex
            justify='center'
            style={{ padding: '28px 0' }}
          >
            <Spin size='large' />
          </Flex>
        ) : (timeSeriesQuery.data?.points?.length || 0) === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description='No time-series data for this range.'
          />
        ) : (
          <Row gutter={[16, 16]}>
            {metricCards.map((metric) => (
              <Col
                xs={24}
                md={12}
                key={metric.key}
              >
                <Card
                  size='small'
                  title={metric.title}
                >
                  <MiniLineChart
                    data={timeSeriesQuery.data?.points || []}
                    dataKey={metric.dataKey}
                    color={metric.lineColor}
                    granularity={granularity}
                  />
                </Card>
              </Col>
            ))}
          </Row>
        )}
      </Card>

      <Card
        style={{ marginTop: 16 }}
        title='Raw context logs'
        extra={
          <Button
            type={showRawLogs ? 'default' : 'primary'}
            icon={<TableOutlined />}
            onClick={() => setShowRawLogs((v) => !v)}
          >
            {showRawLogs ? 'Hide table' : 'Show raw log table'}
          </Button>
        }
      >
        {showRawLogs ? (
          <>
            {rawLogsQuery.isError && (
              <Alert
                type='error'
                showIcon
                className='mb-4!'
                message='Failed to load raw logs'
                description={getErrorMessage(rawLogsQuery.error)}
              />
            )}
            <Table
              rowKey='id'
              columns={rawColumns}
              dataSource={rawLogsQuery.data?.items || []}
              loading={rawLogsQuery.isLoading}
              scroll={{ x: 900 }}
              locale={{
                emptyText: rawLogsQuery.isLoading
                  ? 'Loading logs…'
                  : 'No context logs for the current filters.',
              }}
              pagination={{
                current: rawLogsQuery.data?.currentPage || rawPage,
                pageSize: rawLogsQuery.data?.pageSize || rawPageSize,
                total: rawLogsQuery.data?.totalItems || 0,
                showSizeChanger: true,
                onChange: (page, pageSize) => {
                  setRawPage(page);
                  setRawPageSize(pageSize);
                },
              }}
            />
          </>
        ) : (
          <Typography.Text type='secondary'>
            Raw rows are hidden by default. Use the button above when you need
            to inspect individual measurements (pagination applies).
          </Typography.Text>
        )}
      </Card>
    </div>
  );
};
