import { create } from 'zustand';
import type { PlayerActions, PlayerState, Track } from '../types/playerTypes';

const mockTracks: Track[] = [
  {
    id: '1',
    title: 'Campfire',
    artist: 'Henrik Lindstrand',
    album: 'Modern Classical',
    albumArt: 'https://picsum.photos/seed/campfire/200/200',
    duration: 175, // 2:55
  },
  {
    id: '2',
    title: 'Afternoon Jazz',
    artist: 'The Smooth Trio',
    album: 'Afternoon Tea Jazz',
    albumArt: 'https://picsum.photos/seed/jazz/200/200',
    duration: 210,
  },
  {
    id: '3',
    title: 'Morning Breeze',
    artist: 'Nature Sounds',
    album: 'Relaxing Piano',
    albumArt: 'https://picsum.photos/seed/breeze/200/200',
    duration: 240,
  },
];

type PlayerStore = PlayerState & PlayerActions;

export const usePlayerStore = create<PlayerStore>((set, get) => ({
  // State
  isPlaying: false,
  isExpanded: false,
  isShuffle: false,
  currentTrack: mockTracks[0],
  volume: 75,
  currentTime: 82, // 1:22
  duration: mockTracks[0].duration,

  // Actions
  play: () => set({ isPlaying: true }),
  pause: () => set({ isPlaying: false }),
  togglePlay: () => set((s) => ({ isPlaying: !s.isPlaying })),
  toggleShuffle: () => set((s) => ({ isShuffle: !s.isShuffle })),
  toggleExpanded: () => set((s) => ({ isExpanded: !s.isExpanded })),
  setVolume: (volume) => set({ volume }),
  setCurrentTime: (currentTime) => set({ currentTime }),
  setTrack: (track) =>
    set({ currentTrack: track, currentTime: 0, duration: track.duration }),
  nextTrack: () => {
    const { currentTrack, isShuffle } = get();
    const idx = mockTracks.findIndex((t) => t.id === currentTrack?.id);
    let nextIdx: number;
    if (isShuffle) {
      nextIdx = Math.floor(Math.random() * mockTracks.length);
    } else {
      nextIdx = (idx + 1) % mockTracks.length;
    }
    const next = mockTracks[nextIdx];
    set({ currentTrack: next, currentTime: 0, duration: next.duration });
  },
}));
