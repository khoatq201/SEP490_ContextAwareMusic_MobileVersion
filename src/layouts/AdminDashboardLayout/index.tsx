/**
 * Node modules
 */
import { Layout } from 'antd';
import { Outlet } from 'react-router';
import { useState } from 'react';

/**
 * Components
 */
import { AppSidebar, AppFooter, AppContent } from './components';
import { AppHeader } from '@/shared/components/layout';
import { ErrorBoundary, FeatureErrorFallback } from '@/shared/components';

export const AdminDashboardLayout = () => {
  const [collapsed, setCollapsed] = useState(false);

  const handleCollapsed = () => {
    setCollapsed(!collapsed);
  };
  return (
    <Layout hasSider>
      <AppSidebar collapsed={collapsed} />
      <Layout>
        <AppHeader
          collapsed={collapsed}
          onClick={handleCollapsed}
        />
        <AppContent>
          <ErrorBoundary
            fallback={<FeatureErrorFallback featureName='Admin Dashboard' />}
          >
            <Outlet />
          </ErrorBoundary>
        </AppContent>
        <AppFooter />
      </Layout>
    </Layout>
  );
};
