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
