import { Navigate } from 'react-router';

/**
 * Components
 */
import { Loadable } from '@/shared/components/common';

/**
 * Pages
 */
const SpaceList = Loadable(
  () => import('@/features/store/pages/SpaceManagement/SpaceList'),
  'SpaceList',
);

const SpaceSchedulePage = Loadable(
  () => import('@/features/store/pages/SpaceSchedule/SpaceSchedulePage'),
  'SpaceSchedulePage',
);

const TrackList = Loadable(
  () => import('@/features/store/pages/TrackManagement/TrackList'),
  'TrackList',
);

const PlaylistList = Loadable(
  () => import('@/features/store/pages/PlaylistManagement/PlaylistList'),
  'PlaylistList',
);

const ConfigList = Loadable(
  () => import('@/features/store/pages/ConfigManagement/ConfigList'),
  'ConfigList',
);

const Dashboard = Loadable(
  () => import('@/features/store/pages/Dashboard'),
  'StoreDashboard',
);

const StoreProfile = Loadable(
  () => import('@/features/store/pages/Profile/StoreProfile'),
  'StoreProfile',
);

const StoreSettings = Loadable(
  () => import('@/features/store/pages/StoreSettings'),
  'StoreSettings',
);

export const storeRoutes = [
  {
    path: 'dashboard',
    element: <Dashboard />,
  },
  {
    path: 'spaces',
    element: <SpaceList />,
  },
  {
    path: 'spaces/:spaceId/schedule',
    element: <SpaceSchedulePage />,
  },
  {
    path: 'settings',
    element: <StoreSettings />,
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
    path: 'config-management',
    element: <ConfigList />,
  },
  {
    path: 'profile/*',
    element: <StoreProfile />,
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
