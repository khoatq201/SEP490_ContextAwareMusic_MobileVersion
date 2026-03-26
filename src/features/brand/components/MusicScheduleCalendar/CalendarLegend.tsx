import { Flex, Typography } from 'antd';

const { Text } = Typography;

export const CalendarLegend = () => {
  return (
    <Flex
      gap={16}
      style={{ marginBottom: 16 }}
    >
      <Flex
        align='center'
        gap={8}
      >
        <div
          style={{
            width: 12,
            height: 12,
            backgroundColor: '#52c41a',
            borderRadius: 2,
          }}
        />
        <Text type='secondary'>Auto Mode</Text>
      </Flex>
      <Flex
        align='center'
        gap={8}
      >
        <div
          style={{
            width: 12,
            height: 12,
            backgroundColor: '#1677ff',
            borderRadius: 2,
          }}
        />
        <Text type='secondary'>Manual Mode</Text>
      </Flex>
    </Flex>
  );
};
