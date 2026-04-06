import { useQuery } from '@tanstack/react-query';

import { playlistService } from '@/shared/modules/playlists/services';
import { STALE_TIME } from '@/config';

/**
 * Playlist options for a single store (allowed-playlist pickers).
 */
export const usePlaylistOptionsForStore = (storeId: string | undefined) => {
  return useQuery({
    queryKey: ['playlists', 'options', 'store', storeId],
    enabled: !!storeId,
    queryFn: async () => {
      const response = await playlistService.getList({
        page: 1,
        pageSize: 100,
        status: 1,
        storeId: storeId!,
      });

      if (!response.data?.items) {
        return [];
      }

      return response.data.items.map((playlist) => ({
        label: playlist.name,
        value: playlist.id,
      }));
    },
    staleTime: STALE_TIME.medium,
  });
};
