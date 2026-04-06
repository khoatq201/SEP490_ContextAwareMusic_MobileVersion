import { useQuery } from '@tanstack/react-query';

import { fuzzyProfileTemplateService } from '@/features/admin/services';
import { QUERY_KEYS, STALE_TIME } from '@/config';

export const useFuzzyProfileTemplateOptions = (enabled = true) => {
  return useQuery({
    queryKey: QUERY_KEYS.fuzzyProfileTemplates.forSelect,
    queryFn: async () => {
      const res = await fuzzyProfileTemplateService.getForSelect();
      return res.data.data ?? [];
    },
    enabled,
    staleTime: STALE_TIME.long,
  });
};
