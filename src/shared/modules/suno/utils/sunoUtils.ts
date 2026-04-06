import { SunoGenerationStatus } from '../types';

/**
 * Get status badge color for Ant Design Badge component
 */
export const getSunoStatusBadgeColor = (
  status: SunoGenerationStatus,
): 'success' | 'processing' | 'error' | 'default' | 'warning' => {
  switch (status) {
    case SunoGenerationStatus.Completed:
      return 'success';
    case SunoGenerationStatus.Queued:
    case SunoGenerationStatus.Generating:
      return 'processing';
    case SunoGenerationStatus.Failed:
      return 'error';
    case SunoGenerationStatus.Cancelled:
      return 'default';
    default:
      return 'default';
  }
};

/**
 * Get status display text
 */
export const getSunoStatusText = (status: SunoGenerationStatus): string => {
  switch (status) {
    case SunoGenerationStatus.Queued:
      return 'Queued';
    case SunoGenerationStatus.Generating:
      return 'Generating...';
    case SunoGenerationStatus.Completed:
      return 'Completed';
    case SunoGenerationStatus.Failed:
      return 'Failed';
    case SunoGenerationStatus.Cancelled:
      return 'Cancelled';
    default:
      return 'Unknown';
  }
};

/**
 * Check if generation is in progress
 */
export const isGenerationInProgress = (
  status: SunoGenerationStatus,
): boolean => {
  return (
    status === SunoGenerationStatus.Queued ||
    status === SunoGenerationStatus.Generating
  );
};

/**
 * Check if generation is completed (success or failure)
 */
export const isGenerationFinished = (status: SunoGenerationStatus): boolean => {
  return (
    status === SunoGenerationStatus.Completed ||
    status === SunoGenerationStatus.Failed ||
    status === SunoGenerationStatus.Cancelled
  );
};

/**
 * Format progress percent for display
 */
export const formatProgress = (percent: number): string => {
  const clamped = Math.max(0, Math.min(100, percent));
  return `${Math.round(clamped)}%`;
};

/**
 * Build prompt from template
 * Replace placeholders like {mood}, {genre}, etc.
 */
export const buildPromptFromTemplate = (
  template: string,
  variables: Record<string, string>,
): string => {
  let result = template;
  const escapeRegExp = (value: string): string =>
    value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  Object.entries(variables).forEach(([key, value]) => {
    const placeholder = `{${key}}`;
    result = result.replace(new RegExp(escapeRegExp(placeholder), 'g'), value);
  });
  return result;
};
