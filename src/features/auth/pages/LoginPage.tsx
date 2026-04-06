/**
 * Node modules
 */
import { Flex, Typography } from 'antd';

const { Title } = Typography;

/**
 * Components
 */
import { Seo } from '@/shared/components';
import { AuthWrapper, LoginForm } from '../components';

export const LoginPage = () => {
  return (
    <>
      <Seo
        title='Login'
        description='Sign in to CAMS - Content and Music System'
        keywords='login, signin, authentication'
      />
      <AuthWrapper>
        <Flex
          vertical
          gap={24}
        >
          <Flex
            justify='start'
            align='center'
          >
            <Title level={3}>Login</Title>
          </Flex>
          <LoginForm />
        </Flex>
      </AuthWrapper>
    </>
  );
};
