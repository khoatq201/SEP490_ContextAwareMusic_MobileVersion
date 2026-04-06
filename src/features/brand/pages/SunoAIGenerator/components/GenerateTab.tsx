import { Row, Col, Typography, Alert, Space, Flex } from 'antd';
import { ClockCircleOutlined } from '@ant-design/icons';

/**
 * Components
 */
import { SunoGenerationForm } from '@/shared/modules/suno/components';

const { Title, Text } = Typography;

interface GenerateTabProps {
  onSuccess: (generationId: string) => void;
}

export const GenerateTab = ({ onSuccess }: GenerateTabProps) => {
  return (
    <Row gutter={[40, 32]}>
      <Col
        xs={24}
        lg={10}
      >
        <Space
          vertical
          size='large'
          style={{ width: '100%' }}
        >
          <Flex vertical>
            <Title
              level={4}
              style={{
                marginTop: 10,
                marginBottom: 5,
              }}
            >
              Generate AI Music
            </Title>
            <Text type='secondary'>
              Create original music tracks powered by Suno AI. Choose between a
              custom prompt or let CAMS auto-build one from your brand's music
              profile.
            </Text>
          </Flex>

          <Alert
            icon={<ClockCircleOutlined />}
            message='Generation takes 1–2 minutes'
            description='You will be notified when the music is ready. You can continue working while generation is in progress.'
            type='info'
            showIcon
          />
        </Space>
      </Col>

      <Col
        xs={24}
        lg={14}
      >
        <SunoGenerationForm onSuccess={onSuccess} />
      </Col>
    </Row>
  );
};
