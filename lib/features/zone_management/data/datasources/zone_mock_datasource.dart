import '../models/zone_model.dart';
import '../models/music_profile_model.dart';
import '../models/playlist_model.dart';
import '../models/speaker_model.dart';
import '../../../space_control/data/models/track_model.dart';

/// Mock data source for zone management
/// Provides realistic demo data for zones, music profiles, playlists, and speakers
class ZoneMockDataSource {
  // ==================== ZONES ====================

  /// Get all zones for a specific space
  Future<List<ZoneModel>> getZonesBySpace(String spaceId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Main Floor has 3 zones
    if (spaceId == 'space-1') {
      return [
        ZoneModel(
          id: 'zone-001',
          name: 'Entrance Section',
          spaceId: spaceId,
          floorLevel: 'Ground',
          speakerIds: const ['speaker-001', 'speaker-002'],
          musicProfileId: 'profile-001',
          boundary: 'Near main entrance doors and welcome area',
          isActive: true,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 2, 1),
        ),
        ZoneModel(
          id: 'zone-002',
          name: 'Center Display',
          spaceId: spaceId,
          floorLevel: 'Ground',
          speakerIds: const ['speaker-003', 'speaker-004', 'speaker-005'],
          musicProfileId: 'profile-002',
          boundary: 'Main shopping area with product displays',
          isActive: true,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 2, 1),
        ),
        ZoneModel(
          id: 'zone-003',
          name: 'Checkout Area',
          spaceId: spaceId,
          floorLevel: 'Ground',
          speakerIds: const ['speaker-006', 'speaker-007'],
          musicProfileId: 'profile-003',
          boundary: 'Cashier counters and waiting area',
          isActive: true,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 2, 1),
        ),
      ];
    }

    // VIP Lounge has 2 zones
    if (spaceId == 'space-2') {
      return [
        ZoneModel(
          id: 'zone-004',
          name: 'Seating Area',
          spaceId: spaceId,
          floorLevel: null,
          speakerIds: const ['speaker-008', 'speaker-009'],
          musicProfileId: 'profile-004',
          boundary: 'Comfortable seating with sofas',
          isActive: true,
          createdAt: DateTime(2024, 1, 20),
        ),
        ZoneModel(
          id: 'zone-005',
          name: 'Consultation Room',
          spaceId: spaceId,
          floorLevel: null,
          speakerIds: const ['speaker-010'],
          musicProfileId: 'profile-005',
          boundary: 'Private consultation area',
          isActive: true,
          createdAt: DateTime(2024, 1, 20),
        ),
      ];
    }

    // Other spaces have single zone
    return [
      ZoneModel(
        id: 'zone-default-$spaceId',
        name: 'Main Area',
        spaceId: spaceId,
        floorLevel: null,
        speakerIds: const ['speaker-default'],
        musicProfileId: 'profile-default',
        boundary: 'Entire space',
        isActive: true,
        createdAt: DateTime(2024, 1, 10),
      ),
    ];
  }

  // ==================== MUSIC PROFILES ====================

  /// Get music profile by zone ID
  Future<MusicProfileModel> getMusicProfileByZone(String zoneId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final profiles = {
      // Entrance Section - Welcoming mood
      'profile-001': MusicProfileModel(
        id: 'profile-001',
        name: 'Welcome & Greet',
        zoneId: 'zone-001',
        playlistIds: const ['playlist-001', 'playlist-002', 'playlist-009'],
        moodToPlaylistMap: const {
          'welcoming': 'playlist-001',
          'happy': 'playlist-002',
          'calm': 'playlist-009',
          'energetic': 'playlist-003',
        },
        volumeSettings: const VolumeSettingsModel(
          defaultVolume: 65,
          minVolume: 50,
          maxVolume: 80,
          autoAdjust: true,
        ),
        scheduleConfig: ScheduleConfigModel(
          enabled: true,
          timeSlots: [
            const TimeSlotModel(
              startTime: '07:00',
              endTime: '11:00',
              playlistId: 'playlist-009', // Calm morning
              moodOverride: 'calm',
              daysOfWeek: [1, 2, 3, 4, 5], // Weekdays
            ),
            const TimeSlotModel(
              startTime: '11:00',
              endTime: '16:00',
              playlistId: 'playlist-001', // Welcoming afternoon
              daysOfWeek: [],
            ),
            const TimeSlotModel(
              startTime: '16:00',
              endTime: '20:00',
              playlistId: 'playlist-002', // Happy evening
              daysOfWeek: [],
            ),
          ],
        ),
        autoMoodDetection: true,
        offlineFallbackPlaylistId: 'playlist-001',
        isActive: true,
        createdAt: DateTime(2024, 1, 15),
      ),

      // Center Display - Energetic mood
      'profile-002': MusicProfileModel(
        id: 'profile-002',
        name: 'Shopping Energy',
        zoneId: 'zone-002',
        playlistIds: const ['playlist-003', 'playlist-004', 'playlist-005'],
        moodToPlaylistMap: const {
          'energetic': 'playlist-003',
          'happy': 'playlist-004',
          'focused': 'playlist-005',
          'welcoming': 'playlist-001',
        },
        volumeSettings: const VolumeSettingsModel(
          defaultVolume: 70,
          minVolume: 60,
          maxVolume: 85,
          autoAdjust: true,
        ),
        scheduleConfig: ScheduleConfigModel(
          enabled: true,
          timeSlots: [
            const TimeSlotModel(
              startTime: '09:00',
              endTime: '12:00',
              playlistId: 'playlist-003', // Energetic morning
              daysOfWeek: [],
            ),
            const TimeSlotModel(
              startTime: '12:00',
              endTime: '18:00',
              playlistId: 'playlist-004', // Happy peak hours
              daysOfWeek: [],
            ),
            const TimeSlotModel(
              startTime: '18:00',
              endTime: '21:00',
              playlistId: 'playlist-005', // Focused evening
              daysOfWeek: [],
            ),
          ],
        ),
        autoMoodDetection: true,
        offlineFallbackPlaylistId: 'playlist-003',
        isActive: true,
        createdAt: DateTime(2024, 1, 15),
      ),

      // Checkout Area - Calm mood
      'profile-003': MusicProfileModel(
        id: 'profile-003',
        name: 'Calm Checkout',
        zoneId: 'zone-003',
        playlistIds: const ['playlist-006', 'playlist-007', 'playlist-009'],
        moodToPlaylistMap: const {
          'calm': 'playlist-006',
          'relaxed': 'playlist-007',
          'welcoming': 'playlist-009',
          'happy': 'playlist-002',
        },
        volumeSettings: const VolumeSettingsModel(
          defaultVolume: 55,
          minVolume: 45,
          maxVolume: 70,
          autoAdjust: false, // Keep consistent volume at checkout
        ),
        scheduleConfig: null, // No schedule - always calm
        autoMoodDetection: true,
        offlineFallbackPlaylistId: 'playlist-006',
        isActive: true,
        createdAt: DateTime(2024, 1, 15),
      ),

      // VIP Seating - Relaxed mood
      'profile-004': MusicProfileModel(
        id: 'profile-004',
        name: 'VIP Lounge Experience',
        zoneId: 'zone-004',
        playlistIds: const ['playlist-007', 'playlist-008', 'playlist-010'],
        moodToPlaylistMap: const {
          'relaxed': 'playlist-007',
          'calm': 'playlist-008',
          'focused': 'playlist-010',
        },
        volumeSettings: const VolumeSettingsModel(
          defaultVolume: 50,
          minVolume: 40,
          maxVolume: 65,
          autoAdjust: false,
        ),
        scheduleConfig: null,
        autoMoodDetection: false, // Manual control for VIP
        offlineFallbackPlaylistId: 'playlist-007',
        isActive: true,
        createdAt: DateTime(2024, 1, 20),
      ),

      // Consultation Room - Very calm
      'profile-005': MusicProfileModel(
        id: 'profile-005',
        name: 'Private Consultation',
        zoneId: 'zone-005',
        playlistIds: const ['playlist-008', 'playlist-011'],
        moodToPlaylistMap: const {
          'calm': 'playlist-008',
          'relaxed': 'playlist-011',
        },
        volumeSettings: const VolumeSettingsModel(
          defaultVolume: 40,
          minVolume: 30,
          maxVolume: 55,
          autoAdjust: false,
        ),
        scheduleConfig: null,
        autoMoodDetection: false,
        offlineFallbackPlaylistId: 'playlist-008',
        isActive: true,
        createdAt: DateTime(2024, 1, 20),
      ),
    };

    return profiles[zoneId] ?? _getDefaultProfile(zoneId);
  }

  MusicProfileModel _getDefaultProfile(String zoneId) {
    return MusicProfileModel(
      id: 'profile-default',
      name: 'Default Profile',
      zoneId: zoneId,
      playlistIds: const ['playlist-001'],
      moodToPlaylistMap: const {'calm': 'playlist-001'},
      volumeSettings: const VolumeSettingsModel(
        defaultVolume: 60,
        minVolume: 40,
        maxVolume: 80,
        autoAdjust: true,
      ),
      scheduleConfig: null,
      autoMoodDetection: true,
      offlineFallbackPlaylistId: 'playlist-001',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  // ==================== PLAYLISTS ====================

  /// Get all available playlists
  Future<List<PlaylistModel>> getAllPlaylists() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPlaylists;
  }

  /// Get playlist by ID
  Future<PlaylistModel> getPlaylistById(String playlistId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockPlaylists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => _mockPlaylists.first,
    );
  }

  static final List<PlaylistModel> _mockPlaylists = [
    // 1. Welcoming Playlists
    PlaylistModel(
      id: 'playlist-001',
      name: 'Welcome Vibes',
      description: 'Uplifting and friendly music to greet customers',
      tracks: [
        const TrackModel(
          id: 'track-001',
          title: 'Good Day Sunshine',
          artist: 'Retail Mix Artists',
          fileUrl: 'https://example.com/tracks/001.mp3',
          localPath: '/cache/tracks/001.mp3',
          moodTags: ['welcoming', 'happy'],
          duration: 195,
          albumArt: 'https://example.com/art/001.jpg',
        ),
        const TrackModel(
          id: 'track-002',
          title: 'Morning Breeze',
          artist: 'Ambient Collective',
          fileUrl: 'https://example.com/tracks/002.mp3',
          localPath: '/cache/tracks/002.mp3',
          moodTags: ['welcoming', 'calm'],
          duration: 210,
        ),
        const TrackModel(
          id: 'track-003',
          title: 'Friendly Faces',
          artist: 'Store Sounds',
          fileUrl: 'https://example.com/tracks/003.mp3',
          moodTags: ['welcoming'],
          duration: 188,
        ),
      ],
      moodTags: const ['welcoming', 'happy'],
      genre: 'Retail Pop',
      coverArt: 'https://example.com/covers/playlist-001.jpg',
      totalDuration: 593,
      isAvailableOffline: true,
      playCount: 156,
      createdAt: DateTime(2024, 1, 10),
    ),

    PlaylistModel(
      id: 'playlist-002',
      name: 'Happy Shopping',
      description:
          'Upbeat and joyful tracks for a positive shopping experience',
      tracks: [
        const TrackModel(
          id: 'track-004',
          title: 'Smile & Shop',
          artist: 'Happy Beats',
          fileUrl: 'https://example.com/tracks/004.mp3',
          localPath: '/cache/tracks/004.mp3',
          moodTags: ['happy', 'energetic'],
          duration: 200,
        ),
        const TrackModel(
          id: 'track-005',
          title: 'Joy Ride',
          artist: 'Positive Vibes',
          fileUrl: 'https://example.com/tracks/005.mp3',
          moodTags: ['happy'],
          duration: 225,
        ),
      ],
      moodTags: const ['happy', 'welcoming'],
      genre: 'Pop',
      totalDuration: 425,
      isAvailableOffline: false,
      playCount: 89,
      createdAt: DateTime(2024, 1, 12),
    ),

    // 2. Energetic Playlists
    PlaylistModel(
      id: 'playlist-003',
      name: 'Upbeat Retail Mix Vol.3',
      description: 'High-energy music to boost shopping momentum',
      tracks: [
        const TrackModel(
          id: 'track-006',
          title: 'Power Shopping',
          artist: 'Energy Mix',
          fileUrl: 'https://example.com/tracks/006.mp3',
          localPath: '/cache/tracks/006.mp3',
          moodTags: ['energetic'],
          duration: 180,
        ),
        const TrackModel(
          id: 'track-007',
          title: 'Momentum',
          artist: 'Dynamic Sounds',
          fileUrl: 'https://example.com/tracks/007.mp3',
          localPath: '/cache/tracks/007.mp3',
          moodTags: ['energetic', 'focused'],
          duration: 195,
        ),
        const TrackModel(
          id: 'track-008',
          title: 'Drive',
          artist: 'Tempo Masters',
          fileUrl: 'https://example.com/tracks/008.mp3',
          moodTags: ['energetic'],
          duration: 210,
        ),
      ],
      moodTags: const ['energetic', 'happy'],
      genre: 'Electronic Pop',
      totalDuration: 585,
      isAvailableOffline: true,
      playCount: 234,
      createdAt: DateTime(2024, 1, 8),
    ),

    PlaylistModel(
      id: 'playlist-004',
      name: 'Peak Hours Energy',
      description: 'Dynamic tracks for busy shopping periods',
      tracks: [
        const TrackModel(
          id: 'track-009',
          title: 'Rush Hour',
          artist: 'Beat Makers',
          fileUrl: 'https://example.com/tracks/009.mp3',
          moodTags: ['energetic', 'happy'],
          duration: 205,
        ),
        const TrackModel(
          id: 'track-010',
          title: 'On The Move',
          artist: 'Active Mix',
          fileUrl: 'https://example.com/tracks/010.mp3',
          moodTags: ['energetic'],
          duration: 190,
        ),
      ],
      moodTags: const ['energetic'],
      genre: 'Dance Pop',
      totalDuration: 395,
      isAvailableOffline: false,
      playCount: 167,
      createdAt: DateTime(2024, 1, 15),
    ),

    PlaylistModel(
      id: 'playlist-005',
      name: 'Focused Shopper',
      description: 'Moderate energy to maintain shopping focus',
      tracks: [
        const TrackModel(
          id: 'track-011',
          title: 'Concentration',
          artist: 'Focus Sounds',
          fileUrl: 'https://example.com/tracks/011.mp3',
          localPath: '/cache/tracks/011.mp3',
          moodTags: ['focused', 'calm'],
          duration: 240,
        ),
        const TrackModel(
          id: 'track-012',
          title: 'Steady Pace',
          artist: 'Rhythm Group',
          fileUrl: 'https://example.com/tracks/012.mp3',
          moodTags: ['focused'],
          duration: 220,
        ),
      ],
      moodTags: const ['focused', 'energetic'],
      genre: 'Instrumental',
      totalDuration: 460,
      isAvailableOffline: true,
      playCount: 98,
      createdAt: DateTime(2024, 1, 18),
    ),

    // 3. Calm Playlists
    PlaylistModel(
      id: 'playlist-006',
      name: 'Smooth Checkout',
      description: 'Calming music to ease the checkout experience',
      tracks: [
        const TrackModel(
          id: 'track-013',
          title: 'Easy Flow',
          artist: 'Calm Collective',
          fileUrl: 'https://example.com/tracks/013.mp3',
          localPath: '/cache/tracks/013.mp3',
          moodTags: ['calm'],
          duration: 255,
        ),
        const TrackModel(
          id: 'track-014',
          title: 'Peaceful Moments',
          artist: 'Serenity Sounds',
          fileUrl: 'https://example.com/tracks/014.mp3',
          localPath: '/cache/tracks/014.mp3',
          moodTags: ['calm', 'relaxed'],
          duration: 270,
        ),
      ],
      moodTags: const ['calm'],
      genre: 'Ambient',
      totalDuration: 525,
      isAvailableOffline: true,
      playCount: 145,
      createdAt: DateTime(2024, 1, 11),
    ),

    PlaylistModel(
      id: 'playlist-007',
      name: 'Relaxed Atmosphere',
      description: 'Gentle music for a comfortable shopping environment',
      tracks: [
        const TrackModel(
          id: 'track-015',
          title: 'Soft Touch',
          artist: 'Lounge Artists',
          fileUrl: 'https://example.com/tracks/015.mp3',
          moodTags: ['relaxed'],
          duration: 300,
        ),
        const TrackModel(
          id: 'track-016',
          title: 'Comfort Zone',
          artist: 'Easy Listening',
          fileUrl: 'https://example.com/tracks/016.mp3',
          localPath: '/cache/tracks/016.mp3',
          moodTags: ['relaxed', 'calm'],
          duration: 285,
        ),
      ],
      moodTags: const ['relaxed'],
      genre: 'Lounge',
      totalDuration: 585,
      isAvailableOffline: false,
      playCount: 123,
      createdAt: DateTime(2024, 1, 14),
    ),

    PlaylistModel(
      id: 'playlist-008',
      name: 'Quiet Luxury',
      description: 'Sophisticated calm music for premium experiences',
      tracks: [
        const TrackModel(
          id: 'track-017',
          title: 'Elegance',
          artist: 'Classical Modern',
          fileUrl: 'https://example.com/tracks/017.mp3',
          localPath: '/cache/tracks/017.mp3',
          moodTags: ['calm', 'focused'],
          duration: 320,
        ),
        const TrackModel(
          id: 'track-018',
          title: 'Refined Taste',
          artist: 'Jazz Ensemble',
          fileUrl: 'https://example.com/tracks/018.mp3',
          moodTags: ['calm'],
          duration: 340,
        ),
      ],
      moodTags: const ['calm', 'relaxed'],
      genre: 'Jazz',
      totalDuration: 660,
      isAvailableOffline: true,
      playCount: 78,
      createdAt: DateTime(2024, 1, 20),
    ),

    // 4. Morning/Special Time Playlists
    PlaylistModel(
      id: 'playlist-009',
      name: 'Morning Fresh',
      description: 'Light and refreshing music for morning hours',
      tracks: [
        const TrackModel(
          id: 'track-019',
          title: 'New Day',
          artist: 'Dawn Sounds',
          fileUrl: 'https://example.com/tracks/019.mp3',
          localPath: '/cache/tracks/019.mp3',
          moodTags: ['calm', 'welcoming'],
          duration: 230,
        ),
        const TrackModel(
          id: 'track-020',
          title: 'Sunrise Melody',
          artist: 'Morning Vibes',
          fileUrl: 'https://example.com/tracks/020.mp3',
          moodTags: ['calm', 'happy'],
          duration: 245,
        ),
      ],
      moodTags: const ['calm', 'welcoming'],
      genre: 'Acoustic',
      totalDuration: 475,
      isAvailableOffline: true,
      playCount: 201,
      createdAt: DateTime(2024, 1, 9),
    ),

    PlaylistModel(
      id: 'playlist-010',
      name: 'Premium Selection',
      description: 'Curated tracks for VIP and premium areas',
      tracks: [
        const TrackModel(
          id: 'track-021',
          title: 'Distinguished',
          artist: 'Premium Sounds',
          fileUrl: 'https://example.com/tracks/021.mp3',
          moodTags: ['focused', 'calm'],
          duration: 280,
        ),
        const TrackModel(
          id: 'track-022',
          title: 'Prestige',
          artist: 'Elite Mix',
          fileUrl: 'https://example.com/tracks/022.mp3',
          localPath: '/cache/tracks/022.mp3',
          moodTags: ['relaxed'],
          duration: 310,
        ),
      ],
      moodTags: const ['focused', 'relaxed'],
      genre: 'Contemporary',
      totalDuration: 590,
      isAvailableOffline: false,
      playCount: 56,
      createdAt: DateTime(2024, 1, 22),
    ),

    PlaylistModel(
      id: 'playlist-011',
      name: 'Consultation Ambience',
      description: 'Very subtle background music for conversations',
      tracks: [
        const TrackModel(
          id: 'track-023',
          title: 'Whisper',
          artist: 'Ambient Masters',
          fileUrl: 'https://example.com/tracks/023.mp3',
          localPath: '/cache/tracks/023.mp3',
          moodTags: ['calm'],
          duration: 360,
        ),
        const TrackModel(
          id: 'track-024',
          title: 'Subtle Notes',
          artist: 'Background Sounds',
          fileUrl: 'https://example.com/tracks/024.mp3',
          moodTags: ['relaxed', 'calm'],
          duration: 380,
        ),
      ],
      moodTags: const ['calm', 'relaxed'],
      genre: 'Minimal',
      totalDuration: 740,
      isAvailableOffline: true,
      playCount: 34,
      createdAt: DateTime(2024, 1, 23),
    ),
  ];

  // ==================== SPEAKERS ====================

  /// Get speakers by zone ID
  Future<List<SpeakerModel>> getSpeakersByZone(String zoneId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final speakerMap = {
      'zone-001': [
        SpeakerModel(
          id: 'speaker-001',
          name: 'Entrance Left',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.101',
          isOnline: true,
          currentVolume: 65,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 50,
            supportedFormats: ['mp3', 'aac', 'wav'],
            supportsStereo: true,
            frequencyRange: '50Hz-20kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
          firmwareVersion: '2.4.1',
        ),
        SpeakerModel(
          id: 'speaker-002',
          name: 'Entrance Right',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.102',
          isOnline: true,
          currentVolume: 65,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 50,
            supportedFormats: ['mp3', 'aac', 'wav'],
            supportsStereo: true,
            frequencyRange: '50Hz-20kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
          firmwareVersion: '2.4.1',
        ),
      ],
      'zone-002': [
        SpeakerModel(
          id: 'speaker-003',
          name: 'Center Front',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.103',
          isOnline: true,
          currentVolume: 70,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 75,
            supportedFormats: ['mp3', 'aac', 'flac'],
            supportsStereo: true,
            frequencyRange: '40Hz-22kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 1)),
          firmwareVersion: '2.5.0',
        ),
        SpeakerModel(
          id: 'speaker-004',
          name: 'Center Back',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.104',
          isOnline: true,
          currentVolume: 70,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 75,
            supportedFormats: ['mp3', 'aac', 'flac'],
            supportsStereo: true,
            frequencyRange: '40Hz-22kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 1)),
          firmwareVersion: '2.5.0',
        ),
        SpeakerModel(
          id: 'speaker-005',
          name: 'Center Ceiling',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.105',
          isOnline: false, // Offline for demo
          currentVolume: 0,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 60,
            supportedFormats: ['mp3', 'aac'],
            supportsStereo: false,
            frequencyRange: '60Hz-18kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 3)),
          firmwareVersion: '2.4.0',
        ),
      ],
      'zone-003': [
        SpeakerModel(
          id: 'speaker-006',
          name: 'Checkout Counter 1',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.106',
          isOnline: true,
          currentVolume: 55,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 40,
            supportedFormats: ['mp3', 'aac'],
            supportsStereo: true,
            frequencyRange: '60Hz-18kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
          firmwareVersion: '2.4.1',
        ),
        SpeakerModel(
          id: 'speaker-007',
          name: 'Checkout Counter 2',
          zoneId: zoneId,
          hubId: 'hub-001',
          ipAddress: '192.168.1.107',
          isOnline: true,
          currentVolume: 55,
          capabilities: const SpeakerCapabilitiesModel(
            maxPowerWatts: 40,
            supportedFormats: ['mp3', 'aac'],
            supportsStereo: true,
            frequencyRange: '60Hz-18kHz',
          ),
          lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
          firmwareVersion: '2.4.1',
        ),
      ],
    };

    return speakerMap[zoneId] ?? [];
  }
}
