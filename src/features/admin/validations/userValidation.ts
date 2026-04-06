import type { Rule } from 'antd/es/form';

export const createUserValidation = {
  email: [
    { required: true, message: 'Please input email!' },
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],
  role: [{ required: true, message: 'Please select a role!' }] as Rule[],
};