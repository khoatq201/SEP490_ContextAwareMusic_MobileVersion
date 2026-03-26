import { useEffect } from 'react';
import {
  Button,
  Drawer,
  Form,
  Input,
  Select,
  InputNumber,
  Flex,
  Spin,
  Row,
  Col,
} from 'antd';

/**
 * Hooks
 */
import { useSpace, useUpdateSpace } from '@/shared/modules/spaces/hooks';

/**
 * Types
 */
import type { UpdateSpaceRequest } from '@/shared/modules/spaces/types';

/**
 * Constants
 */
import { SPACE_TYPE_OPTIONS } from '@/features/store/constants';

/**
 * Validations
 */
import { updateSpaceValidation } from '@/shared/modules/spaces/validations';

/**
 * Utils
 */
import { nullToUndefined } from '@/shared/utils/formHelpers';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

type EditSpaceDrawerProps = {
  open: boolean;
  spaceId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const EditSpaceDrawer = ({
  open,
  spaceId,
  onClose,
  onSuccess,
}: EditSpaceDrawerProps) => {
  const [form] = Form.useForm<UpdateSpaceRequest>();
  const { data: space, isLoading } = useSpace(spaceId || undefined, open);
  const updateSpace = useUpdateSpace();

  // Pre-fill form when space data is loaded
  useEffect(() => {
    if (space && open) {
      form.setFieldsValue({
        name: space.name,
        type: space.type,
        description: nullToUndefined(space.description),
        maxOccupancy: nullToUndefined(space.maxOccupancy),
        criticalQueueThreshold: nullToUndefined(space.criticalQueueThreshold),
        cameraId: nullToUndefined(space.cameraId),
        roiCoordinates: nullToUndefined(space.roiCoordinates),
        wiFiSensorId: nullToUndefined(space.wiFiSensorId),
      });
    }
  }, [space, open, form]);

  const handleSubmit = async (values: UpdateSpaceRequest) => {
    if (!spaceId) return;

    updateSpace.mutate(
      { id: spaceId, data: values },
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

  return (
    <Drawer
      closeIcon={null}
      title='Edit Space'
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
            loading={updateSpace.isPending}
            disabled={isLoading}
          >
            Update Space
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
            rules={updateSpaceValidation.name}
          >
            <Input placeholder='e.g., Main Counter, VIP Hall' />
          </Form.Item>

          <Form.Item
            label='Space Type'
            name='type'
          >
            <Select
              placeholder='Select space type'
              options={SPACE_TYPE_OPTIONS}
            />
          </Form.Item>

          <Form.Item
            label='Description'
            name='description'
            rules={updateSpaceValidation.description}
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
                rules={updateSpaceValidation.maxOccupancy}
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
                rules={updateSpaceValidation.criticalQueueThreshold}
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
      )}
    </Drawer>
  );
};
