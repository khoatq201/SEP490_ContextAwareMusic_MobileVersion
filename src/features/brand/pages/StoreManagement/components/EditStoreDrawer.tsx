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
  Spin,
  Collapse,
} from 'antd';

/**
 * Hooks
 */
import { useBrand } from '@/features/admin/hooks';
import {
  useStore,
  useUpdateStore,
  useCreateStoreFuzzyOverrideProfile,
} from '@/features/brand/hooks';

/**
 * Providers
 */
import { useAuth } from '@/providers';

/**
 * Types
 */
import type {
  StoreRequest,
  StoreFuzzyOverrideProfileRequest,
} from '@/features/brand/types';

/**
 * Utils
 */
import { pickStoreFuzzyOverrideBody } from '@/features/brand/utils/storeFuzzyOverride';
import { HCMC_DISTRICTS, VIETNAM_CITIES } from '@/shared/constants';
import { STORE_FUZZY_OVERRIDE_LEVEL_OPTIONS } from '@/features/brand/constants/storeMusicPolicy';

/**
 * Validations
 */
import { updateStoreValidation } from '@/features/brand/validations';

/**
 * Components
 */
import { MapPicker } from '@/shared/components';

import { StoreFuzzyOverrideFields } from './StoreFuzzyOverrideFields';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;
const { TextArea } = Input;

type EditStoreDrawerFormValues = StoreRequest & {
  fuzzy?: Partial<StoreFuzzyOverrideProfileRequest>;
};

