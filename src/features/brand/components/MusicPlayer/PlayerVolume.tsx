import { Button, Flex, Slider } from 'antd';

/**
 * Icons
 */
import { SoundOutlined, MutedOutlined } from '@ant-design/icons';

/**
 * Stores
 */
import { usePlayerStore } from '../../stores';

type PlayerVolumeProps = {
  dark?: boolean;
};

export const PlayerVolume = ({ dark = false }: PlayerVolumeProps) => {
  const volume = usePlayerStore((s) => s.volume);
  const setVolume = usePlayerStore((s) => s.setVolume);
  // TODO: Dùng màu có sẵn của antd thay thế hardcore

  const iconStyle = {
    color: dark ? 'rgba(255,255,255,0.85)' : undefined,
    fontSize: 16,
  };

  return (
    <Flex
      align='center'
      gap={8}
      style={{ minWidth: 130 }}
    >
      <Button
        type='text'
        icon={
          volume === 0 ? (
            <MutedOutlined style={iconStyle} />
          ) : (
            <SoundOutlined style={iconStyle} />
          )
        }
        onClick={() => setVolume(volume === 0 ? 75 : 0)}
      />
      <Slider
        min={0}
        max={100}
        value={volume}
        onChange={setVolume}
        style={{ flex: 1, margin: 0 }}
        styles={{
          track: { backgroundColor: dark ? '#fff' : undefined },
          rail: { backgroundColor: dark ? 'rgba(255,255,255,0.3)' : undefined },
          handle: { borderColor: dark ? '#fff' : undefined },
        }}
      />
    </Flex>
  );
};
