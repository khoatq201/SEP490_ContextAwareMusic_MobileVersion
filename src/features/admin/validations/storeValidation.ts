import type { Rule } from 'antd/es/form';

export const storeValidation = {
  store_name: [
    { required: true, message: 'Please input store name!' },
    { min: 2, message: 'Store name must be at least 2 characters!' },
    { max: 100, message: 'Store name must not exceed 100 characters!' },
  ] as Rule[],
  business_type: [
    { required: true, message: 'Please select business type!' },
  ] as Rule[],
  description: [
    { max: 500, message: 'Description must not exceed 500 characters!' },
  ] as Rule[],
  manager_emails: [
    {
      type: 'array',
      validator: async (_, value: string[]) => {
        if (!value || value.length === 0) {
          return Promise.resolve();
        }
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const invalidEmails = value.filter((email) => !emailRegex.test(email));
        if (invalidEmails.length > 0) {
          return Promise.reject(
            new Error(`Invalid email(s): ${invalidEmails.join(', ')}`),
          );
        }
        return Promise.resolve();
      },
    },
  ] as Rule[],
};
