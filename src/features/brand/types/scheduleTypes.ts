export type MusicScheduleEvent = {
  id: string;
  title: string; // Tên playlist/bài hát
  start: string; // ISO datetime
  end: string;
  backgroundColor?: string;
  borderColor?: string;
  extendedProps?: {
    playlist?: string;
    mood?: string;
    genre?: string;
    autoMode?: boolean;
  };
};

export type CreateBrandScheduleSourceRequest = {
  title: string;
  subtitle?: string;
  description?: string;
  isTemplate: boolean;
};

export type UpdateBrandScheduleSourceRequest = {
  title: string;
  subtitle?: string;
  description?: string;
};

export type UpsertBrandScheduleSlotRequest = {
  daysOfWeek: number[];
  startTime: string;
  endTime: string;
  playlistId: string;
};
