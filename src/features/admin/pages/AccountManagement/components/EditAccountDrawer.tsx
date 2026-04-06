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
import { useUpdateAccount, useAccount } from '@/features/admin/hooks';

/**
 * Components
 */
import { ImageDragger } from '@/shared/components';

/**
 * Types
 */
import type { UploadFile } from 'antd';
import { ErrorCodeEnum } from '@/shared/types';
import type { UpdateAccountRequest } from '@/features/admin/types';

/**
 * Validations
 */
import { updateAccountValidation } from '@/features/admin/validations';

/**
 * Utils
 */
import {
  createImageUploadProps,
  handleApiError,
  nullToUndefined,
} from '@/shared/utils';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

const { Title } = Typography;

type EditAccountDrawerProps = {
  open: boolean;
  accountId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const EditAccountDrawer = ({
  open,
  accountId,
  onClose,
  onSuccess,
}: EditAccountDrawerProps) => {
  const [form] = Form.useForm<UpdateAccountRequest>();
  const [avatarFile, setAvatarFile] = useState<UploadFile | null>(null);
  const [existingAvatarUrl, setExistingAvatarUrl] = useState<string | null>(
    null,
  );

  const { data: account, isLoading: isFetching } = useAccount(
    accountId || undefined,
    open && !!accountId,
  );

  const updateAccount = useUpdateAccount();

  useEffect(() => {
    if (account && open) {
      form.setFieldsValue({
        firstName: account.firstName,
        lastName: account.lastName,
        email: account.email,
        phoneNumber: nullToUndefined(account.phoneNumber),
      });
      setExistingAvatarUrl(account.avatarUrl ?? null);
    }
  }, [account, open, form]);

  const handleSubmit = async (values: UpdateAccountRequest) => {
    if (!accountId) return;

    const formData = new FormData();

    if (values.firstName) formData.append('firstName', values.firstName);
    if (values.lastName) formData.append('lastName', values.lastName);
    if (values.email) formData.append('email', values.email);
    if (values.phoneNumber) formData.append('phoneNumber', values.phoneNumber);
    if (avatarFile?.originFileObj) {
      formData.append('avatar', avatarFile.originFileObj);
    }

    updateAccount.mutate(
      { id: accountId, formData },
      {
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
      },
    );
  };

  const handleCancel = () => {
    form.resetFields();
    setAvatarFile(null);
    setExistingAvatarUrl(null);
    onClose();
  };

  const uploadProps = createImageUploadProps<UpdateAccountRequest>(
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
      title='Edit Account Profile'
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
            loading={updateAccount.isPending}
          >
            Update Profile
          </Button>
        </Flex>
      }
    >
      {isFetching ? (
        <Flex
          justify='center'
          align='center'
          style={{ minHeight: 400 }}
        >
          <Spin size='large' />
        </Flex>
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
          <div style={{ marginBottom: 24 }}>
            <Title
              level={5}
              style={{ marginBottom: 16 }}
            >
              Personal Information
            </Title>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label='First Name'
                  name='firstName'
                  rules={updateAccountValidation.firstName}
                >
                  <Input placeholder='e.g., John' />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label='Last Name'
                  name='lastName'
                  rules={updateAccountValidation.lastName}
                >
                  <Input placeholder='e.g., Doe' />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item
              label='Email'
              name='email'
              rules={updateAccountValidation.email}
            >
              <Input
                placeholder='email@example.com'
                type='email'
              />
            </Form.Item>

            <Form.Item
              label='Phone Number'
              name='phoneNumber'
              rules={updateAccountValidation.phoneNumber}
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
        </Form>
      )}
    </Drawer>
  );
};
