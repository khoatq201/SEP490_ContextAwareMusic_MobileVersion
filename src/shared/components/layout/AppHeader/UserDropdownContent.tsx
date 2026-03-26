import { useNavigate } from 'react-router';
import { useState } from 'react';
import { createStyles } from 'antd-style';
import {
  Avatar,
  Button,
  Flex,
  Menu,
  type MenuProps,
  Tabs,
  Typography,
} from 'antd';

/**
 * Configs
 */
import { AVATAR_SIZE } from '@/config';

/**
 * Providers
 */
import { useAuth } from '@/providers';

/**
 * Icons
 */
import {
  EditOutlined,
  LogoutOutlined,
  SettingOutlined,
  UserOutlined,
} from '@ant-design/icons';

const { Text } = Typography;

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

export const UserDropdownContent = () => {
  const { styles } = useStyle();
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('profile');

  const basePath = location.pathname.startsWith('/admin')
    ? '/admin'
    : location.pathname.startsWith('/brand')
      ? '/brand'
      : '/store';

  const handleLogout = () => {
    logout.mutate(undefined, {
      onSuccess: () => {
        navigate('/login', { replace: true });
      },
    });
  };

  const profileItems: MenuProps['items'] = [
    {
      key: 'edit-profile',
      label: 'Edit Profile',
      icon: <EditOutlined style={{ fontSize: 14 }} />,
      onClick: () => navigate(`${basePath}/profile`),
    },
    {
      key: 'view-profile',
      label: 'View Profile',
      icon: <UserOutlined style={{ fontSize: 14 }} />,
    },
    {
      key: 'logout',
      label: 'Logout',
      icon: <LogoutOutlined style={{ fontSize: 14 }} />,
      onClick: handleLogout,
    },
  ];

  const settingItems: MenuProps['items'] = [
    {
      key: 'account-settings',
      label: 'Account Settings',
      icon: <SettingOutlined style={{ fontSize: 14 }} />,
    },
  ];

  const activeItems = activeTab === 'profile' ? profileItems : settingItems;

  return (
    <div style={{ width: 280 }}>
      {/* Header */}
      <Flex
        align='center'
        justify='space-between'
        className='p-4!'
      >
        <Flex
          align='center'
          gap='small'
        >
          <Avatar
            size={AVATAR_SIZE.medium}
            src={user?.avatarUrl}
            icon={<UserOutlined />}
          />
          <Flex vertical>
            <Text strong>
              {user?.firstName} {user?.lastName}
            </Text>
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
              className='max-w-36 truncate'
            >
              {user?.email}
            </Text>
          </Flex>
        </Flex>
        <Button
          type='text'
          size='large'
          color='primary'
          icon={<LogoutOutlined />}
          onClick={handleLogout}
          title='Logout'
          className='shrink-0'
        />
      </Flex>

      {/* Tabs */}
      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        styles={{
          item: {
            width: '100%',
          },
        }}
        className={styles.customTabs}
        centered
        items={[
          {
            key: 'profile',
            label: (
              <Flex
                align='center'
                gap={4}
              >
                <UserOutlined className='mr-1' />
                Profile
              </Flex>
            ),
          },
          {
            key: 'settings',
            label: (
              <Flex
                align='center'
                gap={4}
              >
                <SettingOutlined className='mr-1' />
                Setting
              </Flex>
            ),
          },
        ]}
      />

      {/* Menu Items */}
      <Menu
        mode='inline'
        items={activeItems}
        style={{ border: 'none' }}
        styles={{
          root: {
            padding: 0,
          },
          item: {
            borderRadius: 0,
            paddingBlock: 10,
            paddingInline: 20,
          },
        }}
      />
    </div>
  );
};
