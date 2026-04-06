import type { ItemType } from 'antd/es/menu/interface';

/**
 * Icons
 */
import {
  DashboardOutlined,
  ShopOutlined,
  CustomerServiceOutlined,
  UnorderedListOutlined,
} from '@ant-design/icons';

export const STORE_MENU_ITEMS: ItemType[] = [
  {
    key: 'dashboard',
    icon: <DashboardOutlined />,
    label: 'Dashboard',
  },
  {
    key: 'spaces',
    icon: <ShopOutlined />,
    label: 'Space Management',
  },
  {
    key: 'tracks',
    icon: <CustomerServiceOutlined />,
    label: 'Track Library',
  },
  {
    key: 'playlists',
    icon: <UnorderedListOutlined />,
    label: 'Playlist Management',
  },
];
