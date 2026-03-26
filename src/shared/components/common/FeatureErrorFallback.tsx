import { Result, Button } from 'antd';
import { useNavigate } from 'react-router';

interface FeatureErrorFallbackProps {
  featureName?: string;
  onReset?: () => void;
  error?: Error;
}

/**
 * FeatureErrorFallback - Custom error fallback for feature-level errors
 * Shows a more specific error message with navigation options
 */
export const FeatureErrorFallback = ({
  featureName = 'this feature',
  onReset,
  error,
}: FeatureErrorFallbackProps) => {
  const navigate = useNavigate();

  const handleGoHome = () => {
    navigate('/');
  };

  const handleGoBack = () => {
    navigate(-1);
  };

  return (
    <div style={{ padding: '48px 24px', maxWidth: 600, margin: '0 auto' }}>
      <Result
        status='error'
        title={`Error loading ${featureName}`}
        subTitle='We encountered an error while loading this page. You can try going back or return to the home page.'
        extra={[
          <Button
            key='home'
            type='primary'
            size='large'
            onClick={handleGoHome}
          >
            Go Home
          </Button>,
          <Button
            key='back'
            size='large'
            onClick={handleGoBack}
          >
            Go Back
          </Button>,
          onReset && (
            <Button
              key='retry'
              size='large'
              onClick={onReset}
            >
              Try Again
            </Button>
          ),
        ]}
      />
      {import.meta.env.DEV && error && (
        <details
          style={{
            marginTop: 24,
            padding: 16,
            background: '#f5f5f5',
            borderRadius: 4,
          }}
        >
          <summary
            style={{ cursor: 'pointer', fontWeight: 600, marginBottom: 8 }}
          >
            Error Details (Dev Only)
          </summary>
          <pre style={{ fontSize: 12, overflow: 'auto' }}>
            {error.message}
            {'\n\n'}
            {error.stack}
          </pre>
        </details>
      )}
    </div>
  );
};
