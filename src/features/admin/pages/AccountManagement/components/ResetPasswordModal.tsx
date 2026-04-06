import { useState } from 'react';
import { Alert, Form, Input } from 'antd';

/**
 * Hooks
 */
import { useResetAccountPassword } from '@/features/admin/hooks';

/**
 * Components
 */
import { AppModal, PasswordStrength } from '@/shared/components';

/**
 * Types
 */
import type { ResetPasswordRequest } from '@/features/admin/types';

/**
 * Validations
 */
import { resetPasswordValidation } from '@/features/admin/validations';

/**
 * Configs
 */
import { MODAL_WIDTHS } from '@/config';

type ResetPasswordModalProps = {
  open: boolean;
  accountId: string | null;
  onClose: () => void;
  onSuccess: () => void;
};

export const ResetPasswordModal = ({
  open,
  accountId,
  onClose,
  onSuccess,
}: ResetPasswordModalProps) => {
  const [form] = Form.useForm<ResetPasswordRequest>();
  const resetPassword = useResetAccountPassword();
  const [password, setPassword] = useState('');

  const handleSubmit = async (values: ResetPasswordRequest) => {
    if (!accountId) return;

    resetPassword.mutate(
      { id: accountId, data: values },
      {
        onSuccess: () => {
          form.resetFields();
          setPassword('');
          onSuccess();
          onClose();
        },
      },
    );
  };

  const handleCancel = () => {
    form.resetFields();
    setPassword('');
    onClose();
  };

  const handlePasswordChange = (newPassword: string) => {
    setPassword(newPassword);
    form.setFieldValue('newPassword', newPassword);
  };

  return (
    <AppModal
      size='large'
      title='Reset Password'
      open={open}
      onCancel={handleCancel}
      onOk={() => form.submit()}
      okText='Reset Password'
      confirmLoading={resetPassword.isPending}
      okButtonProps={{
        loading: resetPassword.isPending,
        danger: true,
      }}
      width={MODAL_WIDTHS.medium}
    >
      <Alert
        type='warning'
        showIcon
        title={
          <p className='text-xs'>
            User will be logged out after password reset!
          </p>
        }
        className='mb-5!'
      />
      <Form
        form={form}
        layout='vertical'
        onFinish={handleSubmit}
        autoComplete='off'
        size='large'
        styles={{
          label: {
            height: 22,
          },
        }}
      >
        <Form.Item
          label='New Password'
          name='newPassword'
          rules={resetPasswordValidation.newPassword}
          extra={
            <PasswordStrength
              password={password}
              onPasswordChange={handlePasswordChange}
              showGenerator
              description='This is the password to your account, so it must be strong and hard to guess.'
            />
          }
          className='mb-0!'
        >
          <Input.Password
            placeholder='Enter new password'
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </Form.Item>
      </Form>
    </AppModal>
  );
};
