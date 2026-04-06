/**
 * Node modules
 */
import { Layout } from 'antd';

const { Content } = Layout;

// TODO: Dùng màu có sẵn của antd thay thế hardcore
const contentStyle: React.CSSProperties = {
  background: '#FAFAFB',
  padding: '20px 40px',
};

export const AppContent = ({ children }: { children: React.ReactNode }) => {
  return <Content style={contentStyle}>{children}</Content>;
};
