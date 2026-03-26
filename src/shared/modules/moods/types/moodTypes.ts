import type { EntityStatusEnum } from '@/shared/types/commonTypes';

/**
 * Mood Type Enum (from API_Moods.md §3)
 */
export enum MoodType {
  Calm = 1,
  Energetic = 2,
  Focus = 3,
  Social = 4,
  Romantic = 5,
  Uplifting = 6,
}

/**
 * Mood List Item DTO (from API_Moods.md §2.1)
 */
export interface MoodListItem {
  id: string;
  moodType?: MoodType;
  name: string;
  minBpm?: number;
  maxBpm?: number;
  genre?: string;
  energyLevel?: number;
  priority?: number;
  status: EntityStatusEnum;
  createdAt: string;
  updatedAt?: string;
  createdBy?: string;
  updatedBy?: string;
}

/**
 * Mood Option for Select component
 */
export interface MoodOption {
  label: string;
  value: string;
  moodType?: MoodType;
  energyLevel?: number;
}
