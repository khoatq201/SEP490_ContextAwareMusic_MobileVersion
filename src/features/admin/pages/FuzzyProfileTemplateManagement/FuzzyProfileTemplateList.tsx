import { useEffect, useState } from 'react';
import {
  App,
  Button,
  Drawer,
  Form,
  Input,
  InputNumber,
  Popconfirm,
  Space,
  Switch,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useNavigate } from 'react-router';
import { PlusOutlined } from '@ant-design/icons';

import { PageHeader } from '@/shared/components';
import { PAGINATION_SIZES } from '@/shared/constants';
import type { FuzzyProfileTemplateDetail } from '@/features/admin/types';
import {
  useCreateFuzzyProfileTemplate,
  useDeleteFuzzyProfileTemplate,
  useFuzzyProfileTemplateDetail,
  useFuzzyProfileTemplatesManage,
  useUpdateFuzzyProfileTemplate,
} from '@/features/admin/hooks';

const DEFAULT_CREATE_VALUES: Partial<FuzzyProfileTemplateDetail> = {
  templateKey: '',
  displayName: '',
  profileDescription: '',
  chillMoodDescription: '',
  focusMoodDescription: '',
  energeticMoodDescription: '',
  sortOrder: 0,
  chillBpmMin: 60,
  chillBpmMax: 80,
  focusBpmMin: 85,
  focusBpmMax: 105,
  energeticBpmMin: 120,
  energeticBpmMax: 140,
  pressureLowMax: 2,
  pressureCriticalMin: 5,
  noiseQuietMaxDb: 50,
  noiseLoudMinDb: 75,
  spaceCapacity: 30,
  defaultDecibelWhenNull: 60,
};

const gridStyle: React.CSSProperties = {
  display: 'grid',
  gridTemplateColumns: '1fr 1fr',
  gap: '0 16px',
};

