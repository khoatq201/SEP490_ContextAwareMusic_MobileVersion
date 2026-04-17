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

const ScheduleList = Loadable(
  () => import('@/features/brand/pages/ScheduleManagement/ScheduleList'),
  'ScheduleList',
);

const ConfigList = Loadable(
  () => import('@/features/brand/pages/ConfigManagement/ConfigList'),
  'ConfigList',
);

const BrandProfile = Loadable(
  () => import('@/features/brand/pages/Profile/BrandProfile'),
  'BrandProfile',
);

const SunoAI = Loadable(
  () => import('@/features/brand/pages/SunoAIGenerator'),
  'SunoAI',
);

const TokenBilling = Loadable(
  () => import('@/features/brand/pages/TokenBilling'),
  'BrandTokenBilling',
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
    path: 'schedule',
    element: <ScheduleList />,
  },
  {
    path: 'config-management',
    element: <ConfigList />,
  },
  {
    path: 'suno-ai',
    element: <SunoAI />,
  },
  {
    path: 'tokens',
    element: <TokenBilling />,
  },
  {
    path: 'profile/*',
    element: <BrandProfile />,
  },
  {
    path: '*',
    element: (
      <Navigate
        to='/brand/dashboard'
        replace
      />
    ),
  },
];
