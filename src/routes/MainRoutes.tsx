import { Navigate } from 'react-router';

/**
 * Layouts
 */
import {
  AdminDashboardLayout,
  BrandDashboardLayout,
  StoreDashboardLayout,
} from '@/layouts';

/**
 * Components
 */
import { ProtectedRoute } from '@/shared/components';

/**
 * Routes
 */
import { adminRoutes } from '@/features/admin/routes';
import { brandRoutes } from '@/features/brand/routes';
import { storeRoutes } from '@/features/store/routes';

/**
 * Types
 */
import { RoleEnum } from '@/shared/types';

export const MainRoutes = [
  {
    path: '/admin',
    element: (
      <ProtectedRoute allowedRoles={[RoleEnum.SystemAdmin]}>
        <AdminDashboardLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        index: true,
        element: (
          <Navigate
            to='/admin/dashboard'
            replace
          />
        ),
      },
      ...adminRoutes,
    ],
  },
  {
    path: '/brand',
    element: (
      <ProtectedRoute allowedRoles={[RoleEnum.BrandManager]}>
        <BrandDashboardLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        index: true,
        element: (
          <Navigate
            to='/brand/dashboard'
            replace
          />
        ),
      },
      ...brandRoutes,
    ],
  },
  {
    path: '/store',
    element: (
      <ProtectedRoute allowedRoles={[RoleEnum.StoreManager]}>
        <StoreDashboardLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        index: true,
        element: (
          <Navigate
            to='/store/dashboard'
            replace
          />
        ),
      },
      ...storeRoutes,
    ],
  },
];
