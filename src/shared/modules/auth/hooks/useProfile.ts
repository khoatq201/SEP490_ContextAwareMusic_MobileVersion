import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { authService } from '@/shared/modules/auth/services';

/**
 * Types
 */
import type { User } from '@/shared/modules/auth/types';

/**
 * Configs
 */
import { STALE_TIME, QUERY_KEYS } from '@/config';

/**
 * Hook to get current user's basic profile
 * Returns User type with basic auth information
 */
export const useProfile = (enabled = true) => {
  return useQuery({
    queryKey: QUERY_KEYS.auth.profile,
    queryFn: async () => {
      const response = await authService.getProfile();

      // Type-safe data extraction
      if (!response.data.isSuccess || !response.data.data) {
        throw new Error(response.data.message || 'Failed to fetch profile');
      }

      const profileData = response.data.data;

      // Transform to User domain type
      const user: User = {
        userId: profileData.userId,
        email: profileData.email,
        firstName: profileData.firstName,
        lastName: profileData.lastName,
        phoneNumber: profileData.phoneNumber,
        avatarUrl: profileData.avatarUrl,
        roles: profileData.roles,
        brandId: profileData.brandId,
        storeId: profileData.storeId,
      };

      return user;
    },
    enabled,
    staleTime: STALE_TIME.medium,
    retry: false,
  });
};
