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
import { useCreateAccount, useBrands } from '@/features/admin/hooks';

/**
 * Components
 */
import { ImageDragger, PasswordStrength } from '@/shared/components';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import { ErrorCodeEnum, RoleEnum } from '@/shared/types';
import type { CreateAccountRequest } from '@/features/admin/types';

/**
 * Constants
 */
import { ROLE_OPTIONS_FOR_ADMIN } from '@/features/admin/constants';

/**
 * Validations
 */
import { createAccountValidation } from '@/features/admin/validations';

/**
 * Utils
 */
import { createImageUploadProps, handleApiError } from '@/shared/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

type CreateAccountDrawerProps = {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
};

export const CreateAccountDrawer = ({
  open,
  onClose,
  onSuccess,
}: CreateAccountDrawerProps) => {
  const [form] = Form.useForm<CreateAccountRequest>();
  const [avatarFile, setAvatarFile] = useState<UploadFile | null>(null);
  const [password, setPassword] = useState('');

  const createAccount = useCreateAccount();

  const { data: brandsData } = useBrands({ pageSize: 100 });

  const brandOptions =
    brandsData?.items.map((brand) => ({
      label: brand.name,
      value: brand.id,
    })) || [];

  const handleSubmit = async (values: CreateAccountRequest) => {
    const formData = new FormData();

    // Required fields
    if (values.firstName) formData.append('firstName', values.firstName);
    if (values.lastName) formData.append('lastName', values.lastName);
    if (values.email) formData.append('email', values.email);
    if (values.password) formData.append('password', values.password);
    formData.append('role', String(RoleEnum.BrandManager));

    // Optional fields
    if (avatarFile?.originFileObj) {
      formData.append('avatar', avatarFile.originFileObj);
    }
    if (values.phoneNumber) formData.append('phoneNumber', values.phoneNumber);

    // FIXME: Hình như không cần gửi thì phải!
    if (values.brandId) formData.append('brandId', values.brandId);

    createAccount.mutate(formData, {
      onSuccess: () => {
        handleCancel();
        onSuccess();
      },
      onError: (error: any) => {
        const errorCode = error.response?.data?.errorCode;
        const fieldErrors = error.response?.data?.errors;

        // NOTE: sao payload là camelCase nhưng field lỗi là PascalCase vậy ta?
        if (errorCode === ErrorCodeEnum.ValidationFailed && fieldErrors) {
          form.setFields(
            fieldErrors.map((err: { field: string; message: string }) => ({
              name: err.field.charAt(0).toLowerCase() + err.field.slice(1),
              errors: [err.message],
            })),
          );
          return;
        }
        if (errorCode === ErrorCodeEnum.BusinessRuleViolation) {
          // NOTE: BusinessValidationRule ở đây hơi kỳ khi không chỉ rõ là validation cho trường hợp nào email hay phone!
          form.setFields([
            {
              name: 'email',
              errors: ['Email or phone number already exists'],
            },
            {
              name: 'phoneNumber',
              errors: ['Email or phone number already exists'],
            },
          ]);

          return;
        }

        handleApiError(
          error,
          {},
          'Failed to create account. Please try again.',
        );
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

  const uploadProps = createImageUploadProps<CreateAccountRequest>(
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
      title='Create Brand Manager Account'
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
            loading={createAccount.isPending}
          >
            Create Account
          </Button>
        </Flex>
      }
    >
      <Form
        size='large'
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
        initialValues={{
          role: RoleEnum.BrandManager,
        }}
        styles={{
          label: {
            height: 22,
          },
        }}
      >
        {/* Basic Information Section */}
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
                rules={createAccountValidation.firstName}
              >
                <Input placeholder='e.g., John' />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label='Last Name'
                name='lastName'
                rules={createAccountValidation.lastName}
              >
                <Input placeholder='e.g., Doe' />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label='Email'
            name='email'
            rules={createAccountValidation.email}
          >
            <Input
              placeholder='email@example.com'
              type='email'
            />
          </Form.Item>

          <Form.Item
            label='Password'
            name='password'
            rules={createAccountValidation.password}
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
            label='Phone Number'
            name='phoneNumber'
            rules={createAccountValidation.phoneNumber}
            style={{ marginTop: 16 }}
          >
            <Input placeholder='+84901234567 or 0901234567' />
          </Form.Item>

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

        {/* Assignment Section */}
        <div>
          <Title
            level={5}
            style={{ marginBottom: 16 }}
          >
            Brand Assignment
          </Title>

          <Form.Item
            label='Role'
            name='role'
            rules={createAccountValidation.role}
            hidden
          >
            <Select
              placeholder='Select role'
              options={ROLE_OPTIONS_FOR_ADMIN}
              disabled
            />
          </Form.Item>

          <Form.Item
            label='Brand'
            name='brandId'
            rules={createAccountValidation.brandId}
          >
            <Select
              placeholder='Select brand'
              options={brandOptions}
              showSearch
              filterOption={(input, option) =>
                (option?.label ?? '')
                  .toLowerCase()
                  .includes(input.toLowerCase())
              }
            />
          </Form.Item>
        </div>
      </Form>
    </Drawer>
  );
};
