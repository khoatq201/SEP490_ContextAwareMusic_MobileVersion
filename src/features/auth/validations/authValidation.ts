/* eslint-disable @typescript-eslint/no-explicit-any */
import type { Rule } from 'antd/es/form';

export const loginValidation = {
  email: [
    { required: true, message: 'Please input your email!' },
    { type: 'email', message: 'Please enter a valid email!' },
  ] as Rule[],
  password: [
    { required: true, message: 'Please input your password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],
};

export const changePasswordValidation = {
  currentPassword: [
    { required: true, message: 'Please input your current password!' },
  ] as Rule[],
  newPassword: [
    { required: true, message: 'Please input your new password!' },
    { min: 6, message: 'Password must be at least 6 characters!' },
  ] as Rule[],
  confirmPassword: [
    { required: true, message: 'Please confirm your new password!' },
    ({ getFieldValue }: any) => ({
      validator(_: any, value: string) {
        if (!value || getFieldValue('newPassword') === value) {
          return Promise.resolve();
        }
        return Promise.reject(new Error('The two passwords do not match!'));
      },
    }),
  ] as Rule[],
};
