
export const PLAYLIST_TYPE_LABELS: Record<number, string> = {
  0: 'Static',
  1: 'Dynamic',
};

export const PLAYLIST_TYPE_COLORS: Record<number, string> = {
  0: 'blue',
  1: 'purple',
};

export const PLAYLIST_TYPE_OPTIONS = [
  { label: 'Static Playlist', value: 0 },
  { label: 'Dynamic Playlist', value: 1 },
];

export const DEFAULT_PLAYLIST_FILTER = {
  page: 1,
  pageSize: 10,
  sortBy: 'createdAt',
  isAscending: false,
};
