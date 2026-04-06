import type { Rule } from 'antd/es/form';

export const spaceValidation = {
  space_name: [
    { required: true, message: 'Please input space name!' },
    { min: 2, message: 'Space name must be at least 2 characters!' },
    { max: 100, message: 'Space name must not exceed 100 characters!' },
  ] as Rule[],
  space_code: [
    { required: true, message: 'Please input space code!' },
    {
      pattern: /^[A-Z0-9_]+$/,
      message:
        'Space code must be uppercase letters, numbers, and underscores only!',
    },
    { max: 50, message: 'Space code must not exceed 50 characters!' },
  ] as Rule[],
  description: [
    { max: 255, message: 'Description must not exceed 255 characters!' },
  ] as Rule[],
  device_id: [] as Rule[],
};
