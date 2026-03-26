import { useEffect, useState } from 'react';
import { Drawer, Spin } from 'antd';
import { useQueryClient } from '@tanstack/react-query';

/**
 * Components
 */
import { SpacePlayerCard } from './SpacePlayerCard';

/**
 * Hooks
 */
import { useStoreHub } from '@/shared/modules/cams/hooks';
import { useSpace } from '@/shared/modules/spaces/hooks';
import { useAuth } from '@/providers';

/**
 * Services
 */
import { storeHubService } from '@/shared/modules/cams/services';

/**
 * Configs
 */
import { DRAWER_WIDTHS } from '@/config';

interface SpaceMusicDrawerProps {
  open: boolean;
  spaceId: string | null;
  storeId: string;
  onClose: () => void;
}

/**
 * SpaceMusicDrawer - Manages music playback for a single space
 *
 * This component:
 * 1. Joins the specific space group via SignalR (JoinSpaceAsync)
 * 2. Listens for SpaceStateSync events for real-time updates
 * 3. Renders SpacePlayerCard for music control
 * 4. Leaves the space group when closed
 */
export const SpaceMusicDrawer = ({
  open,
  spaceId,
  storeId,
  onClose,
}: SpaceMusicDrawerProps) => {
  const { accessToken } = useAuth();
  const queryClient = useQueryClient();
  const [isJoinedSpace, setIsJoinedSpace] = useState(false);

  const { data: space, isLoading: isLoadingSpace } = useSpace(
    spaceId || undefined,
    open && !!spaceId,
  );

  const { isConnected } = useStoreHub(storeId, accessToken, {
    onSpaceStateSync: (syncedSpaceId: string) => {
      if (syncedSpaceId === spaceId) {
        queryClient.invalidateQueries({
          queryKey: ['cams-space-state', spaceId],
          refetchType: 'active',
        });
      }
    },
  });

  useEffect(() => {
    if (!open || !spaceId || !isConnected) {
      return;
    }

    let joined = false;

    storeHubService
      .joinSpace(spaceId)
      .then(() => {
        joined = true;
        setIsJoinedSpace(true);
      })
      .catch((error) => {
        console.error('❌ Failed to join space group:', error);
      });

    return () => {
      if (joined) {
        setIsJoinedSpace(false);
      }
      storeHubService
        .leaveSpace(spaceId)
        .then(() => {
          console.log('✅ Left space group successfully:', spaceId);
        })
        .catch((error) => {
          console.error('❌ Failed to leave space group:', error);
        });
    };
  }, [open, spaceId, isConnected]);

  return (
    <Drawer
      closeIcon={null}
      title='Manage Music'
      open={open}
      onClose={onClose}
      width={DRAWER_WIDTHS.medium}
      destroyOnClose
    >
      {isLoadingSpace ? (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size='large' />
        </div>
      ) : !isJoinedSpace ? (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin
            size='large'
            tip='Connecting to space...'
          />
        </div>
      ) : spaceId && space ? (
        <SpacePlayerCard
          space={space}
          storeId={storeId}
        />
      ) : null}
    </Drawer>
  );
};
