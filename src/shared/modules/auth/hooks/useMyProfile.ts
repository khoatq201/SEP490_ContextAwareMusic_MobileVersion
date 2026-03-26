import { useQuery } from '@tanstack/react-query';

/**
 * Configs
 */
import { STALE_TIME, QUERY_KEYS } from '@/config';

/**
 * Services
 */
import { authService } from '@/shared/modules/auth/services';
import { userService } from '@/shared/modules/users/services';

/**
 * Types
 */
import type { User } from '@/shared/modules/auth/types';

/**
 * Hook to get current user's full profile
 * Combines auth profile (basic info) with user detail (full info including brandName, storeName, etc.)
 *
 * @returns {Object} Query result with UserDetail data
 */
export const useMyProfile = () => {
  // Step 1: Get basic auth profile (userId, roles, etc.)
  const profileQuery = useQuery({
    queryKey: QUERY_KEYS.auth.profile,
    queryFn: async () => {
      const response = await authService.getProfile();

      if (!response.data.isSuccess || !response.data.data) {
        throw new Error(response.data.message || 'Failed to fetch profile');
      }

      const profileData = response.data.data;

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
    staleTime: STALE_TIME.medium,
    retry: false,
  });

  // Step 2: Get full user detail by userId
  const detailQuery = useQuery({
    queryKey: QUERY_KEYS.users.detail(profileQuery.data?.userId),
    queryFn: async () => {
      const response = await userService.getById(profileQuery.data!.userId);

      if (!response.data.isSuccess || !response.data.data) {
        throw new Error(response.data.message || 'Failed to fetch user detail');
      }

      return response.data.data;
    },
    enabled: !!profileQuery.data?.userId,
    staleTime: STALE_TIME.medium,
    retry: false,
  });

  return {
    data: detailQuery.data,
    isLoading: profileQuery.isLoading || detailQuery.isLoading,
    error: profileQuery.error ?? detailQuery.error,
  };
};
