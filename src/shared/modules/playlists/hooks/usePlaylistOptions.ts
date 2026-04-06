import { useQuery } from '@tanstack/react-query';
import { playlistService } from '@/shared/modules/playlists/services';
import { STALE_TIME } from '@/config';

/**
 * Hook to get playlist options for Select component
 * Returns array of { label, value } for Ant Design Select
 */
export const usePlaylistOptions = () => {
  return useQuery({
    queryKey: ['playlists', 'options'],
    queryFn: async () => {
      const response = await playlistService.getList({
        page: 1,
        pageSize: 100,
        status: 1, // Only active playlists
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
