import type { Rule } from 'antd/es/form';

export const createPlaylistValidation = {
  name: [
    { required: true, message: 'Please enter playlist name!' },
    { max: 255, message: 'Name cannot exceed 255 characters!' },
    { whitespace: true, message: 'Name cannot be only whitespace!' },
  ] as Rule[],

  storeId: [{ required: true, message: 'Please select a store!' }] as Rule[],

  description: [
    { max: 2000, message: 'Description cannot exceed 2000 characters!' },
  ] as Rule[],

  hlsUrl: [
    { max: 500, message: 'HLS URL cannot exceed 500 characters!' },
    {
      pattern: /\.m3u8$/i,
      message: 'HLS URL must end with .m3u8!',
    },
  ] as Rule[],

  totalDurationSeconds: [
    { type: 'number', min: 1, message: 'Duration must be greater than 0!' },
  ] as Rule[],
};

export const updatePlaylistValidation = {
  name: [
    { max: 255, message: 'Name cannot exceed 255 characters!' },
    { whitespace: true, message: 'Name cannot be only whitespace!' },
  ] as Rule[],

  description: [
    { max: 2000, message: 'Description cannot exceed 2000 characters!' },
  ] as Rule[],

  hlsUrl: [
    { max: 500, message: 'HLS URL cannot exceed 500 characters!' },
    {
      pattern: /\.m3u8$/i,
      message: 'HLS URL must end with .m3u8!',
    },
  ] as Rule[],

  totalDurationSeconds: [
    { type: 'number', min: 1, message: 'Duration must be greater than 0!' },
  ] as Rule[],
};
