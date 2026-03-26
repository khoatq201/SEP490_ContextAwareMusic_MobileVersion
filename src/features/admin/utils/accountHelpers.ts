import { groupBy, sortBy } from 'lodash';
import type { AccountListItem } from '../types';

/**
 * Group accounts by brand for expandable table
 * Accounts without brand assignments go to "Unassigned" group
 */
export const groupAccountsByBrand = (
  accounts: AccountListItem[],
): AccountListItem[] => {
  // Group by brandId (null for unassigned)
  const grouped = groupBy(
    accounts,
    (account) => account.brandId || 'unassigned',
  );

  // Transform to expandable table structure
  const result: AccountListItem[] = [];

  Object.entries(grouped).forEach(([brandId, groupAccounts]) => {
    if (groupAccounts.length === 0) return;

    const isUnassigned = brandId === 'unassigned';
    const brandName = isUnassigned
      ? 'Unassigned Accounts'
      : groupAccounts[0].brandName || 'Unknown Brand';

    const brandLogoUrl = isUnassigned
      ? undefined
      : groupAccounts[0].brandLogoUrl;

    // Find primary owner for the brand
    const primaryOwner = groupAccounts.find((acc) => acc.isPrimaryOwner);

    // Sort accounts: primary owner first, then by name
    const sortedAccounts = sortBy(groupAccounts, [
      (acc) => !acc.isPrimaryOwner, // Primary owner first
      'fullName',
    ]);

    // Create parent row (brand summary)
    const parentRow: AccountListItem = {
      id: `brand-${brandId}`,
      email: '', // Not shown in parent row
      firstName: '',
      lastName: '',
      fullName: '', // Not used in group row
      status: primaryOwner?.status || 1, // Use primary owner's status
      roles: [],
      isPrimaryOwner: false,
      brandId: isUnassigned ? undefined : brandId,
      brandName,
      brandLogoUrl, // Include brand logo
      children: sortedAccounts, // Nested accounts
    };

    result.push(parentRow);
  });

  // Sort brands: assigned first, then alphabetically
  return sortBy(result, [
    (row) => row.brandId === undefined, // Unassigned last
    'brandName',
  ]);
};
