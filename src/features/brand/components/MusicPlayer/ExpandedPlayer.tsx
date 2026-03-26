import { Avatar, Button, Flex, Typography } from 'antd';

/**
 * Icons
 */
import {
  FullscreenExitOutlined,
  EllipsisOutlined,
  UnorderedListOutlined,
} from '@ant-design/icons';

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

const { Text, Title } = Typography;

export const ExpandedPlayer = () => {
  const currentTrack = usePlayerStore((s) => s.currentTrack);
  const isExpanded = usePlayerStore((s) => s.isExpanded);
  const toggleExpanded = usePlayerStore((s) => s.toggleExpanded);

  if (!currentTrack) return null;

  // TODO: Dùng màu có sẵn của antd thay thế hardcore
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 1001,
        overflow: 'hidden',
        opacity: isExpanded ? 1 : 0,
        pointerEvents: isExpanded ? 'all' : 'none',
        transition: 'opacity 0.3s ease',
      }}
    >
      {/* Blurred Background */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: `url(${currentTrack.albumArt})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          filter: 'blur(20px) brightness(0.4)',
          transform: 'scale(1.1)',
        }}
      />

      {/* Dark overlay */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundColor: 'rgba(0,0,0,0.45)',
        }}
      />

      {/* Content */}
      <Flex
        style={{ position: 'relative', height: '100%', padding: '32px 48px' }}
        align='center'
        gap={64}
      >
        {/* Album Art */}
        <Avatar
          src={currentTrack.albumArt}
          size={380}
          shape='square'
          style={{
            borderRadius: 12,
            flexShrink: 0,
            boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
          }}
        />

        {/* Right Info */}
        <Flex
          vertical
          style={{ flex: 1 }}
          gap={0}
        >
          {/* Header */}
          <Flex
            justify='space-between'
            align='flex-start'
            style={{ marginBottom: 32 }}
          >
            <Flex vertical>
              <Text style={{ color: 'rgba(255,255,255,0.55)', fontSize: 13 }}>
                CAMS
              </Text>
              <Text style={{ color: '#fff', fontSize: 15, fontWeight: 600 }}>
                {currentTrack.album}
              </Text>
            </Flex>
            <Button
              type='text'
              icon={
                <EllipsisOutlined
                  style={{ color: 'rgba(255,255,255,0.65)', fontSize: 20 }}
                />
              }
            />
          </Flex>

          {/* Track Info */}
          <Flex
            justify='space-between'
            align='center'
            style={{ marginBottom: 24 }}
          >
            <Flex vertical>
              <Title
                level={3}
                style={{ color: '#fff', margin: 0 }}
              >
                {currentTrack.title}
              </Title>
              <Text style={{ color: 'rgba(255,255,255,0.65)', fontSize: 14 }}>
                {currentTrack.artist}
              </Text>
            </Flex>
            <Button
              type='text'
              icon={
                <UnorderedListOutlined
                  style={{ color: 'rgba(255,255,255,0.65)', fontSize: 18 }}
                />
              }
            />
          </Flex>

          {/* Progress */}
          <div style={{ marginBottom: 16 }}>
            <PlayerProgress dark />
          </div>

          {/* Controls + Volume */}
          <Flex
            align='center'
            justify='space-between'
          >
            <PlayerControls
              dark
              size='large'
            />
            <PlayerVolume dark />
          </Flex>
        </Flex>
      </Flex>

      {/* Close Button */}
      <Button
        type='text'
        icon={
          <FullscreenExitOutlined
            style={{ color: 'rgba(255,255,255,0.85)', fontSize: 20 }}
          />
        }
        onClick={toggleExpanded}
        style={{ position: 'absolute', top: 20, right: 20 }}
      />
    </div>
  );
};
