import 'dart:async';
import 'package:just_audio/just_audio.dart';

/// Wraps [AudioPlayer] from `just_audio` to provide a clean interface
/// for streaming audio (HLS, progressive MP3, etc.) throughout the app.
///
/// Singleton registered in DI – inject wherever audio playback is needed.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

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
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  ProcessingState get processingState => _player.processingState;

  // ── Controls ─────────────────────────────────────────────────────────────

  /// Load an audio source from a URL (supports HLS `.m3u8`, MP3, AAC, etc.).
  ///
  /// Returns the total duration if available.
  Future<Duration?> loadUrl(String url) async {
    final audioSource = AudioSource.uri(Uri.parse(url));
    return await _player.setAudioSource(audioSource);
  }

  /// Start / resume playback.
  Future<void> play() => _player.play();

  /// Pause playback.
  Future<void> pause() => _player.pause();

  /// Stop playback and reset position.
  Future<void> stop() => _player.stop();

  /// Seek to a specific position.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Set volume (0.0 – 1.0).
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Release resources. Call when the service is no longer needed.
  Future<void> dispose() => _player.dispose();
}
