import { useQuery } from '@tanstack/react-query';

/**
 * Services
 */
import { playlistService } from '@/shared/modules/playlists/services';

/**
 * Types
 */
import type { PlaylistFilter } from '@/shared/modules/playlists/types';
import { STALE_TIME } from '@/config';

export const usePlaylists = (filter: PlaylistFilter = {}) => {
  return useQuery({
    queryKey: ['playlists', filter],
    queryFn: async () => {
      const response = await playlistService.getList(filter);
      return response.data;
    },
    staleTime: STALE_TIME.medium,
  });
};
