import { Card, Form, Input, Button, Row, Col, Typography, List } from 'antd';
import { useState } from 'react';

/**
 * Icons
 */
import { EyeInvisibleOutlined, EyeTwoTone } from '@ant-design/icons';

/**
 * Hooks
 */
import { useChangePassword } from '@/shared/modules/auth/hooks';

/**
 * Types
 */
import { ErrorCodeEnum } from '@/shared/types';
import type { ChangePasswordRequest } from '@/shared/modules/auth/types';

/**
 * Validations
 */
import { changePasswordValidation } from '@/features/auth/validations';

/**
 * Components
 */
import { PasswordStrength } from '@/shared/components/ui';

const { Text } = Typography;

/**
 * ChangePasswordContent - Change Password tab content
 * Allows users to change their password
 */
export const ChangePasswordContent = () => {
  const [form] = Form.useForm<ChangePasswordRequest>();
  const changePassword = useChangePassword();
  const [newPassword, setNewPassword] = useState('');

  const handleSubmit = async (values: ChangePasswordRequest) => {
    changePassword.mutate(values, {
      onSuccess: () => {
        form.resetFields();
        setNewPassword('');
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      onError: (error: any) => {
        const errorCode = error.response?.data?.errorCode;

        if (errorCode === ErrorCodeEnum.InvalidCredentials) {
          form.setFields([
            {
              name: 'currentPassword',
              errors: ['Invalid Password! Please try again!'],
            },
          ]);
          return;
        }
      },
    });
  };

  const handleCancel = () => {
    form.resetFields();
    setNewPassword('');
  };

  const handlePasswordChange = (newPassword: string) => {
    setNewPassword(newPassword);
    form.setFieldValue('newPassword', newPassword);
  };

  const passwordRequirements = [
    'At least 6 characters',
    'Mix of uppercase and lowercase letters recommended',
    'Include numbers for better security',
    'Special characters (!@#$%^&*) for stronger password',
  ];

  return (
    <Row gutter={[24, 24]}>
      <Col
        xs={24}
        lg={14}
      >
        <Card title='Change Password'>
          <Form
            form={form}
            layout='vertical'
            onFinish={handleSubmit}
            autoComplete='off'
          >
            <Form.Item
              label='Current Password'
              name='currentPassword'
              rules={changePasswordValidation.currentPassword}
            >
              <Input.Password
                size='large'
                placeholder='Enter your current password'
                iconRender={(visible) =>
                  visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />
                }
              />
            </Form.Item>

            <Form.Item
              label='New Password'
              name='newPassword'
              rules={changePasswordValidation.newPassword}
              extra={
                <PasswordStrength
                  password={newPassword}
                  onPasswordChange={handlePasswordChange}
                  showGenerator
                  description='This is the password to your account, so it must be strong and hard to guess.'
                />
              }
            >
              <Input.Password
                size='large'
                placeholder='Enter your new password'
                onChange={(e) => setNewPassword(e.target.value)}
                iconRender={(visible) =>
                  visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />
                }
              />
            </Form.Item>

            <Form.Item
              label='Confirm New Password'
              name='confirmPassword'
              rules={changePasswordValidation.confirmPassword}
            >
              <Input.Password
                size='large'
                placeholder='Confirm your new password'
                iconRender={(visible) =>
                  visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />
                }
              />
            </Form.Item>

            <Form.Item style={{ marginBottom: 0 }}>
              <Button
                type='primary'
                htmlType='submit'
                size='large'
                loading={changePassword.isPending}
                style={{ marginRight: 8 }}
              >
                Update Password
              </Button>
              <Button
                size='large'
                onClick={handleCancel}
                disabled={changePassword.isPending}
              >
                Cancel
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </Col>

      <Col
        xs={24}
        lg={10}
      >
        <Card title='Password Requirements'>
          <Text
            type='secondary'
            style={{ display: 'block', marginBottom: 16 }}
          >
            Your new password must meet the following requirements:
          </Text>
          <List
            size='small'
            dataSource={passwordRequirements}
            renderItem={(item) => (
              <List.Item style={{ padding: '8px 0', border: 'none' }}>
                <Text>• {item}</Text>
              </List.Item>
            )}
          />
        </Card>

        <Card
          title='Security Tips'
          style={{ marginTop: 24 }}
        >
          <List
            size='small'
            dataSource={[
              'Never share your password with anyone',
              'Use a unique password for this account',
              'Change your password regularly',
              'Avoid using personal information in passwords',
            ]}
            renderItem={(item) => (
              <List.Item style={{ padding: '8px 0', border: 'none' }}>
                <Text type='secondary'>💡 {item}</Text>
              </List.Item>
            )}
          />
        </Card>
      </Col>
    </Row>
  );
};
