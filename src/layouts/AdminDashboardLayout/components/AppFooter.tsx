/**
 * Node modules
 */
import { Flex, Layout, Typography } from 'antd';

const { Text, Link } = Typography;
const { Footer } = Layout;

// TODO: Dùng màu có sẵn của antd thay thế hardcore
const footerStyle: React.CSSProperties = {
  background: '#FAFAFB',
};

export const AppFooter = () => {
  return (
    <Footer style={footerStyle}>
      <Flex
        align='center'
        justify='space-between'
      >
        <Flex>
          <Text className='text-gray'>
            CAMS ©{new Date().getFullYear()} Created by CAMS - FPT University
          </Text>
        </Flex>
        <Flex gap={16}>
          <Link href='#'>Terms and Conditions</Link>
          <Link href='#'>Privacy Policy</Link>
          <Link href='#'>Help</Link>
        </Flex>
      </Flex>
    </Footer>
  );
};
