import {
  ProfileLayout,
  ProfileContent,
  ChangePasswordContent,
  SettingsContent,
} from '@/shared/components/profile';
import { Routes, Route, Navigate } from 'react-router';

const breadcrumbs = [
  { title: 'Admin', path: '/admin' },
  { title: 'My Profile' },
];

export const AdminProfile = () => (
  <Routes>
    <Route
      path='/'
      element={
        <ProfileLayout
          breadcrumbs={breadcrumbs}
          baseRoute='/admin/profile'
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
            to='/admin/profile'
            replace
          />
        }
      />
    </Route>
  </Routes>
);
