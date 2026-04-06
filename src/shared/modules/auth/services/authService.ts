import { api } from '@/config';

/**
 * Types
 */
import type {
  LoginPayload,
  LoginResponse,
  ProfileResponse,
  RefreshTokenResponse,
  ChangePasswordRequest,
} from '../types';
import type { Result } from '@/shared/types';

const AUTH_ENDPOINTS = {
  login: '/api/auth/login',
  logout: '/api/auth/logout',
  profile: '/api/auth/profile',
  refreshToken: '/api/auth/refresh-token',
  changePassword: '/api/auth/change-password',
} as const;

export const authService = {
  // POST /api/auth/login
  login: (payload: LoginPayload) =>
    api.post<LoginResponse>(AUTH_ENDPOINTS.login, payload),

  // POST /api/auth/logout
  logout: () => api.post<Result>(AUTH_ENDPOINTS.logout),

  // GET /api/auth/profile
  getProfile: () => api.get<ProfileResponse>(AUTH_ENDPOINTS.profile),

  // POST /api/auth/refresh-token
  refreshToken: () =>
    api.post<RefreshTokenResponse>(AUTH_ENDPOINTS.refreshToken),

  // POST /api/auth/change-password
  changePassword: (data: ChangePasswordRequest) =>
    api.post<Result>(AUTH_ENDPOINTS.changePassword, data),
};
