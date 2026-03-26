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

export const BrandDashboardLayout = () => {
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
            fallback={<FeatureErrorFallback featureName='Brand Dashboard' />}
          >
            <Outlet />
          </ErrorBoundary>
        </AppContent>
        <AppFooter />
        {/* <MusicPlayer sidebarCollapsed={collapsed} /> */}
      </Layout>
    </Layout>
  );
};
