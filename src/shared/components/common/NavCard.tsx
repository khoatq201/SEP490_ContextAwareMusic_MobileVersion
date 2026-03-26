import { Button, Card, Flex } from 'antd';
import { Typography } from 'antd';

const { Title, Text } = Typography;

/**
 * Assets
 */
import fileImage from '@/assets/images/files.png';

export const NavCard = () => {
  return (
    <Card className='m-3! mx-5! bg-gray-50!'>
      <Flex
        vertical
        align='center'
        justify='center'
        gap='middle'
      >
        <img
          src={fileImage}
          width={150}
          className='object-cover'
          alt=''
        />
        <Flex
          vertical
          align='center'
        >
          <Title level={5}>Help?</Title>
          <Text type='secondary'>Get to resolve query</Text>
        </Flex>
        <Button type='primary'>Support</Button>
      </Flex>
    </Card>
  );
};
