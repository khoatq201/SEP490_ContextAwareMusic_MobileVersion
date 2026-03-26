import type { Rule } from 'antd/es/form';

export const createTrackValidation = {
  title: [
    { required: true, message: 'Please enter track title!' },
    { max: 255, message: 'Title cannot exceed 255 characters!' },
    { whitespace: true, message: 'Title cannot be only whitespace!' },
  ] as Rule[],

  artist: [
    { max: 255, message: 'Artist name cannot exceed 255 characters!' },
  ] as Rule[],

  genre: [
    { max: 100, message: 'Genre cannot exceed 100 characters!' },
  ] as Rule[],

  durationSec: [
    {
      type: 'number',
      min: 1,
      message: 'Duration must be greater than 0 seconds!',
    },
  ] as Rule[],

  bpm: [
    {
      type: 'number',
      min: 20,
      max: 300,
      message: 'BPM must be between 20-300!',
    },
  ] as Rule[],

  energyLevel: [
    {
      type: 'number',
      min: 0,
      max: 1,
      message: 'Energy level must be between 0.0-1.0!',
    },
  ] as Rule[],

  valence: [
    {
      type: 'number',
      min: 0,
      max: 1,
      message: 'Valence must be between 0.0-1.0!',
    },
  ] as Rule[],

  audioFile: [
    { required: true, message: 'Please upload audio file!' },
  ] as Rule[],

  moodId: [] as Rule[],

  coverImageFile: [] as Rule[],
};

export const updateTrackValidation = {
  title: [
    { max: 255, message: 'Title cannot exceed 255 characters!' },
    { whitespace: true, message: 'Title cannot be only whitespace!' },
  ] as Rule[],

  artist: [
    { max: 255, message: 'Artist name cannot exceed 255 characters!' },
  ] as Rule[],

  genre: [
    { max: 100, message: 'Genre cannot exceed 100 characters!' },
  ] as Rule[],

  durationSec: [
    { type: 'number', min: 1, message: 'Duration must be greater than 0!' },
  ] as Rule[],

  bpm: [
    {
      type: 'number',
      min: 20,
      max: 300,
      message: 'BPM must be between 20-300!',
    },
  ] as Rule[],

  energyLevel: [
    {
      type: 'number',
      min: 0,
      max: 1,
      message: 'Energy level must be between 0.0-1.0!',
    },
  ] as Rule[],

  valence: [
    {
      type: 'number',
      min: 0,
      max: 1,
      message: 'Valence must be between 0.0-1.0!',
    },
  ] as Rule[],
};
