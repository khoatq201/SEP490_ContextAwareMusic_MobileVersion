import {
  Button,
  Drawer,
  Form,
  Input,
  Select,
  InputNumber,
  Flex,
  Row,
  Col,
} from 'antd';

/**
 * Hooks
 */
import { useCreateSpace } from '@/shared/modules/spaces/hooks';

/**
 * Types
 */
import type { CreateSpaceRequest } from '@/shared/modules/spaces/types';

/**
 * Constants
 */
import { SPACE_TYPE_OPTIONS } from '@/features/store/constants';

/**
 * Validations
 */
import { createSpaceValidation } from '@/shared/modules/spaces/validations';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

type CreateSpaceDrawerProps = {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
};

export const CreateSpaceDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateSpaceDrawerProps) => {
  const [form] = Form.useForm<CreateSpaceRequest>();
  const createSpace = useCreateSpace();

  const handleSubmit = async (values: CreateSpaceRequest) => {
    createSpace.mutate(values, {
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

  return (
    <Drawer
      closeIcon={null}
      title='Create New Space'
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
            loading={createSpace.isPending}
          >
            Create Space
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
        styles={{
          label: {
            height: 22,
          },
        }}
      >
        <Form.Item
          label='Space Name'
          name='name'
          rules={createSpaceValidation.name}
        >
          <Input placeholder='e.g., Main Counter, VIP Hall' />
        </Form.Item>

        <Form.Item
          label='Space Type'
          name='type'
          rules={createSpaceValidation.type}
        >
          <Select
            placeholder='Select space type'
            options={SPACE_TYPE_OPTIONS}
          />
        </Form.Item>

        <Form.Item
          label='Description'
          name='description'
          rules={createSpaceValidation.description}
        >
          <Input.TextArea
            rows={3}
            placeholder='Brief description of this space...'
          />
        </Form.Item>

        <Row gutter={16}>
          <Col span={12}>
            <Form.Item
              label='Max Occupancy'
              name='maxOccupancy'
              rules={createSpaceValidation.maxOccupancy}
            >
              <InputNumber
                min={1}
                style={{ width: '100%' }}
                placeholder='e.g., 50'
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item
              label='Critical Queue Threshold'
              name='criticalQueueThreshold'
              rules={createSpaceValidation.criticalQueueThreshold}
            >
              <InputNumber
                min={1}
                style={{ width: '100%' }}
                placeholder='e.g., 10'
              />
            </Form.Item>
          </Col>
        </Row>
      </Form>
    </Drawer>
  );
};
