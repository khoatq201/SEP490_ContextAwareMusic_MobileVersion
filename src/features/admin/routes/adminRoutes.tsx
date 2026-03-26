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

const AccountList = Loadable(
  () => import('@/features/admin/pages/AccountManagement/AccountList'),
  'AccountList',
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
    path: 'accounts',
    element: <AccountList />,
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
    path: 'profile/*',
    element: <AdminProfile />,
  },
  {
    path: '*',
    element: (
      <Navigate
        to='/store/dashboard'
        replace
      />
    ),
  },
];