export const FuzzyProfileTemplateList = () => {
  const navigate = useNavigate();
  const { message } = App.useApp();
  const [form] = Form.useForm();
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [mode, setMode] = useState<'create' | 'edit'>('create');
  const [editingId, setEditingId] = useState<string | undefined>();

  const { data, isLoading, refetch } = useFuzzyProfileTemplatesManage(
    page,
    pageSize,
  );
  const { data: detail, isLoading: detailLoading } =
    useFuzzyProfileTemplateDetail(
      editingId,
      drawerOpen && mode === 'edit' && !!editingId,
    );

  const createMut = useCreateFuzzyProfileTemplate();
  const updateMut = useUpdateFuzzyProfileTemplate();
  const deleteMut = useDeleteFuzzyProfileTemplate();

  useEffect(() => {
    if (!drawerOpen || mode !== 'edit' || !detail) return;
    form.setFieldsValue({
      ...detail,
      noiseQuietMaxDb:
        detail.noiseQuietMaxDb ??
        detail.stressComfortableMax ??
        detail.densitySparseMax ??
        undefined,
      noiseLoudMinDb:
        detail.noiseLoudMinDb ??
        detail.stressHighMin ??
        detail.densityCrowdedMin ??
        undefined,
      defaultDecibelWhenNull:
        detail.defaultDecibelWhenNull ??
        detail.defaultDensityRatioWhenNull ??
        undefined,
      isActive: detail.isActive,
    });
  }, [drawerOpen, mode, detail, form]);

  const openCreate = () => {
    setMode('create');
    setEditingId(undefined);
    form.resetFields();
    form.setFieldsValue(DEFAULT_CREATE_VALUES);
    setDrawerOpen(true);
  };

  const openEdit = (id: string) => {
    setMode('edit');
    setEditingId(id);
    form.resetFields();
    setDrawerOpen(true);
  };

  const closeDrawer = () => {
    setDrawerOpen(false);
    setEditingId(undefined);
  };

  const buildPayload = (values: Record<string, unknown>) => ({
    templateKey: String(values.templateKey ?? '').trim(),
    displayName: String(values.displayName ?? '').trim(),
    profileDescription: String(values.profileDescription ?? '').trim() || null,
    chillMoodDescription:
      String(values.chillMoodDescription ?? '').trim() || null,
    focusMoodDescription:
      String(values.focusMoodDescription ?? '').trim() || null,
    energeticMoodDescription:
      String(values.energeticMoodDescription ?? '').trim() || null,
    sortOrder: Number(values.sortOrder),
    chillBpmMin: Number(values.chillBpmMin),
    chillBpmMax: Number(values.chillBpmMax),
    focusBpmMin: Number(values.focusBpmMin),
    focusBpmMax: Number(values.focusBpmMax),
    energeticBpmMin: Number(values.energeticBpmMin),
    energeticBpmMax: Number(values.energeticBpmMax),
    pressureLowMax: Number(values.pressureLowMax),
    pressureCriticalMin: Number(values.pressureCriticalMin),
    noiseQuietMaxDb: Number(values.noiseQuietMaxDb),
    noiseLoudMinDb: Number(values.noiseLoudMinDb),
    spaceCapacity: Number(values.spaceCapacity),
    defaultDecibelWhenNull: Number(values.defaultDecibelWhenNull),
  });

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields();
      const body = buildPayload(values);
      if (mode === 'create') {
        const res = await createMut.mutateAsync(body);
        if (res.data.isSuccess) {
          message.success(res.data.message || 'Created');
          closeDrawer();
          refetch();
        } else {
          message.error(res.data.message || 'Create failed');
        }
      } else if (editingId) {
        const res = await updateMut.mutateAsync({
          id: editingId,
          body: { ...body, isActive: !!values.isActive },
        });
        if (res.data.isSuccess) {
          message.success(res.data.message || 'Updated');
          closeDrawer();
          refetch();
        } else {
          message.error(res.data.message || 'Update failed');
        }
      }
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      const apiMsg = err?.response?.data?.message;
      if (apiMsg) message.error(apiMsg);
    }
  };

  const columns = [
    {
      title: 'Display name',
      dataIndex: 'displayName',
      key: 'displayName',
    },
    {
      title: 'Key',
      dataIndex: 'templateKey',
      key: 'templateKey',
    },
    {
      title: 'Description',
      dataIndex: 'profileDescription',
      key: 'profileDescription',
      render: (value: string | null | undefined) =>
        value?.trim() ? (
          value
        ) : (
          <Typography.Text type='secondary'>No description</Typography.Text>
        ),
    },
    {
      title: 'Sort',
      dataIndex: 'sortOrder',
      key: 'sortOrder',
      width: 80,
    },
    {
      title: 'Active',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      render: (active: boolean) =>
        active ? <Tag color='green'>Yes</Tag> : <Tag>No</Tag>,
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 160,
      render: (_: unknown, record: { id: string }) => (
        <Space>
          <Button
            type='link'
            size='small'
            onClick={() => openEdit(record.id)}
          >
            Edit
          </Button>
          <Popconfirm
            title='Deactivate this template?'
            description='Soft delete: hidden from pickers; existing brand keys may still resolve.'
            onConfirm={async () => {
              try {
                const res = await deleteMut.mutateAsync(record.id);
                if (res.data.isSuccess) {
                  message.success(res.data.message || 'Deleted');
                  refetch();
                } else {
                  message.error(res.data.message || 'Delete failed');
                }
              } catch (e: unknown) {
                const err = e as { response?: { data?: { message?: string } } };
                const apiMsg = err?.response?.data?.message;
                if (apiMsg) message.error(apiMsg);
              }
            }}
            okText='Yes'
            cancelText='No'
          >
            <Button
              type='link'
              danger
              size='small'
            >
              Delete
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const breadcrumbs = [
    {
      title: 'Dashboard',
      onClick: () => navigate('/admin/dashboard'),
      className: 'cursor-pointer',
    },
    { title: 'AI fuzzy management' },
  ];

  const saving = createMut.isPending || updateMut.isPending;

  return (
    <div>
      <PageHeader
        title='AI fuzzy management'
        breadcrumbs={breadcrumbs}
        extra={
          <Button
            type='primary'
            icon={<PlusOutlined />}
            onClick={openCreate}
          >
            New template
          </Button>
        }
      />

      <Typography.Paragraph type='secondary'>
        Default fuzzy profiles brands inherit when choosing a template. Brands
        can still override thresholds in brand settings.
      </Typography.Paragraph>

      <Table
        rowKey='id'
        loading={isLoading}
        columns={columns}
        dataSource={data?.items ?? []}
        pagination={{
          current: data?.currentPage ?? page,
          pageSize: data?.pageSize ?? pageSize,
          total: data?.totalItems ?? 0,
          showSizeChanger: true,
          pageSizeOptions: PAGINATION_SIZES,
          showTotal: (t) => `Total ${t} templates`,
          onChange: (p, ps) => {
            setPage(p);
            setPageSize(ps);
          },
        }}
      />

      <Drawer
        title={mode === 'create' ? 'Create template' : 'Edit template'}
        width={720}
        open={drawerOpen}
        onClose={closeDrawer}
        destroyOnClose
        extra={
          <Space>
            <Button onClick={closeDrawer}>Cancel</Button>
            <Button
              type='primary'
              loading={saving}
              onClick={handleSubmit}
            >
              Save
            </Button>
          </Space>
        }
      >
        <Form
          form={form}
          layout='vertical'
          disabled={mode === 'edit' && detailLoading}
        >
          <Form.Item
            name='templateKey'
            label='Template key'
            rules={[
              { required: true, message: 'Required' },
              { max: 64, message: 'Max 64 characters' },
            ]}
            extra='Stable identifier stored on brands (e.g. LuxuryRestaurant). Changing the key does not update existing brands.'
          >
            <Input placeholder='Unique key' />
          </Form.Item>
          <Form.Item
            name='displayName'
            label='Display name'
            rules={[{ required: true, message: 'Required' }]}
          >
            <Input placeholder='Shown in dropdowns' />
          </Form.Item>
          <Form.Item
            name='profileDescription'
            label='Profile description'
            rules={[{ max: 1000, message: 'Max 1000 characters' }]}
            extra='Explain the business intent of this template so non-technical users understand when to use it.'
          >
            <Input.TextArea
              rows={3}
              showCount
              maxLength={1000}
              placeholder='Example: Balanced coffee-shop profile for calm mornings, focused work sessions, and gentle peak-hour acceleration.'
            />
          </Form.Item>
          <Form.Item
            name='sortOrder'
            label='Sort order'
            rules={[{ required: true, message: 'Required' }]}
          >
            <InputNumber
              className='w-full!'
              min={0}
            />
          </Form.Item>
          {mode === 'edit' && (
            <Form.Item
              name='isActive'
              label='Active'
              valuePropName='checked'
            >
              <Switch />
            </Form.Item>
          )}

          <Typography.Title level={5}>BPM & thresholds</Typography.Title>
          <div style={gridStyle}>
            <Form.Item
              name='chillMoodDescription'
              label='Chill mood description'
              rules={[{ max: 1000, message: 'Max 1000 characters' }]}
            >
              <Input.TextArea
                rows={3}
                showCount
                maxLength={1000}
                placeholder='Describe the sonic character and purpose of chill mode.'
              />
            </Form.Item>
            <Form.Item
              name='focusMoodDescription'
              label='Focus mood description'
              rules={[{ max: 1000, message: 'Max 1000 characters' }]}
            >
              <Input.TextArea
                rows={3}
                showCount
                maxLength={1000}
                placeholder='Describe how focus mode should feel in-store.'
              />
            </Form.Item>
          </div>
          <Form.Item
            name='energeticMoodDescription'
            label='Energetic mood description'
            rules={[{ max: 1000, message: 'Max 1000 characters' }]}
          >
            <Input.TextArea
              rows={3}
              showCount
              maxLength={1000}
              placeholder='Describe energetic mode for rush/promotions while preserving brand identity.'
            />
          </Form.Item>
          <div style={gridStyle}>
            <Form.Item
              name='chillBpmMin'
              label='Chill BPM min'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='chillBpmMax'
              label='Chill BPM max'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='focusBpmMin'
              label='Focus BPM min'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='focusBpmMax'
              label='Focus BPM max'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='energeticBpmMin'
              label='Energetic BPM min'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='energeticBpmMax'
              label='Energetic BPM max'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={1}
              />
            </Form.Item>
            <Form.Item
              name='pressureLowMax'
              label='People count: Low level max'
              tooltip='If people count is below this value, CAMS treats crowd pressure as Low.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
              />
            </Form.Item>
            <Form.Item
              name='pressureCriticalMin'
              label='People count: Energetic trigger min'
              tooltip='If people count is above this value, CAMS treats crowd pressure as Critical and prioritizes Energetic.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
              />
            </Form.Item>
            <Form.Item
              name='noiseQuietMaxDb'
              label='Noise threshold: Quiet max (dB)'
              tooltip='If decibel is below this value, CAMS classifies ambient noise as Quiet.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
                step={0.01}
              />
            </Form.Item>
            <Form.Item
              name='noiseLoudMinDb'
              label='Noise threshold: Loud min (dB)'
              tooltip='If decibel is above this value, CAMS classifies ambient noise as Loud.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
                step={0.01}
              />
            </Form.Item>
            <Form.Item
              name='spaceCapacity'
              label='Space capacity (reference)'
              tooltip='Reference capacity for this template profile.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
              />
            </Form.Item>
            <Form.Item
              name='defaultDecibelWhenNull'
              label='Fallback decibel when missing (dB)'
              tooltip='Used only when telemetry payload does not include decibel.'
              rules={[{ required: true }]}
            >
              <InputNumber
                className='w-full!'
                min={0}
                step={0.01}
              />
            </Form.Item>
          </div>
        </Form>
      </Drawer>
    </div>
  );
};
