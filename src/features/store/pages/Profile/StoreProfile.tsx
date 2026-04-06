import {
  ProfileContent,
  ChangePasswordContent,
  SettingsContent,
  ProfileLayout,
} from '@/shared/components/profile';
import { Routes, Route, Navigate } from 'react-router';

const breadcrumbs = [
  { title: 'Dashboard', path: '/store' },
  { title: 'My Profile' },
];

export const StoreProfile = () => (
  <Routes>
    <Route
      path='/'
      element={
        <ProfileLayout
          breadcrumbs={breadcrumbs}
          baseRoute='/store/profile'
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
            to='/store/profile'
            replace
          />
        }
      />
    </Route>
  </Routes>
);
