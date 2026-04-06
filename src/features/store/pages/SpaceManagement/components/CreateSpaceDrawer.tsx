import {
  App,
  Alert,
  Button,
  Checkbox,
  Drawer,
  Form,
  Input,
  Select,
  InputNumber,
  Flex,
  Row,
  Col,
  Divider,
  Typography,
} from 'antd';

/**
 * Hooks
 */
import { useCreateSpace } from '@/shared/modules/spaces/hooks';
import { spaceService } from '@/shared/modules/spaces/services';

/**
 * Types
 */
import type {
  CreateSpaceRequest,
  SpaceFuzzyOverrideProfileRequest,
} from '@/shared/modules/spaces/types';

/**
 * Constants
 */
import { SPACE_TYPE_OPTIONS } from '@/features/store/constants';

/**
 * Validations
 */
import { createSpaceValidation } from '@/shared/modules/spaces/validations';
import { SpaceFuzzyOverrideFields } from './SpaceFuzzyOverrideFields';
import { pickSpaceFuzzyOverrideBody } from './spaceFuzzyOverrideUtils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

type CreateSpaceDrawerProps = {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
};

type CreateSpaceFormValues = CreateSpaceRequest & {
  applyFuzzyAfterCreate?: boolean;
  fuzzy?: Partial<SpaceFuzzyOverrideProfileRequest>;
};

export const CreateSpaceDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateSpaceDrawerProps) => {
  const { message } = App.useApp();
  const [form] = Form.useForm<CreateSpaceFormValues>();
  const createSpace = useCreateSpace();

  const handleSubmit = async (values: CreateSpaceFormValues) => {
    const { applyFuzzyAfterCreate, fuzzy, ...spaceValues } = values;

    createSpace.mutate(spaceValues, {
      onSuccess: async () => {
        if (applyFuzzyAfterCreate && spaceValues.name?.trim()) {
          const body = pickSpaceFuzzyOverrideBody(fuzzy);
          try {
            const listRes = await spaceService.getList({
              search: spaceValues.name.trim(),
              page: 1,
              pageSize: 25,
              sortBy: 'createdAt',
              isAscending: false,
            });

            const exact = listRes.data?.items?.find(
              (s) => s.name.trim() === spaceValues.name.trim(),
            );

            if (exact) {
              await spaceService.createFuzzyOverrideProfile(exact.id, body);
              message.success('Space fuzzy profile created and activated.');
            } else {
              message.warning(
                'Space was created; fuzzy override was not applied automatically. Use Edit space.',
              );
            }
          } catch {
            message.warning(
              'Space was created but fuzzy override failed. Try Edit space.',
            );
          }
        }

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

        <Form.Item
          label='IoT Device ID'
          name='ioTDeviceId'
          tooltip='Device identifier used by CAMS telemetry query for this space'
        >
          <Input placeholder='e.g., esp32-people-counter' />
        </Form.Item>

        <Divider />

        <Alert
          type='info'
          showIcon
          style={{ marginBottom: 12 }}
          message='Optional after-create action'
          description='Create and activate a space fuzzy profile immediately after space creation.'
        />

        <Form.Item
          name='applyFuzzyAfterCreate'
          valuePropName='checked'
          initialValue={false}
        >
          <Checkbox>
            Create &amp; activate space fuzzy profile after create
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
              <>
                <Typography.Paragraph type='secondary'>
                  Profile is created through{' '}
                  <Typography.Text code>
                    POST /api/spaces/:id/fuzzy-profiles
                  </Typography.Text>
                  . Allowed playlists can be configured later in Edit space.
                </Typography.Paragraph>
                <SpaceFuzzyOverrideFields />
              </>
            ) : null
          }
        </Form.Item>
      </Form>
    </Drawer>
  );
};
