import { Flex, Layout, Menu } from 'antd';
import SimpleBar from 'simplebar-react';
import 'simplebar-react/dist/simplebar.min.css';

/**
 * Shared
 */
import { Logo } from '@/shared/components/common/Logo';
import { cn } from '@/shared/lib';

/**
 * Hooks
 */
import { useMenuNavigation } from '@/shared/hooks/useMenuNavigation';

/**
 * Features
 */
import { STORE_MENU_ITEMS, STORE_ROUTE_MAP } from '@/features/store/constants';

/**
 * Components
 */
import { NavCard } from '@/shared/components';

/**
 * Configs
 */
import { SIDEBAR_WIDTHS } from '@/config';

type AppSidebarProps = {
  collapsed: boolean;
};

const { Sider } = Layout;

const siderStyle: React.CSSProperties = {
  overflowY: 'hidden',
  height: '100vh',
  position: 'sticky',
  insetInlineStart: 0,
  top: 0,
  left: 0,
  bottom: 0,
  borderRight: '1px solid #F0F0F0',
};

export const AppSidebar = ({ collapsed }: AppSidebarProps) => {
  const { selectedKeys, openKeys, handleMenuClick } = useMenuNavigation({
    menuItems: STORE_MENU_ITEMS,
    routeMap: STORE_ROUTE_MAP,
  });

  return (
    <Sider
      trigger={null}
      style={siderStyle}
      theme='light'
      width={SIDEBAR_WIDTHS.width}
      collapsedWidth={SIDEBAR_WIDTHS.collapsedWidth}
      collapsible
      collapsed={collapsed}
    >
      <Flex className={cn('p-4!', collapsed && 'px-2.5!')}>
        <Logo isIcon={collapsed} />
      </Flex>
      <SimpleBar
        style={{ maxHeight: '100vh' }}
        className='custom-sidebar-scrollbar'
      >
        <Menu
          theme='light'
          mode='inline'
          className='border-none!'
          selectedKeys={selectedKeys}
          defaultOpenKeys={openKeys}
          items={STORE_MENU_ITEMS}
          onClick={({ key }) => handleMenuClick(key)}
        />
        {!collapsed && <NavCard />}
      </SimpleBar>
    </Sider>
  );
};
