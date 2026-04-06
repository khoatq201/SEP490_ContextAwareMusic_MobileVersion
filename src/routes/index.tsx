import { createBrowserRouter, Navigate } from 'react-router';
import { AuthRoutes } from './AuthRoutes';
import { MainRoutes } from './MainRoutes';
import { ErrorRoutes } from './ErrorRoutes';

export const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <Navigate
        to='/login'
        replace
      />
    ),
  },
  AuthRoutes,
  ...MainRoutes,
  ...ErrorRoutes,
]);
