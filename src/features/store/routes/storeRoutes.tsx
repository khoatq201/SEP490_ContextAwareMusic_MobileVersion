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

const TrackList = Loadable(
  () => import('@/features/store/pages/TrackManagement/TrackList'),
  'TrackList',
);

const PlaylistList = Loadable(
  () => import('@/features/store/pages/PlaylistManagement/PlaylistList'),
  'PlaylistList',
);

const Dashboard = Loadable(
  () => import('@/features/store/pages/Dashboard'),
  'StoreDashboard',
);

const StoreProfile = Loadable(
  () => import('@/features/store/pages/Profile/StoreProfile'),
  'StoreProfile',
);

/* eslint-disable react-refresh/only-export-components */
const StoreSettings = () => <div>Settings (Coming Soon)</div>;

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
