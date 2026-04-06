import { Button, Flex, Result, Typography } from 'antd';
import { useNavigate } from 'react-router';

const { Title } = Typography;

export const UnexpectedErrorPage = () => {
  const navigate = useNavigate();

  return (
    <Flex
      className='min-h-dvh'
      vertical
      align='center'
      justify='center'
    >
      <Result
        status='500'
        title={<Title level={1}>Internal Server Error</Title>}
        subTitle='Server error 500. we fixing the problem. please try again at a later stage.'
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
