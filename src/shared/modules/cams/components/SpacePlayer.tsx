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
  MutedOutlined,
} from '@ant-design/icons';
import { FastForwardOutlined, FastBackwardOutlined } from '@ant-design/icons';
import RepeatButton from '@/shared/modules/cams/components/RepeatButton';
import { HLS_PLAYER_CONFIG } from '../constants';
import {
  formatPlaybackTime,
  volumeToAudioLevel,
  getEffectiveSeekOffset,
} from '../utils';
import { storeHubService } from '../services/storeHubService';
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
  onVolumeChangeComplete?: (volume: number) => void;
  onToggleMute?: () => void;
  onRewind10?: () => void;
  onForward10?: () => void;
  isPreviousDisabled?: boolean;
  isNextDisabled?: boolean;
  onQueueEndBehaviorChange?: (next: number) => void;
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
  onVolumeChangeComplete,
  onToggleMute,
  onRewind10,
  onForward10,
  isPreviousDisabled,
  isNextDisabled,
  onQueueEndBehaviorChange,
}: SpacePlayerProps) => {
  const audioRef = useRef<HTMLAudioElement>(null);
  const hlsRef = useRef<Hls | null>(null);

  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState<number>(() =>
    typeof state?.volumePercent === 'number'
      ? Math.max(0, Math.min(100, Math.floor(state!.volumePercent)))
      : 75,
  );
  const [isBuffering, setIsBuffering] = useState(false);
  const [isMuted, setIsMuted] = useState<boolean>(() =>
    typeof state?.isMuted === 'boolean' ? state!.isMuted : false,
  );
  // Track if user is actively adjusting volume to avoid sync loops
  const isAdjustingVolumeRef = useRef(false);
  const adjustingVolumeTimeoutRef = useRef<number | null>(null);

  // ✅ Track if we're syncing from server to avoid feedback loops
  const isSyncingRef = useRef(false);
  // Key of the last state we fully processed — prevents re-processing the identical state
  // object but NEVER blocks a genuinely new state (e.g. from another client's command).
  const lastSyncedStateKeyRef = useRef<string | null>(null);
  // ✅ Track last pause time to detect long pause (need HLS reload)
  const lastPauseTimeRef = useRef<number | null>(null);
  // ✅ Store expected seek position after reload
  const pendingSeekRef = useRef<number | null>(null);
  // Always-current snapshot of the state prop — readable inside HLS/audio event closures.
  const stateRef = useRef<SpaceStateResponse | null | undefined>(state);
  useEffect(() => {
    stateRef.current = state;
  }, [state]);
  // Keep local seek authoritative briefly to avoid snap-back from stale server state.
  const localSeekLockRef = useRef<{
    targetSeconds: number;
    startedAtMs: number;
  } | null>(null);
  // True while user is actively dragging the seek slider (between onChange and onAfterChange).
  const isUserSeekingRef = useRef(false);
  // Delay remote seek after user releases slider
  const seekTimeoutRef = useRef<number | null>(null);
  const SEEK_API_DELAY_MS = 120;
  const LOCAL_SEEK_LOCK_MS = 3500;
  const LOCAL_SEEK_MATCH_TOLERANCE_SECONDS = 0.25;
  const POSITION_SYNC_TOLERANCE_SECONDS = 0.6;

  // Initialize HLS player
  useEffect(() => {
    console.log('🎯 HLS Effect triggered:', {
      hlsUrl: hlsUrl?.substring(0, 50),
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

        // Recompute seek offset fresh at manifest-ready time to avoid using a stale
        // pendingSeekRef that was calculated before the HLS load began.
        const seekTarget = (() => {
          if (pendingSeekRef.current !== null) {
            // Long-pause reload path: pendingSeekRef holds the expected position,
            // but we recompute it now so accumulated load time is accounted for.
            pendingSeekRef.current = null;
          }
          if (!stateRef.current) return null;
          return getEffectiveSeekOffset(
            stateRef.current,
            storeHubService.serverClockOffsetMs,
          );
        })();

        if (
          seekTarget !== null &&
          !Number.isNaN(seekTarget) &&
          seekTarget > 0
        ) {
          console.log(
            `⏩ MANIFEST_PARSED seek to ${seekTarget.toFixed(1)}s (clock-corrected)`,
          );
          audio.currentTime = seekTarget;
        }

        // DO NOT autoplay here based on stale isPlaying, we rely on the state sync effect
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

      // Apply pending seek for Safari — recompute fresh to account for load delay.
      if (pendingSeekRef.current !== null) {
        pendingSeekRef.current = null;
      }
      if (stateRef.current && !stateRef.current.isPaused) {
        const seekTarget = getEffectiveSeekOffset(
          stateRef.current,
          storeHubService.serverClockOffsetMs,
        );
        if (seekTarget > 0) {
          audio.currentTime = seekTarget;
        }
      }

      // DO NOT autoplay here based on stale isPlaying, we rely on the state sync effect
    } else {
      console.error('❌ HLS playback not supported in this browser');
      message.error('HLS playback not supported in this browser');
    }
  }, [hlsUrl]);

  // ✅ Sync audio playback state from server (SpaceStateSync)
  useEffect(() => {
    if (!audioRef.current || !state) return;

    const audio = audioRef.current;

    // Build a lightweight key representing the meaningful parts of this state.
    // Two renders with the same key are identical — no need to re-sync.
    const stateKey = [
      state.currentQueueItemId ?? '',
      state.isPaused ? '1' : '0',
      state.startedAtUtc ?? '',
      state.hlsUrl ?? '',
    ].join('|');

    // Re-entrant guard: skip only if we're mid-processing AND the state hasn't changed.
    if (isSyncingRef.current && lastSyncedStateKeyRef.current === stateKey) {
      console.log('⏭️ Already syncing same state, skipping...');
      return;
    }

    isSyncingRef.current = true;
    lastSyncedStateKeyRef.current = stateKey;

    // Handle pause state from server
    if (state.isPaused) {
      if (!audio.paused) {
        console.log('⏸️ Pausing playback');
        audio.pause();
        lastPauseTimeRef.current = Date.now();
      }
      // Sync to pause position
      if (
        state.pausePositionSeconds != null &&
        !Number.isNaN(state.pausePositionSeconds)
      ) {
        const target = state.pausePositionSeconds;
        if (Math.abs(audio.currentTime - target) > 0.3) {
          audio.currentTime = target;
        }
      }

      pendingSeekRef.current = null;
      isSyncingRef.current = false;
      return;
    }

    // Handle playing state from server
    // Pass the server clock offset so seek math matches mobile behaviour.
    const expectedPosition = getEffectiveSeekOffset(
      state,
      storeHubService.serverClockOffsetMs,
    );

    const localSeekLock = localSeekLockRef.current;
    if (localSeekLock) {
      const lockAgeMs = Date.now() - localSeekLock.startedAtMs;
      const serverCaughtUp =
        Math.abs(expectedPosition - localSeekLock.targetSeconds) <=
        LOCAL_SEEK_MATCH_TOLERANCE_SECONDS;

      if (serverCaughtUp || lockAgeMs > LOCAL_SEEK_LOCK_MS) {
        localSeekLockRef.current = null;

        // Keep the locally sought position when server has effectively caught up.
        // This avoids a final tiny snap on the same sync tick.
        if (serverCaughtUp) {
          isSyncingRef.current = false;
          return;
        }
      } else {
        // Ignore stale server position briefly after local seek to prevent UI jump-back.
        isSyncingRef.current = false;
        return;
      }
    }

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
      return;
    }

    // Normal resume — sync position if ready, otherwise schedule pending
    const canSeek = audio.readyState > 0 && !Number.isNaN(expectedPosition);

    if (canSeek) {
      const diff = Math.abs(audio.currentTime - expectedPosition);
      if (diff > POSITION_SYNC_TOLERANCE_SECONDS) {
        console.log(
          `🔄 Syncing position: ${audio.currentTime.toFixed(1)}s → ${expectedPosition.toFixed(1)}s (diff: ${diff.toFixed(1)}s)`,
        );
        audio.currentTime = expectedPosition;
      }
    } else {
      pendingSeekRef.current = expectedPosition;
    }

    if (audio.paused && isPlaying) {
      if (audio.duration > 0 && !Number.isNaN(audio.duration)) {
        console.log('▶️ Resuming playback');
        audio.play().catch((err) => {
          console.error('❌ Play failed:', err);
          setTimeout(() => {
            if (audioRef.current && audioRef.current.paused) {
              audioRef.current.play().catch(console.error);
            }
          }, 500);
        });
      } else {
        console.warn('⚠️ Audio not ready (no duration). Waiting for HLS...');
        const checkReady = setInterval(() => {
          if (audioRef.current && audioRef.current.duration > 0) {
            console.log('✅ Audio ready, playing now');
            clearInterval(checkReady);
            audioRef.current.play().catch(console.error);
          }
        }, 200);
        setTimeout(() => clearInterval(checkReady), 3000);
      }
    }

    lastPauseTimeRef.current = null;

    // Release re-entrant guard after a short window (prevents same-tick double-firing).
    setTimeout(() => {
      isSyncingRef.current = false;
    }, 150);
  }, [state, isPlaying, hlsUrl]);

  // Sync volume
  useEffect(() => {
    if (!audioRef.current) return;
    audioRef.current.volume = volumeToAudioLevel(volume);
  }, [volume]);

  // Sync volume/mute from server state
  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    if (!state) return;
    // Avoid overriding local adjustments while the user is actively dragging the slider
    if (
      !isAdjustingVolumeRef.current &&
      typeof state.volumePercent === 'number'
    ) {
      setVolume(Math.max(0, Math.min(100, Math.floor(state.volumePercent))));
    }
    if (typeof state.isMuted === 'boolean') {
      setIsMuted(state.isMuted);
    }
  }, [state]);
  /* eslint-enable react-hooks/set-state-in-effect */

  // Apply muted to audio element
  useEffect(() => {
    if (!audioRef.current) return;
    audioRef.current.muted = isMuted;
  }, [isMuted]);

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

      // Never override position while the user is dragging the slider or a local seek
      // lock is active. Applying the (stale) server position here would revert the seek.
      if (isUserSeekingRef.current || localSeekLockRef.current !== null) return;

      // Recompute seek offset fresh at canplay so accumulated buffer/load time is
      // factored in — avoids starting a few hundred ms behind due to a stale pendingSeekRef.
      if (audioRef.current) {
        if (pendingSeekRef.current !== null) {
          pendingSeekRef.current = null; // discard stale snapshot
        }
        const s = stateRef.current;
        if (s && !s.isPaused) {
          const seekTarget = getEffectiveSeekOffset(
            s,
            storeHubService.serverClockOffsetMs,
          );
          if (
            seekTarget > 0 &&
            Math.abs(audioRef.current.currentTime - seekTarget) > 0.3
          ) {
            console.log(
              `⏩ canplay seek to ${seekTarget.toFixed(1)}s (clock-corrected)`,
            );
            audioRef.current.currentTime = seekTarget;
          }
        } else if (s?.isPaused && s.pausePositionSeconds != null) {
          const target = s.pausePositionSeconds;
          if (Math.abs(audioRef.current.currentTime - target) > 0.3) {
            audioRef.current.currentTime = target;
          }
        }
      }
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

  // Handle seek (scrub) - immediate local scrub on change, remote seek on afterChange
  const handleSeek = (value: number) => {
    if (!audioRef.current) return;
    isUserSeekingRef.current = true; // mark drag in progress — blocks canplay from reverting
    const seekTime = (value / 100) * duration;
    audioRef.current.currentTime = seekTime;
    setCurrentTime(seekTime);
  };

  const handleSeekComplete = (value: number) => {
    if (!audioRef.current) return;
    isUserSeekingRef.current = false; // drag ended — lock takes over
    const seekTime = (value / 100) * duration;
    localSeekLockRef.current = {
      targetSeconds: seekTime,
      startedAtMs: Date.now(),
    };

    // Keep local audio at sought position immediately.
    audioRef.current.currentTime = seekTime;
    setCurrentTime(seekTime);

    // Debounce the remote seek call so server is called only after release
    if (seekTimeoutRef.current) {
      clearTimeout(seekTimeoutRef.current);
      seekTimeoutRef.current = null;
    }
    seekTimeoutRef.current = window.setTimeout(() => {
      onSeek?.(seekTime);
      seekTimeoutRef.current = null;
    }, SEEK_API_DELAY_MS);
  };

  // Cleanup pending seek timer on unmount
  useEffect(() => {
    return () => {
      if (seekTimeoutRef.current) {
        clearTimeout(seekTimeoutRef.current);
        seekTimeoutRef.current = null;
      }

      localSeekLockRef.current = null;
    };
  }, []);

  // Handle volume change
  const handleVolumeChange = (value: number) => {
    setVolume(value);
    // mark user adjusting to prevent server-sync from overriding during drag
    isAdjustingVolumeRef.current = true;
    if (adjustingVolumeTimeoutRef.current) {
      clearTimeout(adjustingVolumeTimeoutRef.current);
    }
    adjustingVolumeTimeoutRef.current = window.setTimeout(() => {
      isAdjustingVolumeRef.current = false;
      adjustingVolumeTimeoutRef.current = null;
      // Revert to server-confirmed volume — handles the case where the API call
      // failed (e.g. volumePercent out of allowed range) and no SignalR sync fired.
      const s = stateRef.current;
      if (typeof s?.volumePercent === 'number') {
        setVolume(Math.max(0, Math.min(100, Math.floor(s.volumePercent))));
      }
    }, 1200);
  };

  const handleVolumeChangeComplete = (value: number) => {
    onVolumeChangeComplete?.(value);
    // Also call the generic onVolumeChange for backwards compatibility
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
        <div
          title='Seek: drag to scrub, release to send seek'
          aria-label='Seek control'
        >
          <Slider
            value={progress}
            onChange={handleSeek}
            onAfterChange={handleSeekComplete}
            aria-label='Seek'
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

        {/* Playback Controls with RepeatButton at far left */}
        <Flex
          justify='space-between'
          align='center'
          style={{ width: '100%' }}
        >
          {/* Left: Repeat control, visually aligned with other controls */}
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <RepeatButton
              queueEndBehavior={state?.queueEndBehavior ?? 0}
              onChange={(next) => {
                // bubble to parent if provided
                onQueueEndBehaviorChange?.(Number(next));
              }}
              size={20}
              className={'mr-2'}
            />
          </div>

          {/* Center: main playback controls */}
          <Flex
            justify='center'
            align='center'
            gap='middle'
          >
            <Button
              size='large'
              type='text'
              icon={<FastBackwardOutlined />}
              onClick={() => onRewind10?.()}
              disabled={isLoading || !state?.currentQueueItemId}
              title='Rewind 10 seconds'
              aria-label='Rewind 10 seconds'
            />
            <Button
              size='large'
              type='text'
              icon={<StepBackwardOutlined />}
              onClick={onSkipPrevious}
              title='Skip to previous track'
              aria-label='Skip to previous track'
              disabled={
                isLoading ||
                (typeof isPreviousDisabled === 'boolean'
                  ? isPreviousDisabled
                  : !state?.currentQueueItemId)
              }
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
              title={isPlaying ? 'Pause' : 'Resume'}
              aria-label={isPlaying ? 'Pause' : 'Resume'}
            />
            <Button
              size='large'
              type='text'
              icon={<StepForwardOutlined />}
              onClick={onSkipNext}
              title='Skip to next track'
              aria-label='Skip to next track'
              disabled={
                isLoading ||
                (typeof isNextDisabled === 'boolean'
                  ? isNextDisabled
                  : !state?.currentQueueItemId)
              }
            />
            <Button
              size='large'
              type='text'
              icon={<FastForwardOutlined />}
              onClick={() => onForward10?.()}
              disabled={isLoading || !state?.currentQueueItemId}
              title='Forward 10 seconds'
              aria-label='Forward 10 seconds'
            />
          </Flex>

          {/* Right placeholder for visual balance (keeps center centered) */}
          <div style={{ width: 40 }} />
        </Flex>

        {/* Volume Control */}
        <Flex
          align='center'
          gap='middle'
        >
          <Button
            type='text'
            icon={
              isMuted ? (
                <MutedOutlined style={{ fontSize: 16, color: '#ff4d4f' }} />
              ) : (
                <SoundOutlined style={{ fontSize: 16 }} />
              )
            }
            onClick={() => {
              // local toggle for instant feedback; server will sync via spaceState
              setIsMuted((m) => !m);
              onToggleMute?.();
            }}
            title={isMuted ? 'Unmute' : 'Mute'}
            aria-label={isMuted ? 'Unmute' : 'Mute'}
          />
          <Slider
            value={volume}
            onChange={handleVolumeChange}
            onAfterChange={handleVolumeChangeComplete}
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
