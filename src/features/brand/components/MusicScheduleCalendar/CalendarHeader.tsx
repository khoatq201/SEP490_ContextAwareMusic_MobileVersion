import { Button, Flex, Space, Typography } from 'antd';

/**
 * Icons
 */
import { LeftOutlined, RightOutlined } from '@ant-design/icons';

const { Title, Text } = Typography;

type CalendarHeaderProps = {
  dateRangeText: string;
  onPrevious: () => void;
  onNext: () => void;
  onToday: () => void;
};

export const CalendarHeader = ({
  dateRangeText,
  onPrevious,
  onNext,
  onToday,
}: CalendarHeaderProps) => {
  return (
    <Flex
      align='center'
      gap={16}
    >
      <Title
        level={4}
        style={{ margin: 0 }}
      >
        Music Schedule
      </Title>
      <Space>
        <Button onClick={onToday}>Today</Button>
        <Button
          type='text'
          icon={<LeftOutlined />}
          onClick={onPrevious}
        />
        <Button
          type='text'
          icon={<RightOutlined />}
          onClick={onNext}
        />
      </Space>
      <Text strong>{dateRangeText}</Text>
    </Flex>
  );
};
