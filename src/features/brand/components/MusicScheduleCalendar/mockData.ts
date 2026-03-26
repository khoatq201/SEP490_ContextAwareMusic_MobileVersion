import type { MusicScheduleEvent } from '@/features/brand/types/scheduleTypes';

export const mockEvents: MusicScheduleEvent[] = [
  {
    id: '1',
    title: 'Morning Jazz Playlist',
    start: '2026-02-28T08:00:00',
    end: '2026-02-28T12:00:00',
    backgroundColor: '#52c41a',
    borderColor: '#52c41a',
    extendedProps: {
      playlist: 'Morning Vibes',
      mood: 'Relaxing',
      genre: 'Jazz',
      autoMode: true,
    },
  },
  {
    id: '2',
    title: 'Lunch Lounge Mix',
    start: '2026-02-26T12:00:00',
    end: '2026-02-26T14:00:00',
    backgroundColor: '#1677ff',
    borderColor: '#1677ff',
    extendedProps: {
      playlist: 'Lunch Hour',
      mood: 'Upbeat',
      genre: 'Pop',
      autoMode: false,
    },
  },
  {
    id: '3',
    title: 'Afternoon Classical',
    start: '2026-02-27T14:00:00',
    end: '2026-02-27T17:00:00',
    backgroundColor: '#722ed1',
    borderColor: '#722ed1',
    extendedProps: {
      playlist: 'Classical Afternoon',
      mood: 'Calm',
      genre: 'Classical',
      autoMode: true,
    },
  },
  {
    id: '4',
    title: 'Evening Energy',
    start: '2026-02-28T17:00:00',
    end: '2026-02-28T20:00:00',
    backgroundColor: '#fa8c16',
    borderColor: '#fa8c16',
    extendedProps: {
      playlist: 'High Energy Mix',
      mood: 'Energetic',
      genre: 'Electronic',
      autoMode: false,
    },
  },
  {
    id: '5',
    title: 'Weekend Chill',
    start: '2026-02-29T10:00:00',
    end: '2026-02-29T18:00:00',
    backgroundColor: '#13c2c2',
    borderColor: '#13c2c2',
    extendedProps: {
      playlist: 'Weekend Vibes',
      mood: 'Chill',
      genre: 'Indie',
      autoMode: true,
    },
  },
];
