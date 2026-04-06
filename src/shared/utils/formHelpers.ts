import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import customParseFormat from 'dayjs/plugin/customParseFormat';

// Enable plugins
dayjs.extend(relativeTime);
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(customParseFormat);

/**
 * Format date to "MMM DD, YYYY HH:mm"
 * Example: "Mar 11, 2026 14:30"
 */
export const formatDateTime = (date?: string | Date): string => {
  if (!date) return '-';
  return dayjs(date).format('MMM DD, YYYY HH:mm');
};

/**
 * Format date to "MMM DD, YYYY"
 * Example: "Mar 11, 2026"
 */
export const formatDate = (date?: string | Date): string => {
  if (!date) return '-';
  return dayjs(date).format('MMM DD, YYYY');
};

/**
 * Format time to "HH:mm:ss"
 * Example: "14:30:45"
 */
export const formatTime = (date?: string | Date): string => {
  if (!date) return '-';
  return dayjs(date).format('HH:mm:ss');
};

/**
 * Format date to relative time
 * Example: "2 hours ago", "in 3 days"
 */
export const formatRelativeTime = (date?: string | Date): string => {
  if (!date) return '-';
  return dayjs(date).fromNow();
};

/**
 * Format date to ISO 8601 string
 * Example: "2026-03-11T14:30:45.123Z"
 */
export const toISOString = (date?: string | Date): string => {
  if (!date) return '';
  return dayjs(date).toISOString();
};

/**
 * Parse ISO date to Day.js object
 */
export const parseDate = (date?: string | Date) => {
  if (!date) return null;
  return dayjs(date);
};

/**
 * Check if date is valid
 */
export const isValidDate = (date?: string | Date): boolean => {
  if (!date) return false;
  return dayjs(date).isValid();
};

/**
 * Get date range (start, end)
 */
export const getDateRange = (
  startDate?: string | Date,
  endDate?: string | Date,
): string => {
  if (!startDate && !endDate) return '-';
  if (!startDate) return `Until ${formatDate(endDate)}`;
  if (!endDate) return `From ${formatDate(startDate)}`;
  return `${formatDate(startDate)} - ${formatDate(endDate)}`;
};

/**
 * Format phone number (Vietnam format)
 * Example: "0123456789" → "0123 456 789"
 */
export const formatPhoneNumber = (phone?: string): string => {
  if (!phone) return '-';
  const cleaned = phone.replace(/\D/g, '');
  const match = cleaned.match(/^(\d{4})(\d{3})(\d{3})$/);
  if (match) {
    return `${match[1]} ${match[2]} ${match[3]}`;
  }
  return phone;
};

/**
 * Format currency (VND)
 * Example: 1000000 → "1,000,000 ₫"
 */
export const formatCurrency = (amount?: number): string => {
  if (!amount && amount !== 0) return '-';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
};

/**
 * Convert NULL value to UNDEFINED
 */
export const nullToUndefined = <T>(value: T | null): T | undefined => {
  return value === null ? undefined : value;
};
