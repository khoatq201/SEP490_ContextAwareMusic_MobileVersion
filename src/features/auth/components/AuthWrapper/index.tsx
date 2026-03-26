/**
 * Node modules
 */
import { Card, Flex } from 'antd';

/**
 * Components
 */
import { AuthBackground } from './AuthBackground';
import { AuthFooter } from './AuthFooter';
import { AuthHeader } from './AuthHeader';

export const AuthWrapper = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className='relative min-h-dvh'>
      <Flex
        vertical
        className='h-screen'
      >
        <AuthHeader />
        <Flex
          flex={1}
          align='center'
          justify='center'
          className='px-4'
        >
          <Card className='shadow-1 w-120 lg:p-4!'>{children}</Card>
        </Flex>
        <AuthFooter />
      </Flex>
      <AuthBackground />
    </div>
  );
};
