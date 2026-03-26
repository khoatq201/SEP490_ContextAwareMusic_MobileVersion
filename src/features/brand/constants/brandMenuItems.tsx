import type { ItemType } from 'antd/es/menu/interface';

/**
 * Icons
 */
import {
  DashboardOutlined,
  ShopOutlined,
  TeamOutlined,
  CustomerServiceOutlined,
  UnorderedListOutlined,
  TabletOutlined,
  CalendarOutlined,
  ControlOutlined,
} from '@ant-design/icons';

export const BRAND_MENU_ITEMS: ItemType[] = [
  {
    key: 'dashboard',
    icon: <DashboardOutlined />,
    label: 'Dashboard',
  },
  {
    key: 'stores',
    icon: <ShopOutlined />,
    label: 'Store Management',
  },
  {
    key: 'staff',
    icon: <TeamOutlined />,
    label: 'Staff Management',
  },
  {
    key: 'tracks',
    icon: <CustomerServiceOutlined />,
    label: 'Track Management',
  },
  {
    key: 'playlists',
    icon: <UnorderedListOutlined />,
    label: 'Playlist Management',
  },
  {
    key: 'devices',
    icon: <TabletOutlined />,
    label: 'Device Management',
  },
  {
    key: 'schedule',
    icon: <CalendarOutlined />,
    label: 'Schedule',
  },
  {
    key: 'music-control',
    icon: <ControlOutlined />,
    label: 'Music Control',
  },
];
