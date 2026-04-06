import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  App,
  Button,
  Card,
  Col,
  Form,
  Row,
  Space,
  Spin,
  Tag,
  TimePicker,
  Typography,
} from 'antd';
import { ReloadOutlined, SaveOutlined } from '@ant-design/icons';
import { useMutation, useQuery } from '@tanstack/react-query';
import dayjs from 'dayjs';

/**
 * Providers
 */
import { useAuth } from '@/providers';
import { useStore } from '@/features/brand/hooks/store';

/**
 * Components
 */
import { PageHeader } from '@/shared/components';

/**
 * Config
 */
import { api } from '@/config';

/**
 * Types
 */
import type { Dayjs } from 'dayjs';
import type { Result } from '@/shared/types';

/**
 * Utils
 */
import { showErrorMessage } from '@/shared/utils';

type StoreConfigItem = {
  id: string;
  storeId: string;
  key: string;
  value: string;
  description?: string | null;
  category?: string | null;
  dataType?: string | null;
};

type BusinessHoursForm = {
  openTime?: Dayjs;
  closeTime?: Dayjs;
};

const STORE_CONFIG_ENDPOINT = '/api/cms/store-configs';
const OPEN_KEY = 'Store:OpenTime';
const CLOSE_KEY = 'Store:CloseTime';

const parseTime = (value?: string | null) => {
  if (!value) return undefined;

  const parsed = dayjs(value, ['HH:mm', 'HH:mm:ss'], true);
  return parsed.isValid() ? parsed : undefined;
};

const toMinutes = (value?: string | null) => {
  const parsed = parseTime(value);
  if (!parsed) return null;
  return parsed.hour() * 60 + parsed.minute();
};

const getLocalClockByTimezone = (date: Date, timeZone: string) => {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
  });

  const parts = formatter.formatToParts(date);
  const hour = Number(parts.find((part) => part.type === 'hour')?.value || '0');
  const minute = Number(
    parts.find((part) => part.type === 'minute')?.value || '0',
  );

  return {
    label: `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`,
    minutes: hour * 60 + minute,
  };
};

