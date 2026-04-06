import { useRef, useState, useEffect } from 'react';
import { Button, Typography, Flex, Card, Avatar, Slider, message } from 'antd';
import Hls from 'hls.js';
import { PauseIcon, PlayIcon } from 'lucide-react';

/**
 * Icons
 */
import { SoundOutlined } from '@ant-design/icons';

/**
 * Utils
 */
import { formatDuration } from '@/shared/utils';

const { Text } = Typography;

interface HLSAudioPlayerProps {
  hlsUrl?: string;
  title?: string;
  artist?: string;
  coverImageUrl?: string;
  shouldStop?: boolean;
}

export const HLSAudioPlayer = ({
  hlsUrl,
  title,
  artist,
  coverImageUrl,
  shouldStop = false,
}: HLSAudioPlayerProps) => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const hlsRef = useRef<Hls | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Stop playback when drawer closes
  useEffect(() => {
    if (shouldStop && audioRef.current) {
      audioRef.current.pause();
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setIsPlaying(false);
    }
  }, [shouldStop]);

  // Initialize HLS player
  useEffect(() => {
    if (!hlsUrl || !audioRef.current) return;

    const audio = audioRef.current;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setIsLoading(true);
    setError(null);

    // Check if HLS is supported
    if (Hls.isSupported()) {
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
      });

      hls.loadSource(hlsUrl);
      hls.attachMedia(audio);

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        setIsLoading(false);
      });

      hls.on(Hls.Events.ERROR, (_event, data) => {
        console.error('HLS error:', data);
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              setError('Network error - failed to load audio');
              message.error('Failed to load audio stream');
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              setError('Media error - trying to recover');
              hls.recoverMediaError();
              break;
            default:
              setError('Fatal error - cannot play audio');
              hls.destroy();
              break;
          }
        }
        setIsLoading(false);
      });

      hlsRef.current = hls;

      return () => {
        if (hls) {
          hls.destroy();
        }
      };
    } else if (audio.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS support (Safari)
      audio.src = hlsUrl;
      audio.addEventListener('loadedmetadata', () => {
        setIsLoading(false);
      });
      audio.addEventListener('error', () => {
        setError('Failed to load audio');
        setIsLoading(false);
      });
    } else {
      setError('HLS is not supported in this browser');
      setIsLoading(false);
    }
  }, [hlsUrl]);

  // Audio event listeners
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const handleTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };

    const handleDurationChange = () => {
      setDuration(audio.duration);
    };

    const handleEnded = () => {
      setIsPlaying(false);
    };

    const handlePlay = () => {
      setIsPlaying(true);
    };

    const handlePause = () => {
      setIsPlaying(false);
    };

    audio.addEventListener('timeupdate', handleTimeUpdate);
    audio.addEventListener('durationchange', handleDurationChange);
    audio.addEventListener('ended', handleEnded);
    audio.addEventListener('play', handlePlay);
    audio.addEventListener('pause', handlePause);

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate);
      audio.removeEventListener('durationchange', handleDurationChange);
      audio.removeEventListener('ended', handleEnded);
      audio.removeEventListener('play', handlePlay);
      audio.removeEventListener('pause', handlePause);
    };
  }, []);

  const togglePlayPause = () => {
    if (!audioRef.current) return;

    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play().catch((err) => {
        console.error('Play error:', err);
        message.error('Failed to play audio');
      });
    }
  };

  const handleSeek = (value: number) => {
    if (!audioRef.current) return;
    audioRef.current.currentTime = value;
    setCurrentTime(value);
  };

  if (!hlsUrl) {
    return (
      <Card>
        <div style={{ padding: 16, textAlign: 'center', color: '#999' }}>
          <SoundOutlined style={{ fontSize: 24, marginBottom: 8 }} />
          <div>Audio file not available</div>
        </div>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <div style={{ padding: 16, textAlign: 'center', color: '#ff4d4f' }}>
          <SoundOutlined style={{ fontSize: 24, marginBottom: 8 }} />
          <div>{error}</div>
        </div>
      </Card>
    );
  }

  return (
    <Card>
      <audio
        ref={audioRef}
        style={{ display: 'none' }}
      />
      <Flex
        align='start'
        gap='middle'
      >
        {/* Cover Image */}
        {coverImageUrl && (
          <Avatar
            shape='square'
            size={120}
            src={coverImageUrl}
            alt={title}
            className='shrink-0! rounded-lg!'
          />
        )}
        <Flex
          align='center'
          gap='large'
          className='w-full!'
        >
          {/* Track Info & Controls */}
          <Flex
            vertical
            gap={12}
            style={{ flex: 1, minWidth: 0 }}
          >
            {/* Track Title & Artist */}
            {(title || artist) && (
              <Flex
                gap={2}
                align='start'
                vertical
              >
                {title && (
                  <Text
                    strong
                    ellipsis
                    style={{ fontSize: 14 }}
                  >
                    {title}
                  </Text>
                )}
                {artist && (
                  <Text
                    type='secondary'
                    ellipsis
                    style={{ fontSize: 13 }}
                  >
                    {artist}
                  </Text>
                )}
              </Flex>
            )}

            {/* Progress Slider */}
            <div style={{ width: '100%' }}>
              <Slider
                min={0}
                max={duration || 100}
                value={currentTime}
                onChange={handleSeek}
                disabled={isLoading || !duration}
                tooltip={{
                  formatter: (value) => formatDuration(value || 0),
                }}
                style={{ margin: 0 }}
              />
            </div>

            {/* Time Display */}
            <Flex justify='space-between'>
              <Text
                type='secondary'
                style={{ fontSize: 12 }}
              >
                {formatDuration(currentTime)}
              </Text>
              <Text
                type='secondary'
                style={{ fontSize: 12 }}
              >
                {formatDuration(duration)}
              </Text>
            </Flex>

            {isLoading && (
              <Text
                type='secondary'
                style={{ fontSize: 12, textAlign: 'center' }}
              >
                Loading audio stream...
              </Text>
            )}
          </Flex>

          {/* Play/Pause Button */}
          <Button
            shape='circle'
            type='primary'
            icon={
              isPlaying ? (
                <PauseIcon className='size-8' />
              ) : (
                <PlayIcon className='size-8' />
              )
            }
            onClick={togglePlayPause}
            disabled={isLoading}
            className='size-20! shrink-0! [&>span]:size-8!'
          />
        </Flex>
      </Flex>
    </Card>
  );
};
