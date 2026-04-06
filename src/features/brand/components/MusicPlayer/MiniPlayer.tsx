import { Avatar, Button, Flex, Typography } from 'antd';

/**
 * Icons
 */
import { FullscreenOutlined } from '@ant-design/icons';

/**
 * Stores
 */
import { usePlayerStore } from '../../stores';

/**
 * Components
 */
import { PlayerControls } from './PlayerControls';
import { PlayerProgress } from './PlayerProgress';
import { PlayerVolume } from './PlayerVolume';

/**
 * Configs
 */
import { AVATAR_SIZE } from '@/config';

const { Text } = Typography;

type MiniPlayerProps = {
  sidebarCollapsed?: boolean;
};

export const MiniPlayer = ({ sidebarCollapsed = false }: MiniPlayerProps) => {
  const currentTrack = usePlayerStore((s) => s.currentTrack);
  const toggleExpanded = usePlayerStore((s) => s.toggleExpanded);

  if (!currentTrack) return null;

  const sidebarWidth = sidebarCollapsed ? 60 : 260;
  // TODO: Dùng màu có sẵn của antd thay thế hardcore
  return (
    <div
      style={{
        position: 'fixed',
        bottom: 0,
        left: sidebarWidth,
        right: 0,
        height: 92,
        backgroundColor: '#062544',
        borderTop: '1px solid rgba(255,255,255,0.1)',
        zIndex: 1000,
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        gap: 24,
      }}
    >
      {/* Track Info */}
      <Flex
        align='center'
        gap={12}
        style={{ minWidth: 220, flex: '0 0 auto' }}
      >
        <Avatar
          src={currentTrack.albumArt}
          size={AVATAR_SIZE.medium}
          shape='square'
          style={{
            borderRadius: 5,
            flexShrink: 0,
          }}
        />
        <Flex vertical>
          <Text
            strong
            style={{ color: '#fff', fontSize: 16, lineHeight: '22px' }}
            ellipsis
          >
            {currentTrack.title}
          </Text>
          <Text
            style={{
              color: 'rgba(255,255,255,0.55)',
              fontSize: 12,
              lineHeight: '16px',
            }}
            ellipsis
          >
            {currentTrack.artist}
          </Text>
        </Flex>
      </Flex>

      {/* Controls + Progress */}
      <Flex
        vertical
        align='center'
        gap={4}
        style={{ flex: 1 }}
      >
        <PlayerControls
          dark
          size='large'
        />
        <PlayerProgress dark />
      </Flex>

      {/* Volume + Expand */}
      <Flex
        align='center'
        gap={8}
        style={{ flex: '0 0 auto' }}
      >
        <PlayerVolume dark />
        <Button
          type='text'
          icon={
            <FullscreenOutlined
              style={{ color: 'rgba(255,255,255,0.65)', fontSize: 16 }}
            />
          }
          onClick={toggleExpanded}
        />
      </Flex>
    </div>
  );
};
