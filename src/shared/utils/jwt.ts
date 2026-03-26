type JwtPayload = {
  sub: string;
  email: string;
  exp: number;
  iss: string;
  aud: string;
};

/**
 * Decode JWT token
 * Used internally for token expiration check
 */
const decodeJwt = (token: string): JwtPayload | null => {
  try {
    const base64Payload = token.split('.')[1];
    const decoded = JSON.parse(atob(base64Payload));
    return decoded as JwtPayload;
  } catch {
    return null;
  }
};

/**
 * Check if JWT token is expired
 */
export const isTokenExpired = (token: string): boolean => {
  const payload = decodeJwt(token);
  if (!payload) return true;
  return payload.exp * 1000 < Date.now();
};
