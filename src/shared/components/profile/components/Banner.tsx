import { Flex, Progress, Space, Typography } from 'antd';

/**
 * Shared
 */
import { cn } from '@/shared/lib';

/**
 * Assets
 */
import LeftWave from '../assets/left-wave.svg?react';
import RightWave from '../assets/right-wave.svg?react';

const { Title, Text } = Typography;

export const Banner = ({
  className,
  ...props
}: React.ComponentProps<'div'>) => {
  return (
    <div
      className={cn(
        'relative rounded-sm bg-[var(--ant-blue-1)] p-4 px-7',
        className,
      )}
      {...props}
    >
      <LeftWave className='absolute bottom-0 left-0 text-[var(--ant-blue-3)]' />
      <RightWave className='absolute top-0 right-0 text-[var(--ant-blue-3)]' />
      <Flex
        gap={20}
        align='center'
      >
        <Progress
          type='circle'
          percent={30}
          size={85}
          format={(value) => (
            <span className='text-sm font-medium'>{value}%</span>
          )}
          strokeLinecap='square'
          railColor='#ffffff'
        />
        <Space
          vertical
          size={0}
        >
          <Title level={5}>Edit Your Profile</Title>
          <Text
            type='secondary'
            style={{ fontSize: 13 }}
          >
            Complete your profile to unlock all features
          </Text>
        </Space>
      </Flex>
    </div>
  );
};
