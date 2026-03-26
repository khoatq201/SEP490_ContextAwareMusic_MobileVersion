import { createContext, useState } from 'react';
import { useQueryClient, useMutation } from '@tanstack/react-query';
import { message } from 'antd';

/**
 * Configs
 */
import { saveTokens, clearTokens, getAccessToken } from '@/config';

/**
 * Utils
 */
import { isTokenExpired } from '@/shared/utils';

/**
 * Hooks
 */
import { useProfile } from '@/shared/modules/auth/hooks';

/**
 * Services
 */
import { authService } from '@/shared/modules/auth/services';

/**
 * Types
 */
import type { UseMutationResult } from '@tanstack/react-query';
import type { LoginPayload, User } from '@/shared/modules/auth/types';

type AuthContextType = {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  login: UseMutationResult<void, Error, LoginPayload>;
  logout: UseMutationResult<void, Error, void>;
};

/* eslint-disable react-refresh/only-export-components */
export const AuthContext = createContext<AuthContextType | undefined>(
  undefined,
);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const queryClient = useQueryClient();
  const [accessToken, setAccessToken] = useState<string | null>(() => {
    const token = getAccessToken();
    if (token && !isTokenExpired(token)) {
      return token;
    }
    if (token) {
      clearTokens();
    }
    return null;
  });

  const { data: user, isLoading: isLoadingProfile } = useProfile(!!accessToken);

  const loginMutation = useMutation({
    mutationFn: async (payload: LoginPayload) => {
      const response = await authService.login(payload);

      // Type-safe access to nested data
      if (!response.data.isSuccess || !response.data.data) {
        throw new Error(response.data.message || 'Login failed');
      }

      const { accessToken: token } = response.data.data;

      saveTokens(token, payload.rememberMe);
      setAccessToken(token);
      await queryClient.invalidateQueries({ queryKey: ['profile'] });
    },
    onSuccess: () => {
      message.success('Login successful!');
    },
  });

  const logoutMutation = useMutation({
    mutationFn: async () => {
      try {
        await authService.logout();
      } catch (error) {
        console.error('Logout API failed:', error);
      }
    },
    onSuccess: () => {
      clearTokens();
      setAccessToken(null);
      // queryClient.setQueryData(['profile'], null);
      queryClient.clear();
    },
  });

  if (accessToken && isLoadingProfile) {
    return null;
  }

  return (
    <AuthContext.Provider
      value={{
        user: user ?? null,
        accessToken,
        isAuthenticated: !!user,
        login: loginMutation,
        logout: logoutMutation,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
