import { Button, Flex } from 'antd';

/**
 * Icons
 */
import {
  CaretRightOutlined,
  PauseOutlined,
  StepForwardOutlined,
  SwapOutlined,
} from '@ant-design/icons';

/**
 * Stores
 */
import { usePlayerStore } from '../../stores';

type PlayerControlsProps = {
  dark?: boolean;
  size?: 'default' | 'large';
};

export const PlayerControls = ({
  dark = false,
  size = 'default',
}: PlayerControlsProps) => {
  // TODO: Dùng màu có sẵn của antd thay thế hardcore

  const isPlaying = usePlayerStore((s) => s.isPlaying);
  const isShuffle = usePlayerStore((s) => s.isShuffle);
  const togglePlay = usePlayerStore((s) => s.togglePlay);
  const toggleShuffle = usePlayerStore((s) => s.toggleShuffle);
  const nextTrack = usePlayerStore((s) => s.nextTrack);

  const iconStyle = { color: dark ? '#fff' : undefined };
  const shuffleColor = isShuffle
    ? dark
      ? '#fff'
      : 'var(--ant-color-primary)'
    : dark
      ? 'rgba(255,255,255,0.5)'
      : undefined;

  const playBtnSize = size === 'large' ? 52 : 36;
  const playIconSize = size === 'large' ? 24 : 14;

  return (
    <Flex
      align='center'
      gap={size === 'large' ? 20 : 8}
    >
      {/* Shuffle */}
      <Button
        type='text'
        icon={
          <SwapOutlined
            style={{
              color: shuffleColor,
              fontSize: size === 'large' ? 20 : 14,
            }}
          />
        }
        onClick={toggleShuffle}
        style={{ color: shuffleColor }}
      />

      {/* Play / Pause */}
      <Button
        type='primary'
        shape='circle'
        icon={
          isPlaying ? (
            <PauseOutlined style={{ fontSize: playIconSize }} />
          ) : (
            <CaretRightOutlined style={{ fontSize: playIconSize }} />
          )
        }
        onClick={togglePlay}
        style={{
          width: playBtnSize,
          height: playBtnSize,
          backgroundColor: dark ? '#fff' : undefined,
          color: dark ? '#000' : undefined,
          border: 'none',
        }}
      />

      {/* Next */}
      <Button
        type='text'
        icon={
          <StepForwardOutlined
            style={{ ...iconStyle, fontSize: size === 'large' ? 20 : 14 }}
          />
        }
        onClick={nextTrack}
      />
    </Flex>
  );
};
