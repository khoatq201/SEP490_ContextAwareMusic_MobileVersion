export type Track = {
  id: string;
  title: string;
  artist: string;
  album: string;
  albumArt?: string;
  duration: number; // seconds
};

export type PlayerState = {
  isPlaying: boolean;
  isExpanded: boolean;
  isShuffle: boolean;
  currentTrack: Track | null;
  volume: number; // 0-100
  currentTime: number; // seconds
  duration: number; // seconds
};

export type PlayerActions = {
  play: () => void;
  pause: () => void;
  togglePlay: () => void;
  toggleShuffle: () => void;
  toggleExpanded: () => void;
  setVolume: (volume: number) => void;
  setCurrentTime: (time: number) => void;
  setTrack: (track: Track) => void;
  nextTrack: () => void;
};
