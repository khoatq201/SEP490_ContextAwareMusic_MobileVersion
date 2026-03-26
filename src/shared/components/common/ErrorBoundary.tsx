import { Component, type ReactNode } from 'react';
import { Result, Button } from 'antd';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onReset?: () => void;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  componentDidCatch(error: Error, errorInfo: any) {
    console.error('ErrorBoundary caught:', error, errorInfo);

    // TODO: Send to monitoring service (Sentry, LogRocket, etc.)
    // Example:
    // monitoringService.logError(error, {
    //   componentStack: errorInfo.componentStack,
    //   errorBoundary: true,
    // });
  }

  handleReset = () => {
    this.setState({ hasError: false, error: undefined });
    this.props.onReset?.();
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        // If fallback is a React element, clone it and inject error prop
        if (
          typeof this.props.fallback === 'object' &&
          this.props.fallback !== null
        ) {
          return (
            <>
              {this.props.fallback}
              {import.meta.env.DEV && this.state.error && (
                <div className='mx-auto max-w-7xl px-6'>
                  <details className='mt-6 rounded-sm border border-[var(--ant-color-error)] bg-[var(--ant-red-1)] p-4'>
                    <summary className='cursor-pointer font-semibold'>
                      Error Details (Dev Only)
                    </summary>
                    <pre className='mt-2 overflow-auto text-xs'>
                      {this.state.error.message}
                      {'\n\n'}
                      {this.state.error.stack}
                    </pre>
                  </details>
                </div>
              )}
            </>
          );
        }
        return this.props.fallback;
      }

      return (
        <div style={{ padding: '48px 24px', maxWidth: 1200, margin: '0 auto' }}>
          <Result
            status='error'
            title='Something went wrong'
            subTitle='An unexpected error occurred. Please try refreshing the page or contact support if the problem persists.'
            extra={[
              <Button
                key='refresh'
                type='primary'
                size='large'
                onClick={() => window.location.reload()}
              >
                Refresh Page
              </Button>,
              <Button
                key='reset'
                size='large'
                onClick={this.handleReset}
              >
                Try Again
              </Button>,
            ]}
          />
          {import.meta.env.DEV && this.state.error && (
            <div className='mx-auto max-w-7xl px-6'>
              <details className='mt-6 rounded-sm border border-[var(--ant-color-error)] bg-[var(--ant-red-1)] p-4'>
                <summary className='cursor-pointer font-semibold'>
                  Error Details (Dev Only)
                </summary>
                <pre className='mt-2 overflow-auto text-xs'>
                  {this.state.error.message}
                  {'\n\n'}
                  {this.state.error.stack}
                </pre>
              </details>
            </div>
          )}
        </div>
      );
    }

    return this.props.children;
  }
}
