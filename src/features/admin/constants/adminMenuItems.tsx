/**
 * Types
 */
import type { ItemType } from 'antd/es/menu/interface';

/**
 * Icons
 */
import {
  DashboardOutlined,
  UserOutlined,
  ShopOutlined,
  CustomerServiceOutlined,
  UnorderedListOutlined,
} from '@ant-design/icons';

export const ADMIN_MENU_ITEMS: ItemType[] = [
  {
    key: 'dashboard',
    icon: <DashboardOutlined />,
    label: 'Dashboard',
  },
  {
    key: 'accounts',
    icon: <UserOutlined />,
    label: 'Manager Management',
  },
  {
    key: 'brands',
    icon: <ShopOutlined />,
    label: 'Brand Management',
  },
  {
    key: 'tracks',
    icon: <CustomerServiceOutlined />,
    label: 'Track Library',
  },
  {
    key: 'playlists',
    icon: <UnorderedListOutlined />,
    label: 'Playlist Library',
  },
];
