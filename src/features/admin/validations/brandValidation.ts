import type { Rule } from 'antd/es/form';

export const brandValidation = {
  name: [
    { required: true, message: 'Please input brand name!' },
    { max: 200, message: 'Brand name must not exceed 200 characters!' },
  ] as Rule[],

  logo: [
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

  description: [
    { max: 2000, message: 'Description must not exceed 2000 characters!' },
  ] as Rule[],

  website: [
    { type: 'url', message: 'Please enter a valid URL!' },
    {
      pattern: /^https?:\/\/.+/,
      message: 'Website must start with http:// or https://',
    },
  ] as Rule[],

  industry: [
    { max: 100, message: 'Industry must not exceed 100 characters!' },
  ] as Rule[],

  contactEmail: [
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],

  contactPhone: [
    {
      pattern: /^[\d\s\+\(\)-]{7,15}$/,
      message: 'Phone number must be 7-15 digits (supports +, (), -, spaces)',
    },
  ] as Rule[],

  primaryContactName: [
    {
      max: 200,
      message: 'Primary contact name must not exceed 200 characters!',
    },
  ] as Rule[],

  technicalContactEmail: [
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],

  legalName: [
    { max: 250, message: 'Legal name must not exceed 250 characters!' },
  ] as Rule[],

  taxCode: [
    { max: 50, message: 'Tax code must not exceed 50 characters!' },
  ] as Rule[],

  billingAddress: [
    { max: 500, message: 'Billing address must not exceed 500 characters!' },
  ] as Rule[],

  defaultTimeZone: [
    { required: true, message: 'Please select a timezone!' },
  ] as Rule[],
};
