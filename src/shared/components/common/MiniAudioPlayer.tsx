import { useState, useRef, useEffect } from 'react';
import { Button } from 'antd';
import {
  PlayCircleOutlined,
  PauseCircleOutlined,
  LoadingOutlined,
} from '@ant-design/icons';
import Hls from 'hls.js';
import { MusicIcon } from 'lucide-react';
import { cn } from '@/shared/lib';

interface MiniAudioPlayerProps {
  hlsUrl?: string;
  coverImageUrl?: string;
  size?: number;
  onPlay?: () => void;
  onPause?: () => void;
  onError?: (error: Error) => void;
}

/**
 * MiniAudioPlayer - A compact HLS audio player with play/pause button overlay
 * Perfect for track lists where you want inline playback without full player UI
 *
 * @example
 * <MiniAudioPlayer
 *   hlsUrl="https://cdn.example.com/track.m3u8"
 *   coverImageUrl="https://cdn.example.com/cover.jpg"
 *   size={48}
 * />
 */
export const MiniAudioPlayer = ({
  hlsUrl,
  coverImageUrl,
  size = 48,
  onPlay,
  onPause,
  onError,
}: MiniAudioPlayerProps) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [hasError, setHasError] = useState(false);

  const audioRef = useRef<HTMLAudioElement | null>(null);
  const hlsRef = useRef<Hls | null>(null);

  // Initialize HLS
  useEffect(() => {
    if (!hlsUrl) return;

    const audio = new Audio();
    audioRef.current = audio;

    // Setup HLS
    if (Hls.isSupported()) {
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
      });

      hls.loadSource(hlsUrl);
      hls.attachMedia(audio);

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        setHasError(false);
      });

      hls.on(Hls.Events.ERROR, (_event, data) => {
        if (data.fatal) {
          console.error('HLS fatal error:', data);
          setHasError(true);
          setIsLoading(false);
          setIsPlaying(false);
          onError?.(new Error(data.details));
        }
      });

      hlsRef.current = hls;
    } else if (audio.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS support (Safari)
      audio.src = hlsUrl;
    } else {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setHasError(true);
      onError?.(new Error('HLS not supported'));
    }

    // Audio event listeners
    audio.addEventListener('playing', () => {
      setIsLoading(false);
      setIsPlaying(true);
    });

    audio.addEventListener('pause', () => {
      setIsPlaying(false);
    });

    audio.addEventListener('ended', () => {
      setIsPlaying(false);
    });

    audio.addEventListener('waiting', () => {
      setIsLoading(true);
    });

    audio.addEventListener('canplay', () => {
      setIsLoading(false);
    });

    audio.addEventListener('error', () => {
      setHasError(true);
      setIsLoading(false);
      setIsPlaying(false);
    });

    // Cleanup
    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy();
      }
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.src = '';
      }
    };
  }, [hlsUrl, onError]);

  const handleTogglePlay = async () => {
    if (!audioRef.current || !hlsUrl) return;

    try {
      if (isPlaying) {
        audioRef.current.pause();
        onPause?.();
      } else {
        setIsLoading(true);
        await audioRef.current.play();
        onPlay?.();
      }
    } catch (error) {
      console.error('Playback error:', error);
      setHasError(true);
      setIsLoading(false);
      onError?.(error as Error);
    }
  };

  const getIcon = () => {
    if (isLoading) {
      return <LoadingOutlined style={{ fontSize: size * 0.5 }} />;
    }
    if (isPlaying) {
      return <PauseCircleOutlined style={{ fontSize: size * 0.5 }} />;
    }
    return <PlayCircleOutlined style={{ fontSize: size * 0.5 }} />;
  };

  return (
    <div
      style={{
        position: 'relative',
        width: size,
        height: size,
        borderRadius: 4,
        overflow: 'hidden',
      }}
    >
      {/* Background Image or Placeholder */}
      {coverImageUrl ? (
        <img
          src={coverImageUrl}
          alt='Track cover'
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
          }}
          className={cn('rounded-sm', {
            'border border-red-500': hasError,
          })}
        />
      ) : (
        <div
          style={{
            width: '100%',
            height: '100%',
            background: '#f0f0f0',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
          className={cn('rounded-sm', {
            'border border-red-500': hasError,
          })}
        >
          <MusicIcon style={{ color: '#999' }} />
        </div>
      )}

      {/* Play/Pause Button Overlay */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'rgba(0, 0, 0, 0.3)',
          opacity: isPlaying || isLoading ? 1 : 0,
          transition: 'opacity 0.2s',
          cursor: hasError || !hlsUrl ? 'not-allowed' : 'pointer',
        }}
        onMouseEnter={(e) => {
          if (!hasError && hlsUrl) {
            e.currentTarget.style.opacity = '1';
          }
        }}
        onMouseLeave={(e) => {
          if (!isPlaying && !isLoading) {
            e.currentTarget.style.opacity = '0';
          }
        }}
        onClick={handleTogglePlay}
      >
        <Button
          type='text'
          icon={getIcon()}
          disabled={hasError || !hlsUrl}
          style={{
            color: 'white',
            border: 'none',
            background: 'transparent',
            padding: 0,
            height: 'auto',
          }}
        />
      </div>

      {/* Error Indicator */}
      {hasError && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'rgba(255, 0, 0, 0.1)',
          }}
        >
          <span style={{ color: 'red', fontSize: 12 }}>✕</span>
        </div>
      )}
    </div>
  );
};
