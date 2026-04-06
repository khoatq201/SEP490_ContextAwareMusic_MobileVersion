import type { Rule } from 'antd/es/form';

export const createAccountValidation = {
  firstName: [
    { required: true, message: 'Please input first name!' },
    { max: 100, message: 'First name must not exceed 100 characters!' },
  ] as Rule[],

  lastName: [
    { required: true, message: 'Please input last name!' },
    { max: 100, message: 'Last name must not exceed 100 characters!' },
  ] as Rule[],

  email: [
    { required: true, message: 'Please input email!' },
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],

  password: [
    { required: true, message: 'Please input password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],

  phoneNumber: [
    {
      pattern: /^[\d\s\+\(\)-]{7,15}$/,
      message: 'Phone number must be 7-15 digits (supports +, (), -, spaces)',
    },
  ] as Rule[],

  role: [{ required: true, message: 'Please select a role!' }] as Rule[],

  brandId: [
    {
      required: true,
      message: 'Please select a brand for Brand Manager!',
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

export const updateAccountValidation = {
  firstName: [
    { max: 100, message: 'First name must not exceed 100 characters!' },
  ] as Rule[],

  lastName: [
    { max: 100, message: 'Last name must not exceed 100 characters!' },
  ] as Rule[],

  email: [{ type: 'email', message: 'Please enter a valid email!' }] as Rule[],

  phoneNumber: [
    {
      pattern: /^[\d\s\+\(\)-]{7,15}$/,
      message: 'Phone number must be 7-15 digits',
    },
  ] as Rule[],

  avatar: createAccountValidation.avatar,
};

export const resetPasswordValidation = {
  newPassword: [
    { required: true, message: 'Please input new password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],
};

export const assignBrandValidation = {
  newBrandId: [{ required: true, message: 'Please select a brand!' }] as Rule[],
};

export const assignStoreValidation = {
  newStoreId: [{ required: true, message: 'Please select a store!' }] as Rule[],
};
