/**
 * Drawer Widths
 * Use these for consistent drawer sizes across the application
 */
export const DRAWER_WIDTHS = {
  small: 480, // For simple forms (e.g., Change Password)
  medium: 720, // Default for most forms (e.g., Create/Edit Store)
  large: 900, // For complex forms with multiple sections
  extraLarge: 1200, // For very detailed forms or multi-step wizards
} as const;

export const SIDEBAR_WIDTHS = {
  width: 260,
  collapsedWidth: 60,
} as const;

export const MODAL_WIDTHS = {
  medium: 500,
  large: 720,
};

export const AVATAR_SIZE = {
  small: 36,
  medium: 48,
  large: 60,
  extraLarge: 80,
} as const;
