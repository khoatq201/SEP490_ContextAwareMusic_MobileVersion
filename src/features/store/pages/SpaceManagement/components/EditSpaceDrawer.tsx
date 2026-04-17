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
  Divider,
  Typography,
} from 'antd';

/**
 * Hooks
 */
import {
  useSpace,
  useUpdateSpace,
  useCreateSpaceFuzzyOverrideProfile,
} from '@/shared/modules/spaces/hooks';

/**
 * Types
 */
import type {
  UpdateSpaceRequest,
  SpaceFuzzyOverrideProfileRequest,
} from '@/shared/modules/spaces/types';

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
import { SpaceFuzzyOverrideFields } from './SpaceFuzzyOverrideFields';
import { pickSpaceFuzzyOverrideBody } from './spaceFuzzyOverrideUtils';

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

type EditSpaceFormValues = UpdateSpaceRequest & {
  fuzzy?: Partial<SpaceFuzzyOverrideProfileRequest>;
};

export const EditSpaceDrawer = ({
  open,
  spaceId,
  onClose,
  onSuccess,
}: EditSpaceDrawerProps) => {
  const [form] = Form.useForm<EditSpaceFormValues>();
  const {
    data: space,
    isLoading,
    refetch,
  } = useSpace(spaceId || undefined, open);
  const updateSpace = useUpdateSpace();
  const createFuzzyProfile = useCreateSpaceFuzzyOverrideProfile();

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
        ioTDeviceId: nullToUndefined(space.ioTDeviceId),
        fuzzy: {
          name: space.activeFuzzyProfileName ?? undefined,
          chillBpmMin: space.chillBpmMin ?? undefined,
          chillBpmMax: space.chillBpmMax ?? undefined,
          focusBpmMin: space.focusBpmMin ?? undefined,
          focusBpmMax: space.focusBpmMax ?? undefined,
          energeticBpmMin: space.energeticBpmMin ?? undefined,
          energeticBpmMax: space.energeticBpmMax ?? undefined,
          pressureLowMax: space.pressureLowMax ?? undefined,
          pressureCriticalMin: space.pressureCriticalMin ?? undefined,
          noiseQuietMaxDb:
            space.noiseQuietMaxDb ??
            space.stressComfortableMax ??
            space.densitySparseMax ??
            undefined,
          noiseLoudMinDb:
            space.noiseLoudMinDb ??
            space.stressHighMin ??
            space.densityCrowdedMin ??
            undefined,
          spaceCapacity: space.spaceCapacity ?? undefined,
          defaultDecibelWhenNull:
            space.defaultDecibelWhenNull ??
            space.defaultDensityRatioWhenNull ??
            undefined,
          chillMoodCandidates: space.chillMoodCandidates?.length
            ? space.chillMoodCandidates
            : undefined,
          focusMoodCandidates: space.focusMoodCandidates?.length
            ? space.focusMoodCandidates
            : undefined,
          energeticMoodCandidates: space.energeticMoodCandidates?.length
            ? space.energeticMoodCandidates
            : undefined,
          allowedPlaylistIds: space.allowedPlaylistIds?.length
            ? space.allowedPlaylistIds
            : undefined,
        },
      });
    }
  }, [space, open, form]);

  useEffect(() => {
    if (open && spaceId) {
      void refetch();
    }
  }, [open, spaceId, refetch]);

  const handleSubmit = async (values: EditSpaceFormValues) => {
    if (!spaceId) return;

    const { fuzzy, ...spacePayload } = values;
    void fuzzy;

    updateSpace.mutate(
      { id: spaceId, data: spacePayload },
      {
        onSuccess: () => {
          handleCancel();
          onSuccess();
        },
      },
    );
  };

  const handleCreateFuzzyOverride = () => {
    if (!spaceId) return;
    const fuzzy = form.getFieldValue('fuzzy') as
      | Partial<SpaceFuzzyOverrideProfileRequest>
      | undefined;
    const body = pickSpaceFuzzyOverrideBody(fuzzy);
    createFuzzyProfile.mutate(
      { spaceId, body },
      {
        onSuccess: () => {
          void refetch();
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

          <Form.Item
            label='IoT Device ID'
            name='ioTDeviceId'
            tooltip='Device identifier used by CAMS telemetry query for this space'
          >
            <Input placeholder='e.g., esp32-people-counter' />
          </Form.Item>

          <Divider />

          <Typography.Title
            level={5}
            style={{ marginBottom: 8 }}
          >
            Space fuzzy override
          </Typography.Title>
          <Typography.Paragraph type='secondary'>
            Creates and activates a profile via{' '}
            <Typography.Text code>
              POST /api/spaces/:id/fuzzy-profiles
            </Typography.Text>
            .
          </Typography.Paragraph>

          <SpaceFuzzyOverrideFields storeIdForPlaylists={space?.storeId} />

          <Button
            size='large'
            type='primary'
            onClick={handleCreateFuzzyOverride}
            loading={createFuzzyProfile.isPending}
          >
            Create &amp; Activate Space Profile
          </Button>
        </Form>
      )}
    </Drawer>
  );
};
