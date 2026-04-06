import type { BaseResponse } from '@/shared/types/commonTypes';

/**
 * Suno Generation Status Enum (from backend)
 * See: docs/cams/FE_SUNO_IMPLEMENTATION_GUIDE.md §2
 */
export enum SunoGenerationStatus {
  Queued = 0, // Job queued, waiting to start
  Generating = 1, // AI is generating music
  Completed = 2, // Generation completed successfully
  Failed = 3, // Generation failed
  Cancelled = 4, // Generation cancelled by user
}

export enum AiGenerationMode {
  Suno = 1,
  BrandModel = 2,
}

/**
 * CAMS fuzzy snapshot returned with Suno config (same data source as brand detail music policy).
 */
export interface SunoBrandMusicProfileDto {
  fuzzyProfileTemplate?: string | null;
  storeOverrideLevel?: number | null;
  chillBpmMin?: number | null;
  chillBpmMax?: number | null;
  focusBpmMin?: number | null;
  focusBpmMax?: number | null;
  energeticBpmMin?: number | null;
  energeticBpmMax?: number | null;
  pressureLowMax?: number | null;
  pressureCriticalMin?: number | null;
  stressComfortableMax?: number | null;
  stressHighMin?: number | null;
  densitySparseMax?: number | null;
  densityCrowdedMin?: number | null;
  spaceCapacity?: number | null;
  defaultDensityRatioWhenNull?: number | null;
}

/**
 * Suno Config Response (from backend)
 * GET /api/cms/suno/config
 */
export interface SunoConfigResponse {
  brandId: string;
  sunoPromptTemplate: string | null;
  sunoDefaultPlaylistId: string | null;
  aiGenerationMode: AiGenerationMode;
  /** Present when brand has CAMS music policy (null if not configured yet). */
  brandMusicProfile?: SunoBrandMusicProfileDto | null;
}

/**
 * Suno Config Update Request
 * PUT /api/cms/suno/config
 */
export interface SunoConfigUpdateRequest {
  sunoPromptTemplate?: string | null;
  sunoDefaultPlaylistId?: string | null;
  aiGenerationMode?: AiGenerationMode;
}

/**
 * Suno Generation Create Request
 * POST /api/cms/suno/generations
 */
export interface SunoGenerationCreateRequest {
  prompt?: string | null;
  style?: string | null;
  title?: string | null;
  artist?: string | null;
  duration?: number | null;
  customMode?: boolean;
  lyrics?: string | null;
  instrumental?: boolean;
  callbackUrl?: string | null;
  moodId?: string | null;
  targetPlaylistId?: string | null;
  autoAddToTargetPlaylist?: boolean;
}

/**
 * Suno Generation Realtime DTO (SignalR event payload)
 * Event: SunoGenerationStatusChanged
 */
export interface SunoGenerationRealtimeDto {
  id: string;
  brandId: string;
  generationStatus: SunoGenerationStatus;
  progressPercent: number;
  errorMessage: string | null;
  generatedTrackId: string | null;
}

/**
 * Suno Generation Status DTO (full detail)
 * GET /api/cms/suno/generations/{id}
 * POST /api/cms/suno/generations (response)
 */
export interface SunoGenerationStatusDto
  extends SunoGenerationRealtimeDto, BaseResponse {
  generationMode: AiGenerationMode;
  prompt: string | null;
  style: string | null;
  title: string | null;
  artist: string | null;
  duration: number | null;
  customMode: boolean;
  lyrics: string | null;
  instrumental: boolean;
  callbackUrl: string | null;
  externalTaskId: string | null;
  outputAudioUrl: string | null;
  outputStreamUrl: string | null;
  targetPlaylistId: string | null;
  completedAtUtc: string | null;
  lastPolledAtUtc: string | null;
}

/**
 * Local UI state for generation item
 */
export type SunoGenerationUIState =
  | 'idle'
  | 'queued'
  | 'generating'
  | 'completed'
  | 'failed'
  | 'cancelled';

/**
 * Map backend status to UI state
 */
export const mapSunoStatusToUIState = (
  status: SunoGenerationStatus,
): SunoGenerationUIState => {
  switch (status) {
    case SunoGenerationStatus.Queued:
      return 'queued';
    case SunoGenerationStatus.Generating:
      return 'generating';
    case SunoGenerationStatus.Completed:
      return 'completed';
    case SunoGenerationStatus.Failed:
      return 'failed';
    case SunoGenerationStatus.Cancelled:
      return 'cancelled';
    default:
      return 'idle';
  }
};
