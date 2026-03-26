import { Card, Tabs } from 'antd';
import { createStyles } from 'antd-style';
import { Outlet, useLocation, useNavigate } from 'react-router';

/**
 * Icons
 */
import { UserOutlined, LockOutlined, SettingOutlined } from '@ant-design/icons';

/**
 * Components
 */
import { PageHeader } from '@/shared/components';
import { Banner } from './components/Banner';

type ProfileLayoutProps = {
  breadcrumbs: { title: string; path?: string }[];
  baseRoute: string; // e.g., '/admin/profile', '/brand/profile', '/store/profile'
};

const useStyle = createStyles(({ css, prefixCls }) => {
  return {
    customTabs: css`
      .${prefixCls}-tabs-nav {
        margin-bottom: 0;
        .${prefixCls}-tabs-nav-wrap {
          .${prefixCls}-tabs-nav-list {
            width: 100%;
            .${prefixCls}-tabs-tab {
              justify-content: center;
              &:hover {
                background-color: var(--ant-blue-1);
                color: var(--ant-tabs-item-selected-color);
              }
            }
          }
        }
      }
    `,
  };
});

/**
 * ProfileLayout - Shared profile layout with tabs
 * Handles routing between Profile, Change Password, and Settings tabs
 */
export const ProfileLayout = ({
  breadcrumbs,
  baseRoute,
}: ProfileLayoutProps) => {
  const { styles } = useStyle();
  const navigate = useNavigate();
  const location = useLocation();

  // Determine active tab from current path
  const getActiveTab = () => {
    const path = location.pathname;
    if (path.endsWith('/change-password')) return 'change-password';
    if (path.endsWith('/settings')) return 'settings';
    return 'profile';
  };

  const handleTabChange = (key: string) => {
    if (key === 'profile') {
      navigate(baseRoute);
    } else {
      navigate(`${baseRoute}/${key}`);
    }
  };

  const tabItems = [
    {
      key: 'profile',
      label: (
        <span>
          <UserOutlined className='mr-2' />
          Profile
        </span>
      ),
    },
    {
      key: 'change-password',
      label: (
        <span>
          <LockOutlined className='mr-2' />
          Change Password
        </span>
      ),
    },
    {
      key: 'settings',
      label: (
        <span>
          <SettingOutlined className='mr-2' />
          Settings
        </span>
      ),
      disabled: true, // Phase 2
    },
  ];

  return (
    <div>
      <PageHeader
        title='My Profile'
        breadcrumbs={breadcrumbs}
        seo={{
          description: 'Manage your profile and account settings',
          keywords: 'user, profile, settings, password',
        }}
      />

      {/* Banner */}
      <Banner className='mb-5' />
      <Card>
        {/* Tabs */}
        <Tabs
          activeKey={getActiveTab()}
          items={tabItems}
          onChange={handleTabChange}
          style={{ marginBottom: 24 }}
          styles={{
            item: {
              width: 'fit-content',
              paddingInline: 20,
            },
          }}
          className={styles.customTabs}
        />

        {/* Tab Content */}
        <Outlet />
      </Card>
    </div>
  );
};
