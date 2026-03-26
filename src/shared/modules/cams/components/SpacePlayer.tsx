import { useEffect, useRef, useState } from 'react';
import {
  Card,
  Slider,
  Button,
  Space,
  Typography,
  Flex,
  Tag,
  message,
} from 'antd';
import Hls from 'hls.js';
import {
  PlayCircleOutlined,
  PauseCircleOutlined,
  StepBackwardOutlined,
  StepForwardOutlined,
  SoundOutlined,
} from '@ant-design/icons';
import { HLS_PLAYER_CONFIG } from '../constants';
import {
  formatPlaybackTime,
  volumeToAudioLevel,
  getEffectiveSeekOffset,
} from '../utils';
import type { SpaceStateResponse } from '../types';

const { Text } = Typography;

interface SpacePlayerProps {
  spaceId: string;
  hlsUrl: string | null;
  state: SpaceStateResponse | null | undefined;
  isPlaying: boolean;
  isLoading?: boolean;
  onPlayPause: () => void;
  onSkipNext: () => void;
  onSkipPrevious: () => void;
  onSeek?: (seconds: number) => void;
  onVolumeChange?: (volume: number) => void;
}

export const SpacePlayer = ({
  hlsUrl,
  state,
  isPlaying,
  isLoading = false,
  onPlayPause,
  onSkipNext,
  onSkipPrevious,
  onSeek,
  onVolumeChange,
}: SpacePlayerProps) => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const hlsRef = useRef<Hls | null>(null);

  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(75);
  const [isBuffering, setIsBuffering] = useState(false);

  // ✅ Track if we're syncing from server to avoid feedback loops
  const isSyncingRef = useRef(false);
  // ✅ Track last pause time to detect long pause (need HLS reload)
  const lastPauseTimeRef = useRef<number | null>(null);
  // ✅ Store expected seek position after reload
  const pendingSeekRef = useRef<number | null>(null);

  // Initialize HLS player
  useEffect(() => {
    console.log('🎯 HLS Effect triggered:', {
      hlsUrl: hlsUrl?.substring(0, 50),
      isPlaying,
    });

    if (!hlsUrl || !audioRef.current) {
      // ✅ Cleanup old HLS instance if URL becomes null
      if (hlsRef.current) {
        console.log('🧹 Cleaning up HLS instance (no URL)');
        hlsRef.current.destroy();
        hlsRef.current = null;
      }
      return;
    }

    const audio = audioRef.current;

    // ✅ Destroy existing HLS instance before creating new one
    if (hlsRef.current) {
      console.log('🧹 Cleaning up old HLS instance before reload');
      hlsRef.current.destroy();
      hlsRef.current = null;
    }

    // Check if HLS.js is supported
    if (Hls.isSupported()) {
      console.log('🎬 Creating new HLS instance for:', hlsUrl.substring(0, 80));
      const hls = new Hls(HLS_PLAYER_CONFIG);
      hlsRef.current = hls;

      hls.loadSource(hlsUrl);
      hls.attachMedia(audio);

      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        console.log('✅ HLS manifest parsed successfully');

        // ✅ Apply pending seek if exists (from long pause reload)
        if (pendingSeekRef.current !== null) {
          console.log(
            `⏩ Applying pending seek to ${pendingSeekRef.current.toFixed(1)}s`,
          );
          audio.currentTime = pendingSeekRef.current;
          pendingSeekRef.current = null;
        }

        // Auto-play if state says it should be playing
        if (isPlaying) {
          console.log('▶️ Auto-playing after manifest parsed');
          audio.play().catch((err) => {
            console.error('❌ Auto-play failed:', err);
            message.warning('Click play to start playback');
          });
        }
      });

      hls.on(Hls.Events.MANIFEST_LOADING, () => {
        console.log('⏳ Loading HLS manifest...');
      });

      hls.on(Hls.Events.LEVEL_LOADED, (_event, data) => {
        console.log('📦 HLS level loaded:', data.level);
      });

      hls.on(Hls.Events.ERROR, (_event, data) => {
        console.error('❌ HLS error:', data);
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              console.error('🌐 Network error loading stream');
              message.error('Network error loading stream');
              hls.startLoad();
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              console.error('🎵 Media error. Attempting recovery...');
              message.error('Media error. Attempting recovery...');
              hls.recoverMediaError();
              break;
            default:
              console.error('💥 Fatal error occurred');
              message.error('Fatal error occurred. Please refresh.');
              hls.destroy();
              break;
          }
        }
      });

      return () => {
        console.log('🧹 Cleanup HLS instance on unmount/URL change');
        hls.destroy();
        hlsRef.current = null;
      };
    } else if (audio.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS support (Safari)
      console.log('🍎 Using native HLS support (Safari)');
      audio.src = hlsUrl;

      // ✅ Apply pending seek for Safari
      if (pendingSeekRef.current !== null) {
        audio.currentTime = pendingSeekRef.current;
        pendingSeekRef.current = null;
      }

      if (isPlaying) {
        audio.play().catch((err) => {
          console.error('Auto-play failed:', err);
        });
      }
    } else {
      console.error('❌ HLS playback not supported in this browser');
      message.error('HLS playback not supported in this browser');
    }
  }, [hlsUrl, isPlaying]);

  // ✅ Sync audio playback state from server (SpaceStateSync)
  useEffect(() => {
    if (!audioRef.current || !state) return;

    const audio = audioRef.current;

    // ✅ Prevent re-sync if already syncing
    if (isSyncingRef.current) {
      console.log('⏭️ Already syncing, skipping...');
      return;
    }

    isSyncingRef.current = true;

    // Handle pause state from server
    if (state.isPaused) {
      if (!audio.paused) {
        console.log('⏸️ Pausing playback');
        audio.pause();
        lastPauseTimeRef.current = Date.now();
      }
      // Sync to pause position
      if (state.pausePositionSeconds != null) {
        audio.currentTime = state.pausePositionSeconds;
      }

      isSyncingRef.current = false;
    } else {
      // Handle playing state from server
      const expectedPosition = getEffectiveSeekOffset(state);

      // ✅ Check if paused for too long (> 30s) — need HLS reload
      const pauseDuration = lastPauseTimeRef.current
        ? Date.now() - lastPauseTimeRef.current
        : 0;
      const needsReload = pauseDuration > 30000; // 30 seconds

      if (needsReload && hlsUrl && hlsRef.current) {
        console.log(
          `🔄 Long pause detected (${(pauseDuration / 1000).toFixed(0)}s). Reloading HLS instance...`,
        );

        const hls = hlsRef.current;

        // ✅ Store expected position to apply after reload
        pendingSeekRef.current = expectedPosition;

        // ✅ Reload HLS source directly (no setState)
        hls.detachMedia();
        hls.loadSource(hlsUrl);
        hls.attachMedia(audio);

        // Manifest parsed event will handle seek + play
        lastPauseTimeRef.current = null;
        isSyncingRef.current = false;
      } else {
        // Normal resume — just sync position and play
        const diff = Math.abs(audio.currentTime - expectedPosition);
        if (diff > 2) {
          console.log(
            `🔄 Syncing position: ${audio.currentTime.toFixed(1)}s → ${expectedPosition.toFixed(1)}s (diff: ${diff.toFixed(1)}s)`,
          );
          audio.currentTime = expectedPosition;
        }

        // ✅ Only try to play if HLS is ready (has duration)
        if (audio.paused && isPlaying) {
          if (audio.duration && audio.duration > 0) {
            console.log('▶️ Resuming playback');
            audio.play().catch((err) => {
              console.error('❌ Play failed:', err);
              // Retry once
              setTimeout(() => {
                if (audioRef.current && audioRef.current.paused) {
                  audioRef.current.play().catch(console.error);
                }
              }, 500);
            });
          } else {
            console.warn(
              '⚠️ Audio not ready (no duration). Waiting for HLS...',
            );
            // Wait for duration to be available
            const checkReady = setInterval(() => {
              if (audioRef.current && audioRef.current.duration > 0) {
                console.log('✅ Audio ready, playing now');
                clearInterval(checkReady);
                audioRef.current.play().catch(console.error);
              }
            }, 200);

            // Timeout after 3 seconds
            setTimeout(() => clearInterval(checkReady), 3000);
          }
        }

        lastPauseTimeRef.current = null;

        // ✅ Delay before allowing next sync
        setTimeout(() => {
          isSyncingRef.current = false;
        }, 1000); // Increase delay to 1s to prevent rapid re-sync
      }
    }
  }, [state, isPlaying, hlsUrl]);

  // Sync volume
  useEffect(() => {
    if (!audioRef.current) return;
    audioRef.current.volume = volumeToAudioLevel(volume);
  }, [volume]);

  // Audio event handlers
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const handleTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };

    const handleDurationChange = () => {
      setDuration(audio.duration);
    };

    const handleWaiting = () => {
      setIsBuffering(true);
    };

    const handleCanPlay = () => {
      setIsBuffering(false);
    };

    const handleEnded = () => {
      console.log('Track ended');
    };

    audio.addEventListener('timeupdate', handleTimeUpdate);
    audio.addEventListener('durationchange', handleDurationChange);
    audio.addEventListener('waiting', handleWaiting);
    audio.addEventListener('canplay', handleCanPlay);
    audio.addEventListener('ended', handleEnded);

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate);
      audio.removeEventListener('durationchange', handleDurationChange);
      audio.removeEventListener('waiting', handleWaiting);
      audio.removeEventListener('canplay', handleCanPlay);
      audio.removeEventListener('ended', handleEnded);
    };
  }, []);

  // Handle seek
  const handleSeek = (value: number) => {
    if (!audioRef.current) return;
    const seekTime = (value / 100) * duration;
    audioRef.current.currentTime = seekTime;
    onSeek?.(seekTime);
  };

  // Handle volume change
  const handleVolumeChange = (value: number) => {
    setVolume(value);
    onVolumeChange?.(value);
  };

  const progress = duration > 0 ? (currentTime / duration) * 100 : 0;

  return (
    <Card>
      {/* Hidden audio element */}
      <audio ref={audioRef} />

      <Space
        direction='vertical'
        style={{ width: '100%' }}
        size='middle'
      >
        {/* Track Info */}
        <Flex vertical>
          <Flex
            justify='space-between'
            align='center'
          >
            <Text
              strong
              style={{ fontSize: 16, display: 'block' }}
            >
              {state?.currentTrackName || 'No track playing'}
            </Text>
            <Space>
              {isPlaying && (
                <Tag
                  color='processing'
                  icon={<PlayCircleOutlined />}
                >
                  Playing
                </Tag>
              )}
              {isBuffering && <Tag color='warning'>Buffering...</Tag>}
              {state?.isManualOverride && (
                <Tag color='orange'>Manual Override</Tag>
              )}
            </Space>
          </Flex>
          <Text
            type='secondary'
            style={{ fontSize: 14 }}
          >
            {state?.moodName || 'No mood'}
          </Text>
        </Flex>

        {/* Progress Bar */}
        <div>
          <Slider
            value={progress}
            onChange={handleSeek}
            tooltip={{
              formatter: (value) => {
                const seconds = ((value ?? 0) / 100) * duration;
                return formatPlaybackTime(seconds);
              },
            }}
            disabled={!hlsUrl || isLoading}
          />
          <Flex justify='space-between'>
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
            >
              {formatPlaybackTime(currentTime)}
            </Text>
            <Text
              type='secondary'
              style={{ fontSize: 12 }}
            >
              {formatPlaybackTime(duration)}
            </Text>
          </Flex>
        </div>

        {/* Playback Controls */}
        <Flex
          justify='center'
          align='center'
          gap='middle'
        >
          <Button
            size='large'
            type='text'
            icon={<StepBackwardOutlined />}
            onClick={onSkipPrevious}
            disabled={!state?.currentQueueItemId || isLoading}
          />
          <Button
            type='primary'
            shape='circle'
            size='large'
            icon={
              isPlaying ? (
                <PauseCircleOutlined style={{ fontSize: 24 }} />
              ) : (
                <PlayCircleOutlined style={{ fontSize: 24 }} />
              )
            }
            onClick={onPlayPause}
            disabled={!hlsUrl || isLoading}
            loading={isBuffering}
            style={{ width: 56, height: 56 }}
          />
          <Button
            size='large'
            type='text'
            icon={<StepForwardOutlined />}
            onClick={onSkipNext}
            disabled={!state?.currentQueueItemId || isLoading}
          />
        </Flex>

        {/* Volume Control */}
        <Flex
          align='center'
          gap='middle'
        >
          <SoundOutlined style={{ fontSize: 16 }} />
          <Slider
            value={volume}
            onChange={handleVolumeChange}
            min={0}
            max={100}
            style={{ flex: 1 }}
            tooltip={{ formatter: (value) => `${value}%` }}
          />
          <Text
            type='secondary'
            style={{ fontSize: 12, minWidth: 40 }}
          >
            {volume}%
          </Text>
        </Flex>
      </Space>
    </Card>
  );
};
