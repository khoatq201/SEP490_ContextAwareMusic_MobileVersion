import { useMemo } from 'react';
import { useNavigate, useLocation } from 'react-router';
import type { MenuProps } from 'antd';

type MenuItem = Required<MenuProps>['items'][number];

type UseMenuNavigationProps = {
  menuItems: MenuItem[];
  routeMap: Record<string, string>;
};

type UseMenuNavigationReturn = {
  selectedKeys: string[];
  openKeys: string[];
  handleMenuClick: (key: string) => void;
};

/**
 * Custom hook to handle menu navigation and active state
 * @param menuItems - Ant Design menu items configuration
 * @param routeMap - Mapping of menu keys to routes (e.g., { 'dashboard': '/admin/dashboard' })
 * @returns Selected keys, open keys, and click handler
 */
export const useMenuNavigation = ({
  menuItems,
  routeMap,
}: UseMenuNavigationProps): UseMenuNavigationReturn => {
  const navigate = useNavigate();
  const location = useLocation();

  // Create reverse mapping (path -> key)
  const pathToKeyMap = useMemo(() => {
    const map: Record<string, string> = {};
    Object.entries(routeMap).forEach(([key, path]) => {
      map[path] = key;
    });
    return map;
  }, [routeMap]);

  // Find active menu key from current pathname
  const selectedKeys = useMemo(() => {
    const currentPath = location.pathname;

    // Exact match
    if (pathToKeyMap[currentPath]) {
      return [pathToKeyMap[currentPath]];
    }

    // Partial match (for nested routes like /admin/brands/123)
    const matchedKey = Object.entries(routeMap).find(([_, path]) =>
      currentPath.startsWith(path),
    )?.[0];

    return matchedKey ? [matchedKey] : [];
  }, [location.pathname, pathToKeyMap, routeMap]);

  // Find open submenu keys based on selected key
  const openKeys = useMemo(() => {
    const keys: string[] = [];

    // Helper function to find parent menu key
    const findParentKey = (
      items: MenuItem[],
      targetKey: string,
    ): string | null => {
      for (const item of items) {
        if (
          item &&
          typeof item === 'object' &&
          'children' in item &&
          item.children
        ) {
          const child = item.children.find(
            (c: any) =>
              c && typeof c === 'object' && 'key' in c && c.key === targetKey,
          );
          if (child && 'key' in item) return item.key as string;

          const nested = findParentKey(item.children as MenuItem[], targetKey);
          if (nested && 'key' in item) return item.key as string;
        }
      }
      return null;
    };

    if (selectedKeys.length > 0) {
      const parentKey = findParentKey(menuItems, selectedKeys[0]);
      if (parentKey) keys.push(parentKey);
    }

    return keys;
  }, [selectedKeys, menuItems]);

  // Handle menu item click
  const handleMenuClick = (key: string) => {
    const route = routeMap[key];
    if (route) {
      navigate(route);
    }
  };

  return {
    selectedKeys,
    openKeys,
    handleMenuClick,
  };
};
