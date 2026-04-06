import type { Rule } from 'antd/es/form';

export const createStoreValidation = {
  name: [
    { required: true, message: 'Please enter store name!' },
    { max: 200, message: 'Store name must not exceed 200 characters!' },
  ] as Rule[],
  address: [
    { max: 500, message: 'Address must not exceed 500 characters!' },
  ] as Rule[],
  city: [
    { max: 100, message: 'City must not exceed 100 characters!' },
  ] as Rule[],
  district: [
    { max: 100, message: 'District must not exceed 100 characters!' },
  ] as Rule[],
  contactNumber: [
    {
      pattern:
        /^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$/,
      message:
        'Please enter a valid phone number! (e.g., +84283456789 or 0283456789)',
    },
  ] as Rule[],
  latitude: [
    {
      type: 'number',
      min: -90,
      max: 90,
      message: 'Latitude must be between -90 and 90!',
    },
  ] as Rule[],
  longitude: [
    {
      type: 'number',
      min: -180,
      max: 180,
      message: 'Longitude must be between -180 and 180!',
    },
  ] as Rule[],
  mapUrl: [
    {
      type: 'url',
      message: 'Please enter a valid URL!',
    },
  ] as Rule[],
  timeZone: [] as Rule[], // Optional, có default value
  areaSquareMeters: [
    {
      type: 'number',
      min: 0.01,
      message: 'Area must be greater than 0!',
    },
  ] as Rule[],
  maxCapacity: [
    {
      type: 'number',
      min: 1,
      message: 'Max capacity must be at least 1!',
    },
  ] as Rule[],
  fuzzyOverrideLevel: [
    { required: true, message: 'Please select a store policy level!' },
    {
      validator: (_, value) => {
        if (value === undefined || value === null) return Promise.resolve();
        return [1, 2, 3].includes(value)
          ? Promise.resolve()
          : Promise.reject(
              new Error('Invalid policy level. Must be 1, 2 or 3.'),
            );
      },
    },
  ] as Rule[],
};

export const updateStoreValidation = {
  ...createStoreValidation,
  name: [
    { max: 200, message: 'Store name must not exceed 200 characters!' },
  ] as Rule[], // Optional for update
  fuzzyOverrideLevel: [
    {
      validator: (_, value) => {
        if (value === undefined || value === null) return Promise.resolve();
        return [1, 2, 3].includes(value)
          ? Promise.resolve()
          : Promise.reject(
              new Error('Invalid policy level. Must be 1, 2 or 3.'),
            );
      },
    },
  ] as Rule[],
};
