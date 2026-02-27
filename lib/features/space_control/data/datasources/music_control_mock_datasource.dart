import 'dart:async';
import 'dart:convert';
import '../models/music_player_state_model.dart';
import '../models/track_model.dart';
import 'music_control_remote_datasource.dart';

/// Mock implementation of MusicControlRemoteDataSource for development
/// Simulates music control without requiring API server or MQTT broker
class MusicControlMockDataSource implements MusicControlRemoteDataSource {
  final _playerStateController =
      StreamController<MusicPlayerStateModel>.broadcast();
  Timer? _mockTimer;

  // Mock player state
  bool _isPlaying = true;
  int _currentTrackIndex = 0;
  final List<TrackModel> _mockPlaylist = [
    const TrackModel(
      id: 'track-001',
      title: 'Upbeat Retail Mix Vol.3',
      artist: 'Retail Music Co.',
      fileUrl: 'https://example.com/track001.mp3',
      moodTags: ['energetic', 'upbeat'],
      duration: 245,
    ),
    const TrackModel(
      id: 'track-002',
      title: 'Smooth Shopping Vibes',
      artist: 'Ambient Retail',
      fileUrl: 'https://example.com/track002.mp3',
      moodTags: ['calm', 'ambient'],
      duration: 198,
    ),
    const TrackModel(
      id: 'track-003',
      title: 'Happy Store Atmosphere',
      artist: 'Retail Sounds',
      fileUrl: 'https://example.com/track003.mp3',
      moodTags: ['happy', 'cheerful'],
      duration: 212,
    ),
  ];

  @override
  Future<void> overrideMood({
    required String spaceId,
    required String moodId,
    required int duration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock mood override - in real app would trigger playlist change
    print(
        'Mock: Overriding mood to $moodId for $duration minutes in space $spaceId');
  }

  @override
  Future<void> sendMusicControl(String spaceId, String action) async {
    await Future.delayed(const Duration(milliseconds: 150));

    switch (action) {
      case 'play':
        _isPlaying = true;
        break;
      case 'pause':
        _isPlaying = false;
        break;
      case 'skip':
        _currentTrackIndex = (_currentTrackIndex + 1) % _mockPlaylist.length;
        break;
    }

    // Emit updated state
    _emitCurrentState();
  }

  @override
  Stream<MusicPlayerStateModel> subscribeMusicPlayerState(
    String storeId,
    String spaceId,
  ) {
    // Start periodic updates
    _startMockUpdates();
    return _playerStateController.stream;
  }

  @override
  void unsubscribeMusicPlayerState(String storeId, String spaceId) {
    _mockTimer?.cancel();
  }

  void _startMockUpdates() {
    _mockTimer?.cancel();

    // Send initial state
    _emitCurrentState();

    // Send periodic updates (simulate playback progress)
    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _emitCurrentState();
    });
  }

  void _emitCurrentState() {
    final currentTrack = _mockPlaylist[_currentTrackIndex];

    final state = MusicPlayerStateModel(
      currentTrack: currentTrack,
      status: _isPlaying ? 'playing' : 'paused',
      currentPosition: 0,
      isPlayingFromCache: false,
    );

    _playerStateController.add(state);
  }

  void dispose() {
    _mockTimer?.cancel();
    _playerStateController.close();
  }
}
