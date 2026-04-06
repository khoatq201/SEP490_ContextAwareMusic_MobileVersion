import type { Result, RoleEnum } from '@/shared/types';

/**
 * Request Payloads
 */
export type LoginPayload = {
  email: string;
  password: string;
  rememberMe: boolean;
};

export type ChangePasswordRequest = {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
};

/**
 * Response Data Types (nested in Result<T>)
 */
export type LoginData = {
  accessToken: string;
  expiresAt: string;
  roles: number[];
};

export type ProfileData = {
  email: string;
  userId: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  avatarUrl?: string;
  brandId?: string | null;
  storeId?: string | null;
  roles: number[];
};

export type RefreshTokenData = {
  accessToken: string;
  expiresAt: string;
  // refreshToken is in HttpOnly cookie, not in response
};

/**
 * Response Types (using common Result<T>)
 */
export type LoginResponse = Result<LoginData>;
export type ProfileResponse = Result<ProfileData>;
export type RefreshTokenResponse = Result<RefreshTokenData>;

/**
 * Domain Types
 */
export interface User {
  email: string;
  userId: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string | null;
  avatarUrl?: string | null;
  roles: RoleEnum[];
  brandId?: string | null;
  storeId?: string | null;
}

/**
 * Context Types
 */
export type AuthContextType = {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  login: (payload: LoginPayload) => Promise<void>;
  logout: () => void;
};
