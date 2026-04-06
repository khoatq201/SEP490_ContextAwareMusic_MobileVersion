import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { fuzzyProfileTemplateService } from '@/features/admin/services';
import { QUERY_KEYS, STALE_TIME } from '@/config';

export const useFuzzyProfileTemplatesManage = (
  page: number,
  pageSize: number,
) => {
  return useQuery({
    queryKey: QUERY_KEYS.fuzzyProfileTemplates.manage(page, pageSize),
    queryFn: async () => {
      const res = await fuzzyProfileTemplateService.getManagePaged(
        page,
        pageSize,
      );
      return res.data;
    },
    staleTime: STALE_TIME.short,
  });
};

export const useFuzzyProfileTemplateDetail = (
  id: string | undefined,
  enabled: boolean,
) => {
  return useQuery({
    queryKey: QUERY_KEYS.fuzzyProfileTemplates.detail(id),
    queryFn: async () => {
      const res = await fuzzyProfileTemplateService.getById(id!);
      return res.data.data;
    },
    enabled: !!id && enabled,
    staleTime: STALE_TIME.short,
  });
};

export const useCreateFuzzyProfileTemplate = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: Record<string, unknown>) =>
      fuzzyProfileTemplateService.create(body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['fuzzy-profile-templates'] });
    },
  });
};

export const useUpdateFuzzyProfileTemplate = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: Record<string, unknown> }) =>
      fuzzyProfileTemplateService.update(id, body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['fuzzy-profile-templates'] });
    },
  });
};

export const useDeleteFuzzyProfileTemplate = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => fuzzyProfileTemplateService.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['fuzzy-profile-templates'] });
    },
  });
};
