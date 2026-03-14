import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Wraps [AudioPlayer] from `just_audio` to provide a clean interface
/// for streaming audio (HLS, progressive MP3, etc.) throughout the app.
///
/// Singleton registered in DI – inject wherever audio playback is needed.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  // ── Streams ──────────────────────────────────────────────────────────────

  /// Current playback position as a [Duration].
  Stream<Duration> get positionStream => _player.positionStream;

  /// Buffered position (how far the audio has been downloaded/buffered).
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Total duration of the current audio source (may be null for live streams).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Processing state changes (idle, loading, buffering, ready, completed).
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  /// Whether audio is currently playing.
  Stream<bool> get playingStream => _player.playingStream;

  /// Combined player state (playing + processingState).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ── Getters ──────────────────────────────────────────────────────────────

  Duration get position => _player.position;
  Duration get bufferedPosition => _player.bufferedPosition;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  ProcessingState get processingState => _player.processingState;

  // ── Controls ─────────────────────────────────────────────────────────────

  /// Configures the platform audio session for long-running music playback.
  Future<void> configureForBackgroundPlayback() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _session = session;
    _becomingNoisySub ??= session.becomingNoisyEventStream.listen((_) {
      if (_player.playing) {
        unawaited(_player.pause());
      }
    });
    _interruptionSub ??= session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            unawaited(_player.setVolume(0.5));
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            unawaited(_player.pause());
            break;
        }
        return;
      }

      if (event.type == AudioInterruptionType.duck) {
        unawaited(_player.setVolume(1.0));
      }
    });
  }

  /// Load an audio source from a URL (supports HLS `.m3u8`, MP3, AAC, etc.).
  ///
  /// Returns the total duration if available.
  Future<Duration?> loadUrl(String url) async {
    final audioSource = AudioSource.uri(Uri.parse(url));
    return await _player.setAudioSource(audioSource);
  }

  /// Start / resume playback.
  Future<void> play() async {
    await _session?.setActive(true);
    await _player.play();
  }

  /// Pause playback.
  Future<void> pause() => _player.pause();

  /// Stop playback and reset position.
  Future<void> stop() async {
    await _player.stop();
    await _session?.setActive(false);
  }

  /// Seek to a specific position.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Set volume (0.0 – 1.0).
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Release resources. Call when the service is no longer needed.
  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _session?.setActive(false);
    await _player.dispose();
  }
}
