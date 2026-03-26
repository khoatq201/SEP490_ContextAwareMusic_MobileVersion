import { groupBy, sortBy } from 'lodash';
import type { StaffListItem } from '../types';

/**
 * Group staff by store for expandable table
 * Staff without store assignments go to "Unassigned" group
 */
export const groupStaffByStore = (staff: StaffListItem[]): StaffListItem[] => {
  // Group by storeId (null for unassigned)
  const grouped = groupBy(staff, (member) => member.storeId || 'unassigned');

  // Transform to expandable table structure
  const result: StaffListItem[] = [];

  Object.entries(grouped).forEach(([storeId, groupStaff]) => {
    if (groupStaff.length === 0) return;

    const isUnassigned = storeId === 'unassigned';
    const storeName = isUnassigned
      ? 'Unassigned Staff'
      : groupStaff[0].storeName || 'Unknown Store';

    // Find primary owner for the store
    const primaryOwner = groupStaff.find((s) => s.isPrimaryOwner);

    // Sort staff: primary owner first, then by name
    const sortedStaff = sortBy(groupStaff, [
      (s) => !s.isPrimaryOwner,
      'fullName',
    ]);

    // Create parent row
    const parentRow: StaffListItem = {
      id: `store-${storeId}`,
      email: '',
      firstName: '',
      lastName: '',
      fullName: '',
      status: primaryOwner?.status || 1,
      roles: [],
      isPrimaryOwner: false,
      storeId: isUnassigned ? null : storeId,
      storeName,
      brandId: groupStaff[0]?.brandId || null,
      brandName: groupStaff[0]?.brandName || null,
      brandLogoUrl: groupStaff[0]?.brandLogoUrl || null,
      phoneNumber: null,
      avatarUrl: null,
      lastLoginAt: null,
      createdAt: groupStaff[0]?.createdAt || new Date().toISOString(),
      updatedAt: null,
      createdBy: null,
      updatedBy: null,
      children: sortedStaff,
    };

    result.push(parentRow);
  });

  // Sort stores: assigned first, then alphabetically
  return sortBy(result, [(row) => row.storeId === undefined, 'storeName']);
};
