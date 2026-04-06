import { useEffect } from 'react';
import {
  Alert,
  Button,
  Drawer,
  Form,
  Input,
  Radio,
  Select,
  Row,
  Col,
  Typography,
  Flex,
  InputNumber,
  Checkbox,
  message,
  Spin,
} from 'antd';

/**
 * Hooks
 */
import { useBrand } from '@/features/admin/hooks';
import { useCreateStore } from '@/features/brand/hooks';

/**
 * Providers
 */
import { useAuth } from '@/providers';

/**
 * Components
 */
import { MapPicker } from '@/shared/components';

import { StoreFuzzyOverrideFields } from './StoreFuzzyOverrideFields';

/**
 * Types
 */
import type {
  StoreRequest,
  StoreFuzzyOverrideProfileRequest,
} from '@/features/brand/types';

/**
 * Services
 */
import { storeService } from '@/features/brand/services';

/**
 * Utils
 */
import { pickStoreFuzzyOverrideBody } from '@/features/brand/utils/storeFuzzyOverride';
import { VIETNAM_CITIES, HCMC_DISTRICTS } from '@/shared/constants';
import { STORE_FUZZY_OVERRIDE_LEVEL_OPTIONS } from '@/features/brand/constants/storeMusicPolicy';

/**
 * Validations
 */
import { createStoreValidation } from '@/features/brand/validations';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;
const { TextArea } = Input;

const formatRange = (min?: number | null, max?: number | null) => {
  if (min == null && max == null) return 'Not configured';
  if (min != null && max != null) return `${min} - ${max}`;
  return `${min ?? '-'} - ${max ?? '-'}`;
};

type CreateStoreDrawerFormValues = StoreRequest & {
  applyFuzzyAfterCreate?: boolean;
  fuzzy?: Partial<StoreFuzzyOverrideProfileRequest>;
};

type CreateStoreDrawerProps = {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
};

