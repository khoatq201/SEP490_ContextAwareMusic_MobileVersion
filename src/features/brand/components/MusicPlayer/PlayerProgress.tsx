import { Slider, Typography, Flex } from 'antd';

/**
 * Stores
 */
import { usePlayerStore } from '../../stores';

const { Text } = Typography;

const formatTime = (seconds: number) => {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
};

type PlayerProgressProps = {
  dark?: boolean;
};

export const PlayerProgress = ({ dark = false }: PlayerProgressProps) => {
  const currentTime = usePlayerStore((s) => s.currentTime);
  const duration = usePlayerStore((s) => s.duration);
  const setCurrentTime = usePlayerStore((s) => s.setCurrentTime);
  // TODO: Dùng màu có sẵn của antd thay thế hardcore

  const textStyle = {
    color: dark ? 'rgba(255,255,255,0.65)' : undefined,
    fontSize: 12,
  };

  return (
    <Flex
      align='center'
      gap={8}
      className='w-full'
    >
      <Text style={textStyle}>{formatTime(currentTime)}</Text>
      <Slider
        min={0}
        max={duration}
        value={currentTime}
        onChange={setCurrentTime}
        tooltip={{ formatter: (v) => formatTime(v ?? 0) }}
        style={{ flex: 1, margin: 0 }}
        styles={{
          track: {
            backgroundColor: dark ? '#fff' : undefined,
          },
          rail: {
            backgroundColor: dark ? 'rgba(255,255,255,0.3)' : undefined,
          },
          handle: {
            borderColor: dark ? '#fff' : undefined,
          },
        }}
      />
      <Text style={textStyle}>{formatTime(duration)}</Text>
    </Flex>
  );
};
