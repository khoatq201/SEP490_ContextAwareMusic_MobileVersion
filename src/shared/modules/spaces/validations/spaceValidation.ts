import type { Rule } from 'antd/es/form';

/**
 * Validation rules for Create Space form
 * Based on API_Spaces.md §4.7
 */
export const createSpaceValidation = {
  name: [
    { required: true, message: 'Please enter space name!' },
    {
      max: 200,
      message: 'Space name cannot exceed 200 characters!',
    },
    {
      whitespace: true,
      message: 'Space name cannot be only whitespace!',
    },
  ] as Rule[],

  type: [{ required: true, message: 'Please select space type!' }] as Rule[],

  description: [
    {
      max: 500,
      message: 'Description cannot exceed 500 characters!',
    },
  ] as Rule[],

  maxOccupancy: [
    {
      type: 'number' as const,
      min: 1,
      message: 'Max occupancy must be greater than 0!',
    },
  ] as Rule[],

  criticalQueueThreshold: [
    {
      type: 'number' as const,
      min: 1,
      message: 'Critical queue threshold must be greater than 0!',
    },
  ] as Rule[],
};

/**
 * Validation rules for Update Space form
 * All fields optional (partial update)
 */
export const updateSpaceValidation = {
  name: [
    {
      max: 200,
      message: 'Space name cannot exceed 200 characters!',
    },
    {
      whitespace: true,
      message: 'Space name cannot be only whitespace!',
    },
  ] as Rule[],

  description: [
    {
      max: 500,
      message: 'Description cannot exceed 500 characters!',
    },
  ] as Rule[],

  maxOccupancy: [
    {
      type: 'number' as const,
      min: 1,
      message: 'Max occupancy must be greater than 0!',
    },
  ] as Rule[],

  criticalQueueThreshold: [
    {
      type: 'number' as const,
      min: 1,
      message: 'Critical queue threshold must be greater than 0!',
    },
  ] as Rule[],
};
