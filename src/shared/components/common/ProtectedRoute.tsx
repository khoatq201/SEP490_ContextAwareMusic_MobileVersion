import { Navigate } from 'react-router';

/**
 * Providers
 */
import { useAuth } from '@/providers';

/**
 * Types
 */
import type { RoleEnum } from '@/shared/types';

type ProtectedRouteProps = {
  children: React.ReactNode;
  allowedRoles: RoleEnum[];
};

export const ProtectedRoute = ({
  children,
  allowedRoles,
}: ProtectedRouteProps) => {
  const { user, isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return (
      <Navigate
        to='/login'
        replace
      />
    );
  }

  const hasPermission = user?.roles.some((role) => allowedRoles.includes(role));

  if (!hasPermission) {
    return (
      <Navigate
        to='/unauthorized'
        replace
      />
    );
  }

  return <>{children}</>;
};
