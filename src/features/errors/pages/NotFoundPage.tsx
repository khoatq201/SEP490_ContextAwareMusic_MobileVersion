import { Button, Flex, Result, Typography } from 'antd';
import { useNavigate } from 'react-router';

const { Title } = Typography;

export const NotFoundPage = () => {
  const navigate = useNavigate();

  return (
    <Flex
      className='min-h-dvh'
      vertical
      align='center'
      justify='center'
    >
      <Result
        status='404'
        title={<Title level={1}>Page Not Found</Title>}
        subTitle='The page you are looking was moved, removed, renamed, or might never exist!'
        extra={
          <Button
            type='primary'
            onClick={() => navigate(-1)}
          >
            Go Back
          </Button>
        }
      />
    </Flex>
  );
};
