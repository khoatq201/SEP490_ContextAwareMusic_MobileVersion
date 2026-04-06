import {
  ProfileContent,
  ChangePasswordContent,
  SettingsContent,
  ProfileLayout,
} from '@/shared/components/profile';
import { Routes, Route, Navigate } from 'react-router';

const breadcrumbs = [
  { title: 'Dashboard', path: '/brand' },
  { title: 'My Profile' },
];

export const BrandProfile = () => (
  <Routes>
    <Route
      path='/'
      element={
        <ProfileLayout
          breadcrumbs={breadcrumbs}
          baseRoute='/brand/profile'
        />
      }
    >
      <Route
        index
        element={<ProfileContent />}
      />
      <Route
        path='change-password'
        element={<ChangePasswordContent />}
      />
      <Route
        path='settings'
        element={<SettingsContent />}
      />
      <Route
        path='*'
        element={
          <Navigate
            to='/brand/profile'
            replace
          />
        }
      />
    </Route>
  </Routes>
);
