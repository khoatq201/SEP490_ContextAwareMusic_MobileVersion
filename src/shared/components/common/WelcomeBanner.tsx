import { Button, Col, Flex, Row, Typography } from 'antd';

/**
 * Images
 */
import welcomeImage from '@/assets/images/welcome-banner.webp';

const { Title, Text } = Typography;

export const WelcomeBanner = () => {
  return (
    <div
      className='h-64 rounded-sm p-4 px-10'
      style={{
        background:
          'linear-gradient(250.38deg, #e6f4ff 2.39%, #69b1ff 34.42%, #1677ff 60.95%, #0958d9 84.83%, #002c8c 104.37%)',
      }}
    >
      <Row
        gutter={[16, 16]}
        justify='center'
      >
        <Col
          span={12}
          className='py-7'
        >
          <Flex
            vertical
            gap={12}
          >
            <Title
              level={2}
              className='text-white!'
            >
              Welcome to CAMS
            </Title>
            <Text className='text-white!'>
              The purpose of a product update is to add new features, fix bugs
              or improve the performance of the product.
            </Text>
            <Button
              size='large'
              variant='outlined'
              className='w-fit! border-white! bg-transparent! text-white! hover:bg-blue-400!'
            >
              View Full
            </Button>
          </Flex>
        </Col>
        <Col span={12}>
          <Flex justify='right'>
            <img
              src={welcomeImage}
              alt=''
            />
          </Flex>
        </Col>
      </Row>
    </div>
  );
};
