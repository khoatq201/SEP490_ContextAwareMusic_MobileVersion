import { Navigate } from 'react-router';

/**
 * Components
 */
import { Loadable } from '@/shared/components/common';

/**
 * Pages
 */
const AdminDashboard = Loadable(
  () => import('@/features/admin/pages/Dashboard'),
  'AdminDashboard',
);

const BrandList = Loadable(
  () => import('@/features/admin/pages/BrandManagement/BrandList'),
  'BrandList',
);

const FuzzyProfileTemplateList = Loadable(
  () =>
    import('@/features/admin/pages/FuzzyProfileTemplateManagement/FuzzyProfileTemplateList'),
  'FuzzyProfileTemplateList',
);

const AccountList = Loadable(
  () => import('@/features/admin/pages/AccountManagement/AccountList'),
  'AccountList',
);

const ConfigList = Loadable(
  () => import('@/features/admin/pages/ConfigManagement/ConfigList'),
  'ConfigList',
);

const TrackList = Loadable(
  () => import('@/features/admin/pages/TrackManagement/TrackList'),
  'TrackList',
);

const PlaylistList = Loadable(
  () => import('@/features/admin/pages/PlaylistManagement/PlaylistList'),
  'PlaylistList',
);

const AdminProfile = Loadable(
  () => import('@/features/admin/pages/Profile/AdminProfile'),
  'AdminProfile',
);

const BillingPackages = Loadable(
  () => import('@/features/admin/pages/BillingPackages'),
  'AdminBillingPackages',
);

export const adminRoutes = [
  {
    path: 'dashboard',
    element: <AdminDashboard />,
  },
  {
    path: 'brands',
    element: <BrandList />,
  },
  {
    path: 'ai-fuzzy-templates',
    element: <FuzzyProfileTemplateList />,
  },
  {
    path: 'accounts',
    element: <AccountList />,
  },
  {
    path: 'config-management',
    element: <ConfigList />,
  },
  {
    path: 'tracks',
    element: <TrackList />,
  },
  {
    path: 'playlists',
    element: <PlaylistList />,
  },
  {
    path: 'billing-packages',
    element: <BillingPackages />,
  },
  {
    path: 'profile/*',
    element: <AdminProfile />,
  },
  {
    path: '*',
    element: (
      <Navigate
        to='/admin/dashboard'
        replace
      />
    ),
  },
];
