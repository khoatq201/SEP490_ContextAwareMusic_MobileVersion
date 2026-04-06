import type { Rule } from 'antd/es/form';

export const pairDeviceValidation = {
  space_id: [{ required: true, message: 'Please select a space!' }] as Rule[],
  pairing_method: [
    { required: true, message: 'Please select pairing method!' },
  ] as Rule[],
  pairing_code: [
    { required: true, message: 'Please enter pairing code!' },
    {
      pattern: /^[A-Z0-9]{6}$/,
      message: 'Pairing code must be 6 alphanumeric characters!',
    },
  ] as Rule[],
};
