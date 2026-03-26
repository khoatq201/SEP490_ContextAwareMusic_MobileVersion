import type { Rule } from 'antd/es/form';

export const createStaffValidation = {
  firstName: [
    { required: true, message: 'Please enter first name!' },
    { max: 100, message: 'First name must not exceed 100 characters!' },
  ] as Rule[],
  lastName: [
    { required: true, message: 'Please enter last name!' },
    { max: 100, message: 'Last name must not exceed 100 characters!' },
  ] as Rule[],
  email: [
    { required: true, message: 'Please enter email!' },
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],
  password: [
    { required: true, message: 'Please enter password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],
  phoneNumber: [
    {
      pattern:
        /^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$/,
      message: 'Please enter a valid phone number! (e.g., +84901234567)',
    },
  ] as Rule[],
  storeId: [
    {
      required: true,
      message: 'Please assign a store to this staff member!',
    },
  ] as Rule[],
  avatar: [
    {
      validator: (_: any, value: File) => {
        if (!value) return Promise.resolve();

        const allowedTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
          'image/webp',
          'image/bmp',
          'image/svg+xml',
        ];
        if (!allowedTypes.includes(value.type)) {
          return Promise.reject(
            'File must be an image (jpg, jpeg, png, gif, webp, bmp, svg)',
          );
        }

        const maxSize = 5 * 1024 * 1024; // 5MB
        if (value.size > maxSize) {
          return Promise.reject('File size must not exceed 5MB');
        }

        return Promise.resolve();
      },
    },
  ] as Rule[],
};

export const updateStaffValidation = {
  firstName: [
    { max: 100, message: 'First name must not exceed 100 characters!' },
  ] as Rule[],
  lastName: [
    { max: 100, message: 'Last name must not exceed 100 characters!' },
  ] as Rule[],
  email: [{ type: 'email', message: 'Please enter a valid email!' }] as Rule[],
  phoneNumber: [
    {
      pattern:
        /^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$/,
      message: 'Please enter a valid phone number!',
    },
  ] as Rule[],
  avatar: createStaffValidation.avatar,
};

export const resetPasswordValidation = {
  newPassword: [
    { required: true, message: 'Please enter new password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],
};

export const assignStoreValidation = {
  newStoreId: [
    {
      validator: (_: any, value: string | null) => {
        // Allow null for unassigning
        if (value === null || value === undefined || value.trim() === '') {
          return Promise.resolve();
        }
        return Promise.resolve();
      },
    },
  ] as Rule[],
};
