import { Navigate } from 'react-router';

/**
 * Components
 */
import { Loadable } from '@/shared/components/common';

/**
 * Pages
 */
const ManagerDashboard = Loadable(
  () => import('@/features/brand/pages/Dashboard'),
  'BrandDashboard',
);

const StoreList = Loadable(
  () => import('@/features/brand/pages/StoreManagement/StoreList'),
  'StoreList',
);

const StaffList = Loadable(
  () => import('@/features/brand/pages/StaffManagement/StaffList'),
  'StaffList',
);

const TrackList = Loadable(
  () => import('@/features/brand/pages/TrackManagement/TrackList'),
  'TrackList',
);

const PlaylistList = Loadable(
  () => import('@/features/brand/pages/PlaylistManagement/PlaylistList'),
  'PlaylistList',
);

const BrandProfile = Loadable(
  () => import('@/features/brand/pages/Profile/BrandProfile'),
  'BrandProfile',
);

const SunoAI = Loadable(
  () => import('@/features/brand/pages/SunoAIGenerator'),
  'SunoAI',
);

export const brandRoutes = [
  {
    path: 'dashboard',
    element: <ManagerDashboard />,
  },
  {
    path: 'stores',
    element: <StoreList />,
  },
  {
    path: 'staff',
    element: <StaffList />,
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
    path: 'suno-ai',
    element: <SunoAI />,
  },
  {
    path: 'profile/*',
    element: <BrandProfile />,
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
