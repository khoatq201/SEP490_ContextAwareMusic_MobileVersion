import { Link } from 'react-router';
import { Button, Checkbox, Flex, Form, Input, Typography } from 'antd';

/**
 * Hooks
 */
import { useAuth } from '@/providers';

/**
 * Validations
 */
import { loginValidation } from '../validations';

/**
 * Types
 */
import { ErrorCodeEnum } from '@/shared/types';

type LoginFormType = {
  email: string;
  password: string;
  rememberMe: boolean;
};

const { Link: AntLink } = Typography;

export const LoginForm = () => {
  const { login } = useAuth();
  const [form] = Form.useForm<LoginFormType>();

  const handleSubmit = (values: LoginFormType) => {
    login.mutate(
      {
        email: values.email,
        password: values.password,
        rememberMe: values.rememberMe ?? false,
      },
      {
        onError: (error: any) => {
          const errorCode = error.response?.data?.errorCode;
          const errorMessage =
            error.response?.data?.message || 'Login failed! Please try again.';

          // Handle InvalidCredentials (wrong email/password)
          if (errorCode === ErrorCodeEnum.InvalidCredentials) {
            form.setFields([
              {
                name: 'email',
                errors: [''],
              },
              {
                name: 'password',
                errors: [errorMessage], // Show error on password field
              },
            ]);
            return;
          }

          // Handle other auth errors
          if (errorCode === ErrorCodeEnum.Forbidden) {
            form.setFields([
              {
                name: 'email',
                errors: ['You do not have permission to access this system'],
              },
            ]);
            return;
          }
        },
      },
    );
  };

  return (
    <Form
      form={form}
      size='large'
      layout='vertical'
      requiredMark={false}
      onFinish={handleSubmit}
      // autoComplete='off'
      initialValues={{
        rememberMe: true,
      }}
      styles={{ label: { height: 20 } }}
    >
      <Form.Item<LoginFormType>
        label='Email Address'
        name='email'
        rules={loginValidation.email}
      >
        <Input placeholder='Enter email address' />
      </Form.Item>

      <Form.Item<LoginFormType>
        label='Password'
        name='password'
        rules={loginValidation.password}
      >
        <Input.Password placeholder='Enter password' />
      </Form.Item>

      <Form.Item<LoginFormType>
        name='rememberMe'
        valuePropName='checked'
        label={null}
      >
        <Flex justify='space-between'>
          <Checkbox defaultChecked>Remember me</Checkbox>
          <Link to='/forgot-password'>
            <AntLink>Forgot Password?</AntLink>
          </Link>
        </Flex>
      </Form.Item>

      <Button
        type='primary'
        htmlType='submit'
        className='w-full'
        loading={login.isPending}
      >
        Login
      </Button>
    </Form>
  );
};
