import { Navigate, useSearchParams } from 'react-router';

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

const isSafeInternalPath = (path: string) =>
  path.startsWith('/') && !path.startsWith('//') && !path.includes('://');

export const RedirectIfAuthenticated = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  const { isAuthenticated, user } = useAuth();
  const [searchParams] = useSearchParams();

  if (isAuthenticated && user) {
    const next = searchParams.get('redirect');
    if (next && isSafeInternalPath(next)) {
      return (
        <Navigate
          to={next}
          replace
        />
      );
    }

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
