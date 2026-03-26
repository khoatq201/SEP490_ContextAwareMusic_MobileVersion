import { Navigate } from 'react-router';

/**
 * Hooks
 */
import { useAuth } from '@/providers';

/**
 * Types
 */
import { RoleEnum } from '@/shared/types';

/**
 * Role to Dashboard Route Mapping
 */
const ROLE_HOME_MAP: Record<RoleEnum, string> = {
  [RoleEnum.SystemAdmin]: '/admin/dashboard',
  [RoleEnum.BrandManager]: '/brand/dashboard',
  [RoleEnum.StoreManager]: '/store/dashboard',
};

export const RedirectIfAuthenticated = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  const { isAuthenticated, user } = useAuth();

  if (isAuthenticated && user) {
    const primaryRole = user.roles[0];
    const redirectTo = ROLE_HOME_MAP[primaryRole] ?? '/unauthorized';

    return (
      <Navigate
        to={redirectTo}
        replace
      />
    );
  }

  return <>{children}</>;
};
