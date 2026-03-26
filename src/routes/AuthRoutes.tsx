/**
 * Components
 */
import { Loadable, RedirectIfAuthenticated } from '@/shared/components';

/**
 * Pages
 */
const LoginPage = Loadable(
  () => import('@/features/auth/pages/LoginPage'),
  'LoginPage',
);

export const AuthRoutes = {
  path: '/',
  children: [
    {
      path: 'login',
      element: (
        <RedirectIfAuthenticated>
          <LoginPage />
        </RedirectIfAuthenticated>
      ),
    },
  ],
};
