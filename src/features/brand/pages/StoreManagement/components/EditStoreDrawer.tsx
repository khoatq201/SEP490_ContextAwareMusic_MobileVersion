import { useEffect } from 'react';
import {
  Button,
  Drawer,
  Form,
  Input,
  Select,
  Row,
  Col,
  Typography,
  Flex,
  InputNumber,
  Spin,
} from 'antd';

/**
 * Hooks
 */
import { useStore, useUpdateStore } from '@/features/brand/hooks';

/**
 * Types
 */
import type { StoreRequest } from '@/features/brand/types';

/**
 * Constants
 */
import { HCMC_DISTRICTS, VIETNAM_CITIES } from '@/shared/constants';

/**
 * Validations
 */
import { updateStoreValidation } from '@/features/brand/validations';

/**
 * Components
 */
import { MapPicker } from '@/shared/components';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;
const { TextArea } = Input;

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
  const [form] = Form.useForm<StoreRequest>();
  const { data: store, isLoading } = useStore(storeId || undefined, open);
  const updateStore = useUpdateStore();

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
      });
    }
  }, [store, open, form]);

  const handleSubmit = async (values: StoreRequest) => {
    if (!storeId) return;

    updateStore.mutate(
      { id: storeId, data: values },
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

  return (
    <Drawer
      closeIcon={null}
      title='Edit Store'
      placement='right'
      width={DRAWER_WIDTHS.medium}
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
      {isLoading ? (
        <div className='flex h-96 items-center justify-center'>
          <Spin size='large' />
        </div>
      ) : (
        <Form
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
        </Form>
      )}
    </Drawer>
  );
};