export const StoreSettings = () => {
  const { message } = App.useApp();
  const { user } = useAuth();
  const [form] = Form.useForm<BusinessHoursForm>();
  const [now, setNow] = useState(() => new Date());

  const storeId = user?.storeId || undefined;
  const { data: store } = useStore(storeId, !!storeId);

  const {
    data: configs,
    isLoading,
    refetch,
    isRefetching,
  } = useQuery({
    queryKey: ['store-settings', 'business-hours', storeId],
    queryFn: async () => {
      const response = await api.get<Result<StoreConfigItem[]>>(
        `${STORE_CONFIG_ENDPOINT}/store/${storeId}`,
      );
      return response.data.data || [];
    },
    enabled: !!storeId,
  });

  const openConfig = useMemo(
    () => configs?.find((config) => config.key === OPEN_KEY),
    [configs],
  );

  const closeConfig = useMemo(
    () => configs?.find((config) => config.key === CLOSE_KEY),
    [configs],
  );

  const timeZone = store?.timeZone || 'UTC';

  const { localClockLabel, localClockMinutes } = useMemo(() => {
    try {
      const localClock = getLocalClockByTimezone(now, timeZone);
      return {
        localClockLabel: localClock.label,
        localClockMinutes: localClock.minutes,
      };
    } catch {
      const fallbackClock = getLocalClockByTimezone(now, 'UTC');
      return {
        localClockLabel: fallbackClock.label,
        localClockMinutes: fallbackClock.minutes,
      };
    }
  }, [now, timeZone]);

  const openMinutes = useMemo(
    () => toMinutes(openConfig?.value),
    [openConfig?.value],
  );
  const closeMinutes = useMemo(
    () => toMinutes(closeConfig?.value),
    [closeConfig?.value],
  );

  const isWindowConfigured =
    openMinutes !== null && closeMinutes !== null && openMinutes < closeMinutes;

  const isOpenNow =
    isWindowConfigured &&
    localClockMinutes >= openMinutes &&
    localClockMinutes < closeMinutes;

  useEffect(() => {
    const timer = window.setInterval(() => {
      setNow(new Date());
    }, 30000);

    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    form.setFieldsValue({
      openTime: parseTime(openConfig?.value),
      closeTime: parseTime(closeConfig?.value),
    });
  }, [form, openConfig?.value, closeConfig?.value]);

  const saveBusinessHours = useMutation({
    mutationFn: async (values: BusinessHoursForm) => {
      if (!storeId) throw new Error('Store scope is missing. Please re-login.');
      if (!values.openTime || !values.closeTime)
        throw new Error('Please set both open and close times.');

      const openValue = values.openTime.format('HH:mm');
      const closeValue = values.closeTime.format('HH:mm');

      const upsert = async (
        key: string,
        value: string,
        currentConfig?: StoreConfigItem,
      ) => {
        const payload = {
          key,
          value,
          description: 'Store business hours',
          category: 'CAMS',
          dataType: 'time',
        };

        if (currentConfig) {
          await api.put<Result<StoreConfigItem>>(
            `${STORE_CONFIG_ENDPOINT}/${currentConfig.id}`,
            payload,
          );
          return;
        }

        await api.post<Result<StoreConfigItem>>(STORE_CONFIG_ENDPOINT, {
          storeId,
          ...payload,
        });
      };

      await upsert(OPEN_KEY, openValue, openConfig);
      await upsert(CLOSE_KEY, closeValue, closeConfig);
    },
    onSuccess: async () => {
      message.success('Business hours updated successfully.');
      await refetch();
    },
    onError: (error: unknown) => {
      showErrorMessage(error, 'Failed to update business hours.');
    },
  });

  const handleSave = (values: BusinessHoursForm) => {
    saveBusinessHours.mutate(values);
  };

  const breadcrumbs = [{ title: 'Store' }, { title: 'Settings' }];

  return (
    <div>
      <PageHeader
        title='Store Settings'
        breadcrumbs={breadcrumbs}
        seo={{
          description: 'Configure store business hours for CAMS automation.',
          keywords: 'store settings, business hours, cams',
        }}
      />

      {!storeId && (
        <Alert
          type='warning'
          showIcon
          message='Store scope is missing. Please re-login and try again.'
          className='mb-4!'
        />
      )}

      <Card
        title='Business Hours'
        extra={
          <Space>
            <Button
              size='large'
              icon={<ReloadOutlined />}
              onClick={() => refetch()}
              loading={isRefetching}
            >
              Refresh
            </Button>
            <Button
              size='large'
              type='primary'
              icon={<SaveOutlined />}
              loading={saveBusinessHours.isPending}
              onClick={() => form.submit()}
              disabled={!storeId}
            >
              Save
            </Button>
          </Space>
        }
      >
        {isLoading ? (
          <Spin />
        ) : (
          <Form
            size='large'
            form={form}
            layout='vertical'
            onFinish={handleSave}
            disabled={!storeId}
          >
            <Alert
              showIcon
              type={
                isWindowConfigured
                  ? isOpenNow
                    ? 'success'
                    : 'warning'
                  : 'info'
              }
              message={
                <Space>
                  <span>Current Status:</span>
                  <Tag
                    color={
                      isWindowConfigured
                        ? isOpenNow
                          ? 'green'
                          : 'orange'
                        : 'default'
                    }
                  >
                    {isWindowConfigured
                      ? isOpenNow
                        ? 'Open'
                        : 'Closed'
                      : 'Not Configured'}
                  </Tag>
                </Space>
              }
              description={
                <Space
                  direction='vertical'
                  size={2}
                >
                  <Typography.Text type='secondary'>
                    Local time ({timeZone}): {localClockLabel}
                  </Typography.Text>
                  <Typography.Text type='secondary'>
                    Window: {openConfig?.value || '--:--'} -{' '}
                    {closeConfig?.value || '--:--'}
                  </Typography.Text>
                </Space>
              }
              className='mb-4!'
            />

            <Row gutter={[16, 16]}>
              <Col
                xs={24}
                md={12}
              >
                <Form.Item<BusinessHoursForm>
                  label='Open Time'
                  name='openTime'
                  rules={[{ required: true, message: 'Open time is required' }]}
                >
                  <TimePicker
                    style={{ width: '100%' }}
                    format='HH:mm'
                    minuteStep={5}
                    allowClear={false}
                  />
                </Form.Item>
              </Col>

              <Col
                xs={24}
                md={12}
              >
                <Form.Item<BusinessHoursForm>
                  label='Close Time'
                  name='closeTime'
                  rules={[
                    { required: true, message: 'Close time is required' },
                    ({ getFieldValue }) => ({
                      validator(_, value: Dayjs | undefined) {
                        const open = getFieldValue('openTime') as
                          | Dayjs
                          | undefined;
                        if (!open || !value) return Promise.resolve();
                        if (open.isBefore(value)) return Promise.resolve();
                        return Promise.reject(
                          new Error('Close time must be later than open time.'),
                        );
                      },
                    }),
                  ]}
                >
                  <TimePicker
                    style={{ width: '100%' }}
                    format='HH:mm'
                    minuteStep={5}
                    allowClear={false}
                  />
                </Form.Item>
              </Col>
            </Row>

            <Alert
              showIcon
              type='info'
              message='Playback orchestration only runs during open hours.'
              description={
                <Typography.Text type='secondary'>
                  The current track can continue playing, but CAMS will skip
                  analysis and refill when the store is outside this configured
                  window.
                </Typography.Text>
              }
            />
          </Form>
        )}
      </Card>
    </div>
  );
};
