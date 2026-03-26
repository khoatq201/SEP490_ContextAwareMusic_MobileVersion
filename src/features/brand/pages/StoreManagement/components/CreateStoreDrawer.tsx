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
} from 'antd';

/**
 * Hooks
 */
import { useCreateStore } from '@/features/brand/hooks';

/**
 * Components
 */
import { MapPicker } from '@/shared/components';

/**
 * Types
 */
import type { StoreRequest } from '@/features/brand/types';

/**
 * Constants
 */
import { VIETNAM_CITIES, HCMC_DISTRICTS } from '@/shared/constants';

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
  const [form] = Form.useForm<StoreRequest>();
  const createStore = useCreateStore();

  const handleSubmit = async (values: StoreRequest) => {
    createStore.mutate(values, {
      onSuccess: () => {
        handleCancel();
        onSuccess();
      },
    });
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