export const CreateStoreDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateStoreDrawerProps) => {
  const [form] = Form.useForm<CreateStoreDrawerFormValues>();
  const createStore = useCreateStore();
  const { user } = useAuth();
  const brandId = user?.brandId ?? undefined;
  const {
    data: brand,
    isLoading: brandPolicyLoading,
    isError: brandPolicyError,
  } = useBrand(brandId, open && !!brandId);

  const canStoreFuzzyOverride = !!brand && !brandPolicyError;
  const selectedStorePolicyLevel = Form.useWatch('fuzzyOverrideLevel', form);

  useEffect(() => {
    if (!open) return;
    if (canStoreFuzzyOverride) {
      form.setFieldValue('applyFuzzyAfterCreate', true);
    }
  }, [open, canStoreFuzzyOverride, form]);

  const handleSubmit = async (values: CreateStoreDrawerFormValues) => {
    const { applyFuzzyAfterCreate, fuzzy, ...storeValues } = values;

    try {
      await createStore.mutateAsync(storeValues);
    } catch {
      return;
    }

    if (
      applyFuzzyAfterCreate &&
      canStoreFuzzyOverride &&
      storeValues.name?.trim()
    ) {
      const body = pickStoreFuzzyOverrideBody(fuzzy);
      try {
        const listRes = await storeService.getList({
          search: storeValues.name.trim(),
          page: 1,
          pageSize: 25,
          sortBy: 'createdat',
          isAscending: false,
        });
        const exact = listRes.data?.items?.find(
          (s) => s.name.trim() === storeValues.name!.trim(),
        );
        if (exact) {
          await storeService.createFuzzyOverrideProfile(exact.id, body);
          message.success('Fuzzy override profile created for the new store.');
        } else {
          message.warning(
            'Store was created; fuzzy override was not applied automatically. Use Edit store.',
          );
        }
      } catch {
        message.error(
          'Store was created but fuzzy override failed. Try Edit store.',
        );
      }
    }

    handleCancel();
    onSuccess();
  };

  const handleCancel = () => {
    form.resetFields();
    onClose();
  };

  const handleMapLocationChange = (location: { lat: number; lng: number }) => {
    form.setFieldsValue({
      latitude: location.lat,
      longitude: location.lng,
      mapUrl: `https://maps.google.com/?q=${location.lat},${location.lng}`,
    });
  };

  const handleAddressChange = (address: string) => {
    form.setFieldsValue({
      address: address,
    });
  };

  return (
    <Drawer
      closeIcon={null}
      title='Add New Store'
      placement='right'
      width={DRAWER_WIDTHS.large}
      forceRender
      open={open}
      onClose={handleCancel}
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
            loading={createStore.isPending}
          >
            Create Store
          </Button>
        </Flex>
      }
    >
      <Form
        size='large'
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
        autoComplete='off'
        initialValues={{
          timeZone: 'Asia/Ho_Chi_Minh',
          fuzzyOverrideLevel: 3,
          applyFuzzyAfterCreate: false,
          fuzzy: {},
        }}
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
            label='Store Name'
            name='name'
            rules={createStoreValidation.name}
          >
            <Input placeholder='e.g., DeerCoffee Điện Biên Phủ' />
          </Form.Item>

          <Form.Item
            label='Contact Number'
            name='contactNumber'
            rules={createStoreValidation.contactNumber}
          >
            <Input placeholder='+84283456789 or 0283456789' />
          </Form.Item>

          <Form.Item
            label='Store policy level (CAMS)'
            name='fuzzyOverrideLevel'
            rules={createStoreValidation.fuzzyOverrideLevel}
            tooltip='Tagged at store creation; can be reassigned later in Edit store.'
          >
            <Radio.Group>
              {STORE_FUZZY_OVERRIDE_LEVEL_OPTIONS.map((opt) => (
                <Radio
                  key={opt.value}
                  value={opt.value}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    marginBottom: 8,
                  }}
                >
                  <span>
                    <div>{opt.label}</div>
                    <Typography.Text
                      type='secondary'
                      style={{ fontSize: 12, fontWeight: 'normal' }}
                    >
                      {opt.description}
                    </Typography.Text>
                  </span>
                </Radio>
              ))}
            </Radio.Group>
          </Form.Item>
        </div>

        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 12 }}
          >
            Store music profile (CAMS)
          </Title>

          {!brandId ? (
            <Alert
              type='warning'
              showIcon
              message='Brand context is missing'
              description='Cannot load music policy. Create the store, then configure a fuzzy override from Edit store if needed.'
            />
          ) : brandPolicyLoading ? (
            <Flex
              vertical
              align='center'
              justify='center'
              gap='middle'
              style={{ padding: 24 }}
            >
              <Spin size='large' />
              <Typography.Text type='secondary'>
                Loading brand music policy…
              </Typography.Text>
            </Flex>
          ) : brandPolicyError ? (
            <Alert
              type='error'
              showIcon
              message='Could not load brand music policy'
              description='Create the store, then configure a fuzzy override from Edit store if your role allows it.'
            />
          ) : canStoreFuzzyOverride ? (
            <>
              <Alert
                type='info'
                showIcon
                style={{ marginBottom: 12 }}
                message='Current brand policy snapshot'
                description={
                  <div>
                    <div>
                      Template:{' '}
                      {brand?.fuzzyProfileTemplate ?? 'Not configured'}
                    </div>
                    <div>
                      Default BPM bands: Chill{' '}
                      {formatRange(brand?.chillBpmMin, brand?.chillBpmMax)} |
                      Focus{' '}
                      {formatRange(brand?.focusBpmMin, brand?.focusBpmMax)} |
                      Energetic{' '}
                      {formatRange(
                        brand?.energeticBpmMin,
                        brand?.energeticBpmMax,
                      )}
                    </div>
                  </div>
                }
              />
              <Typography.Paragraph type='secondary'>
                Optional: create an active store fuzzy profile right after the
                store is saved (
                <Typography.Text code>
                  POST /api/stores/:id/fuzzy-profiles
                </Typography.Text>
                ). Runtime uses the active store profile first and falls back to
                the brand default profile when the store has no active profile.
                The new store is matched by exact name.
              </Typography.Paragraph>
              <Form.Item
                name='applyFuzzyAfterCreate'
                valuePropName='checked'
              >
                <Checkbox>
                  Create &amp; activate store override profile when the store is
                  created
                </Checkbox>
              </Form.Item>
              <Form.Item
                noStyle
                shouldUpdate={(prev, cur) =>
                  prev.applyFuzzyAfterCreate !== cur.applyFuzzyAfterCreate
                }
              >
                {({ getFieldValue }) =>
                  getFieldValue('applyFuzzyAfterCreate') ? (
                    <StoreFuzzyOverrideFields
                      storeOverrideLevel={selectedStorePolicyLevel}
                      isCreateFlow
                      defaultAdvancedExpanded
                    />
                  ) : null
                }
              </Form.Item>
            </>
          ) : (
            <Alert
              type='warning'
              showIcon
              message='Brand music policy not found or incomplete'
              description='Create the store first. Configure a brand default template in Admin, then add a store profile from Edit store.'
            />
          )}
        </div>

        {/* Location Section */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Location
          </Title>

          <Form.Item
            label='Address'
            name='address'
            rules={createStoreValidation.address}
            extra='You can search on the map below to auto-fill this field'
          >
            <TextArea
              rows={2}
              placeholder='e.g., 789 Điện Biên Phủ, Phường 25, Bình Thạnh'
            />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label='City'
                name='city'
                rules={createStoreValidation.city}
              >
                <Select
                  placeholder='Select city'
                  options={VIETNAM_CITIES}
                  showSearch
                  optionFilterProp='label'
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='District'
                name='district'
                rules={createStoreValidation.district}
              >
                <Select
                  placeholder='Select district'
                  options={HCMC_DISTRICTS}
                  showSearch
                  optionFilterProp='label'
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label='Pinpoint Store Location on Map'
            extra='Click on the map or search for the address to set coordinates'
          >
            <Form.Item
              noStyle
              shouldUpdate
            >
              {({ getFieldValue }) => {
                const lat = getFieldValue('latitude');
                const lng = getFieldValue('longitude');
                return (
                  <MapPicker
                    value={lat && lng ? { lat, lng } : null}
                    onChange={handleMapLocationChange}
                    onAddressChange={handleAddressChange}
                    height={400}
                  />
                );
              }}
            </Form.Item>
          </Form.Item>

          {/* Hidden fields for coordinates */}
          <Form.Item
            name='latitude'
            hidden
          >
            <Input />
          </Form.Item>
          <Form.Item
            name='longitude'
            hidden
          >
            <Input />
          </Form.Item>
          <Form.Item
            name='mapUrl'
            hidden
          >
            <Input />
          </Form.Item>
        </div>

        {/* Store Details */}
        <div>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Store Details
          </Title>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label='Area (m²)'
                name='areaSquareMeters'
                rules={createStoreValidation.areaSquareMeters}
              >
                <InputNumber
                  className='w-full!'
                  placeholder='e.g., 95.0'
                  min={0.01}
                  step={0.1}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='Max Capacity'
                name='maxCapacity'
                rules={createStoreValidation.maxCapacity}
              >
                <InputNumber
                  className='w-full!'
                  placeholder='e.g., 60'
                  min={1}
                />
              </Form.Item>
            </Col>
          </Row>
        </div>
      </Form>
    </Drawer>
  );
};
