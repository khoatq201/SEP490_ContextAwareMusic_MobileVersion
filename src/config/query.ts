/**
 * Stale Times (milliseconds)
 * Data is considered fresh for this duration
 */
export const STALE_TIME = {
  instant: 0, // Always refetch (real-time data)
  short: 30 * 1000, // 30 seconds - frequently changing data
  medium: 5 * 60 * 1000, // 5 minutes - default for most queries
  long: 15 * 60 * 1000, // 15 minutes - stable data
  veryLong: 60 * 60 * 1000, // 1 hour - rarely changing data
} as const;

/**
 * Query Keys
 * Centralized query key management for React Query
 */
export const QUERY_KEYS = {
  // Auth
  auth: {
    profile: ['auth', 'profile'] as const,
  },
  // Accounts (Brand Managers)
  accounts: {
    all: ['accounts'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['accounts', 'list', filter] as const,
    detail: (id?: string) => ['accounts', 'detail', id] as const,
  },
  // Users/Accounts
  users: {
    all: ['users'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['users', 'list', filter] as const,
    detail: (id?: string) => ['users', 'detail', id] as const,
  },
  // Brands
  brands: {
    all: ['brands'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['brands', 'list', filter] as const,
    detail: (id?: string) => ['brands', 'detail', id] as const,
  },
  // Stores
  stores: {
    all: ['stores'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['stores', 'list', filter] as const,
    detail: (id?: string) => ['stores', 'detail', id] as const,
  },
  // Spaces
  spaces: {
    all: ['spaces'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['spaces', 'list', filter] as const,
    detail: (id?: string) => ['spaces', 'detail', id] as const,
  },
  // Tracks
  tracks: {
    all: ['tracks'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['tracks', 'list', filter] as const,
    detail: (id?: string) => ['tracks', 'detail', id] as const,
  },
  // Playlists
  playlists: {
    all: ['playlists'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['playlists', 'list', filter] as const,
    detail: (id?: string) => ['playlists', 'detail', id] as const,
  },
  // Moods
  moods: {
    all: ['moods'] as const,
    list: (filter?: Record<string, unknown>) =>
      ['moods', 'list', filter] as const,
    detail: (id?: string) => ['moods', 'detail', id] as const,
  },
  // CAMS
  cams: {
    all: ['cams'] as const, // NEW (2026-03-23): For queue management invalidation
    spaceState: (spaceId?: string) => ['cams-space-state', spaceId] as const,
    pairDeviceInfo: (spaceId?: string) => ['pairDeviceInfo', spaceId] as const,
    queue: (spaceId: string) => ['cams', 'queue', spaceId] as const, // NEW (2026-03-23): Queue management
  },
} as const;
