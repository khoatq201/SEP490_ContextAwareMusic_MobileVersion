import { useState } from 'react';
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
} from 'antd';

/**
 * Hooks
 */
import { useCreateStaff, useStores } from '@/features/brand/hooks';

/**
 * Components
 */
import { ImageDragger, PasswordStrength } from '@/shared/components';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import { type CreateStaffRequest } from '@/features/brand/types';
import { EntityStatusEnum, RoleEnum } from '@/shared/types';

/**
 * Validations
 */
import { createStaffValidation } from '@/features/brand/validations';

/**
 * Utils
 */
import { createImageUploadProps } from '@/shared/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

type CreateStaffDrawerProps = {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
};

export const CreateStaffDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateStaffDrawerProps) => {
  const [form] = Form.useForm<CreateStaffRequest>();
  const createStaff = useCreateStaff();
  const [avatarFile, setAvatarFile] = useState<UploadFile | null>(null);
  const [password, setPassword] = useState('');

  // Fetch active stores for dropdown
  const { data: storesData } = useStores({
    status: EntityStatusEnum.Active,
    pageSize: 100,
  });

  const storeOptions =
    storesData?.items.map((store) => ({
      label: store.name,
      value: store.id,
    })) || [];

  const handleSubmit = async (values: CreateStaffRequest) => {
    const formData = new FormData();

    // Required fields
    if (values.firstName) formData.append('firstName', values.firstName);
    if (values.lastName) formData.append('lastName', values.lastName);
    if (values.email) formData.append('email', values.email);
    if (values.password) formData.append('password', values.password);
    if (values.storeId) formData.append('storeId', values.storeId);
    formData.append('role', String(RoleEnum.StoreManager));

    // Optional fields
    if (avatarFile?.originFileObj) {
      formData.append('avatar', avatarFile.originFileObj);
    }
    if (values.phoneNumber) formData.append('phoneNumber', values.phoneNumber);

    createStaff.mutate(formData, {
      onSuccess: () => {
        handleCancel();
        onSuccess();
      },
    });
  };

  const handleCancel = () => {
    form.resetFields();
    setAvatarFile(null);
    setPassword('');
    onClose();
  };

  const handlePasswordChange = (newPassword: string) => {
    setPassword(newPassword);
    form.setFieldValue('password', newPassword);
  };

  const uploadProps = createImageUploadProps<CreateStaffRequest>(
    setAvatarFile,
    (field, value) => form.setFieldValue(field, value),
  );

  const getPreviewUrl = () => {
    if (avatarFile?.originFileObj) {
      return URL.createObjectURL(avatarFile.originFileObj);
    }
    return null;
  };

  return (
    <Drawer
      closeIcon={null}
      title='Add New Staff Member'
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
            loading={createStaff.isPending}
          >
            Create Staff
          </Button>
        </Flex>
      }
    >
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
                rules={createStaffValidation.firstName}
              >
                <Input placeholder='e.g., Nguyen' />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='Last Name'
                name='lastName'
                rules={createStaffValidation.lastName}
              >
                <Input placeholder='e.g., Van A' />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label='Email'
            name='email'
            rules={createStaffValidation.email}
          >
            <Input placeholder='email@example.com' />
          </Form.Item>

          <Form.Item
            label='Phone Number'
            name='phoneNumber'
            rules={createStaffValidation.phoneNumber}
          >
            <Input placeholder='+84901234567 or 0901234567' />
          </Form.Item>
        </div>

        {/* Account Setup */}
        <div style={{ marginBottom: 24 }}>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Account Setup
          </Title>

          <Form.Item
            label='Password'
            name='password'
            rules={createStaffValidation.password}
            extra={
              <PasswordStrength
                password={password}
                onPasswordChange={handlePasswordChange}
                showGenerator
                description='This is the password to your account, so it must be strong and hard to guess.'
              />
            }
          >
            <Input.Password
              placeholder='Enter password'
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </Form.Item>

          <Form.Item
            label='Assign Store'
            name='storeId'
            rules={createStaffValidation.storeId}
            extra='This staff member will manage the selected store'
            style={{ marginTop: 16 }}
          >
            <Select
              placeholder='Select a store'
              options={storeOptions}
              showSearch
              filterOption={(input, option) =>
                (option?.label ?? '')
                  .toLowerCase()
                  .includes(input.toLowerCase())
              }
            />
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
      </Form>
    </Drawer>
  );
};
