import { useEffect, useState } from 'react';
import {
  Button,
  Drawer,
  Form,
  Input,
  Row,
  Col,
  Typography,
  Flex,
  Spin,
} from 'antd';

/**
 * Hooks
 */
import { useStaffDetail, useUpdateStaff } from '@/features/brand/hooks';

/**
 * Components
 */
import { ImageDragger } from '@/shared/components';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import type { UpdateStaffRequest } from '@/features/brand/types';

/**
 * Validations
 */
import { updateStaffValidation } from '@/features/brand/validations';

/**
 * Utils
 */
import { createImageUploadProps } from '@/shared/utils';
import { nullToUndefined } from '@/shared/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

type EditStaffDrawerProps = {
  open: boolean;
  staffId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const EditStaffDrawer = ({
  open,
  staffId,
  onClose,
  onSuccess,
}: EditStaffDrawerProps) => {
  const [form] = Form.useForm<UpdateStaffRequest>();
  const { data: staff, isLoading } = useStaffDetail(staffId || undefined, open);
  const updateStaff = useUpdateStaff();
  const [avatarFile, setAvatarFile] = useState<UploadFile | null>(null);
  const [existingAvatarUrl, setExistingAvatarUrl] = useState<string | null>(
    null,
  );

  // Populate form when staff data is loaded
  useEffect(() => {
    if (staff && open) {
      form.setFieldsValue({
        firstName: staff.firstName,
        lastName: staff.lastName,
        email: staff.email,
        phoneNumber: nullToUndefined(staff.phoneNumber),
      });
      setExistingAvatarUrl(staff.avatarUrl);
    }
  }, [staff, open, form]);

  const handleSubmit = async (values: UpdateStaffRequest) => {
    if (!staffId) return;

    const formData = new FormData();

    // Optional fields (partial update)
    if (values.firstName) formData.append('firstName', values.firstName);
    if (values.lastName) formData.append('lastName', values.lastName);
    if (values.email) formData.append('email', values.email);
    if (values.phoneNumber) formData.append('phoneNumber', values.phoneNumber);

    // Avatar update
    if (avatarFile?.originFileObj) {
      formData.append('avatar', avatarFile.originFileObj);
    }

    updateStaff.mutate(
      { id: staffId, formData },
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
    setAvatarFile(null);
    setExistingAvatarUrl(null);
    onClose();
  };

  const uploadProps = createImageUploadProps<UpdateStaffRequest>(
    setAvatarFile,
    (field, value) => form.setFieldValue(field, value),
  );

  const getPreviewUrl = () => {
    if (avatarFile?.originFileObj) {
      return URL.createObjectURL(avatarFile.originFileObj);
    }
    return existingAvatarUrl;
  };

  return (
    <Drawer
      closeIcon={null}
      title='Edit Staff Member'
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
            loading={updateStaff.isPending}
            disabled={isLoading}
          >
            Update Staff
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

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label='First Name'
                  name='firstName'
                  rules={updateStaffValidation.firstName}
                >
                  <Input placeholder='e.g., Nguyen' />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label='Last Name'
                  name='lastName'
                  rules={updateStaffValidation.lastName}
                >
                  <Input placeholder='e.g., Van A' />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item
              label='Email'
              name='email'
              rules={updateStaffValidation.email}
            >
              <Input placeholder='email@example.com' />
            </Form.Item>

            <Form.Item
              label='Phone Number'
              name='phoneNumber'
              rules={updateStaffValidation.phoneNumber}
            >
              <Input placeholder='+84901234567 or 0901234567' />
            </Form.Item>

            {/* ✅ Use shared ImageDragger */}
            <Form.Item
              label='Avatar'
              name='avatar'
              valuePropName='file'
            >
              <ImageDragger
                previewUrl={getPreviewUrl()}
                uploadProps={uploadProps}
              />
            </Form.Item>
          </div>

          {/* Read-only Info */}
          {staff && (
            <div style={{ marginTop: 16 }}>
              <Typography.Text type='secondary'>
                Assigned Store:{' '}
                <strong>{staff.storeName || 'Not Assigned'}</strong>
              </Typography.Text>
              <br />
              <Typography.Text type='secondary'>
                Role: <strong>Store Manager</strong>
              </Typography.Text>
            </div>
          )}
        </Form>
      )}
    </Drawer>
  );
};
