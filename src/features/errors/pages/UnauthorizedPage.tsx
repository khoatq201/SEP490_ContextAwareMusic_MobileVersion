import { Button, Flex, Result, Typography } from 'antd';
import { useNavigate } from 'react-router';

const { Title } = Typography;

export const UnauthorizedPage = () => {
  const navigate = useNavigate();

  return (
    <Flex
      className='min-h-dvh'
      vertical
      align='center'
      justify='center'
    >
      <Result
        status='403'
        title={<Title level={1}>Unauthorized</Title>}
        subTitle='Sorry, you are not authorized to access this page.'
        extra={
          <Button
            type='primary'
            onClick={() => navigate('/')}
          >
            Back To Home
          </Button>
        }
      />
    </Flex>
  );
};