type EditStoreDrawerProps = {
  open: boolean;
  storeId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const EditStoreDrawer = ({
  open,
  storeId,
  onClose,
  onSuccess,
}: EditStoreDrawerProps) => {
  const [form] = Form.useForm<EditStoreDrawerFormValues>();
  const {
    data: store,
    isLoading,
    refetch,
  } = useStore(storeId || undefined, open);
  const updateStore = useUpdateStore();
  const createFuzzyProfile = useCreateStoreFuzzyOverrideProfile();
  const { user } = useAuth();
  const {
    data: brandPolicy,
    isLoading: brandPolicyLoading,
    isError: brandPolicyError,
  } = useBrand(user?.brandId ?? undefined, open && !!user?.brandId);

  const canStoreFuzzyOverride = !!brandPolicy && !brandPolicyError;
  const selectedStorePolicyLevel = Form.useWatch('fuzzyOverrideLevel', form);

  // Populate form when store data is loaded
  useEffect(() => {
    if (store && open) {
      form.setFieldsValue({
        name: store.name,
        contactNumber: store.contactNumber || undefined,
        address: store.address || undefined,
        city: store.city || undefined,
        district: store.district || undefined,
        latitude: store.latitude || undefined,
        longitude: store.longitude || undefined,
        mapUrl: store.mapUrl || undefined,
        areaSquareMeters: store.areaSquareMeters || undefined,
        maxCapacity: store.maxCapacity || undefined,
        fuzzyOverrideLevel: store.fuzzyOverrideLevel ?? 3,
        fuzzy: {
          name: store.activeFuzzyProfileName ?? undefined,
          chillBpmMin: store.chillBpmMin ?? undefined,
          chillBpmMax: store.chillBpmMax ?? undefined,
          focusBpmMin: store.focusBpmMin ?? undefined,
          focusBpmMax: store.focusBpmMax ?? undefined,
          energeticBpmMin: store.energeticBpmMin ?? undefined,
          energeticBpmMax: store.energeticBpmMax ?? undefined,
          pressureLowMax: store.pressureLowMax ?? undefined,
          pressureCriticalMin: store.pressureCriticalMin ?? undefined,
          noiseQuietMaxDb:
            store.noiseQuietMaxDb ??
            store.stressComfortableMax ??
            store.densitySparseMax ??
            undefined,
          noiseLoudMinDb:
            store.noiseLoudMinDb ??
            store.stressHighMin ??
            store.densityCrowdedMin ??
            undefined,
          spaceCapacity: store.spaceCapacity ?? undefined,
          defaultDecibelWhenNull:
            store.defaultDecibelWhenNull ??
            store.defaultDensityRatioWhenNull ??
            undefined,
          chillMoodCandidates: store.chillMoodCandidates?.length
            ? store.chillMoodCandidates
            : undefined,
          focusMoodCandidates: store.focusMoodCandidates?.length
            ? store.focusMoodCandidates
            : undefined,
          energeticMoodCandidates: store.energeticMoodCandidates?.length
            ? store.energeticMoodCandidates
            : undefined,
          allowedPlaylistIds: store.allowedPlaylistIds?.length
            ? store.allowedPlaylistIds
            : undefined,
        },
      });
    }
  }, [store, open, form]);

  useEffect(() => {
    if (open && storeId) {
      void refetch();
    }
  }, [open, storeId, refetch]);

  const handleSubmit = async (values: EditStoreDrawerFormValues) => {
    if (!storeId) return;

    const { fuzzy, ...storePayload } = values;
    void fuzzy;

    updateStore.mutate(
      { id: storeId, data: storePayload },
      {
        onSuccess: () => {
          handleCancel();
          onSuccess();
        },
      },
    );
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

  const handleCreateFuzzyOverride = () => {
    if (!storeId) return;
    const fuzzy = form.getFieldValue('fuzzy') as
      | Partial<StoreFuzzyOverrideProfileRequest>
      | undefined;
    const body = pickStoreFuzzyOverrideBody(fuzzy);
    createFuzzyProfile.mutate(
      { storeId, body },
      {
        onSuccess: () => {
          void refetch();
        },
      },
    );
  };

  return (
    <Drawer
      closeIcon={null}
      title='Edit Store'
      placement='right'
      width={DRAWER_WIDTHS.medium}
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
            loading={updateStore.isPending}
            disabled={isLoading}
          >
            Update Store
          </Button>
        </Flex>
      }
    >
      <Form<EditStoreDrawerFormValues>
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
        {isLoading ? (
          <div className='flex h-96 items-center justify-center'>
            <Spin size='large' />
          </div>
        ) : (
          <>
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
                rules={updateStoreValidation.name}
              >
                <Input placeholder='e.g., DeerCoffee Điện Biên Phủ' />
              </Form.Item>

              <Form.Item
                label='Contact Number'
                name='contactNumber'
                rules={updateStoreValidation.contactNumber}
              >
                <Input placeholder='+84283456789 or 0283456789' />
              </Form.Item>

              <Form.Item
                label='Store policy level (CAMS)'
                name='fuzzyOverrideLevel'
                rules={updateStoreValidation.fuzzyOverrideLevel}
                tooltip='Brand manager can reassign this policy for the store.'
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

            {/* Location Section - Simplified */}
            <div style={{ marginBottom: 24 }}>
              <Title
                level={5}
                style={{ marginBottom: 16 }}
              >
                Location
              </Title>

              {/* Address Field */}
              <Form.Item
                label='Address'
                name='address'
                rules={updateStoreValidation.address}
                extra='You can search on the map below to auto-fill this field'
              >
                <TextArea
                  rows={2}
                  placeholder='e.g., 789 Điện Biên Phủ, Phường 25, Bình Thạnh'
                />
              </Form.Item>

              {/* City & District */}
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label='City'
                    name='city'
                    rules={updateStoreValidation.city}
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
                    rules={updateStoreValidation.district}
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

              {/* Map Picker */}
              <Form.Item
                label='Pinpoint Store Location on Map'
                extra='Click on the map or search for the address to update coordinates'
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

              {/* Hidden fields for lat/lng/mapUrl */}
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
                    rules={updateStoreValidation.areaSquareMeters}
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
                    rules={updateStoreValidation.maxCapacity}
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

            <Collapse
              style={{ marginTop: 8 }}
              defaultActiveKey={['fuzzy']}
              items={[
                {
                  key: 'fuzzy',
                  label: 'Store music profile (CAMS)',
                  children: (
                    <>
                      {brandPolicyLoading ? (
                        <Flex
                          justify='center'
                          style={{ padding: 16 }}
                        >
                          <Spin />
                        </Flex>
                      ) : brandPolicyError ? (
                        <Alert
                          type='error'
                          showIcon
                          message='Could not load brand music policy'
                          description='Try again later or contact an administrator.'
                        />
                      ) : canStoreFuzzyOverride ? (
                        <>
                          <Typography.Paragraph type='secondary'>
                            Creates and activates a profile via{' '}
                            <Typography.Text code>
                              POST /api/stores/:id/fuzzy-profiles
                            </Typography.Text>
                            . Runtime prefers this active store profile first
                            and falls back to the brand default profile when
                            none is active. This does not replace Update Store —
                            use the button when you are ready.
                          </Typography.Paragraph>
                          <StoreFuzzyOverrideFields
                            storeIdForPlaylists={storeId ?? undefined}
                            storeOverrideLevel={selectedStorePolicyLevel}
                          />
                          <Button
                            size='large'
                            type='primary'
                            onClick={handleCreateFuzzyOverride}
                            loading={createFuzzyProfile.isPending}
                          >
                            Create &amp; activate override profile
                          </Button>
                        </>
                      ) : (
                        <Alert
                          type='warning'
                          showIcon
                          message='Brand music policy is not configured'
                          description='Configure the brand default template in Admin before creating a store profile.'
                        />
                      )}
                    </>
                  ),
                },
              ]}
            />
          </>
        )}
      </Form>
    </Drawer>
  );
};
