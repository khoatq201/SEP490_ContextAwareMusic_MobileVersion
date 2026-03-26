/**
 * Node modules
 */
import { App, ConfigProvider } from 'antd';

/**
 * Configs
 */
import { antTheme } from '@/config/theme';

export const ThemeProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <ConfigProvider theme={antTheme}>
      <App>{children}</App>
    </ConfigProvider>
  );
};
