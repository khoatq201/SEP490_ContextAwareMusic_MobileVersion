/**
 * Node modules
 */
import { Flex, Typography } from 'antd';

const { Link, Text } = Typography;

export const AuthFooter = () => {
  return (
    <footer className='mx-auto w-full max-w-7xl px-4 py-8'>
      <Flex
        justify='space-between'
        align='center'
        wrap='wrap'
        gap={16}
      >
        <Flex align='center'>
          <Text className='text-gray'>
            CAMS ©{new Date().getFullYear()} Created by CAMS - FPT University
          </Text>
        </Flex>
        <Flex
          align='center'
          gap={16}
        >
          <Link href='#'>Terms and Conditions</Link>
          <Link href='#'>Privacy Policy</Link>
        </Flex>
      </Flex>
    </footer>
  );
};
