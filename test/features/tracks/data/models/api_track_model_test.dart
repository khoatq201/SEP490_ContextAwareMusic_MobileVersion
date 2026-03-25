import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/music_provider_enum.dart';
import 'package:cams_store_manager/features/tracks/data/models/api_track_model.dart';
import 'package:cams_store_manager/features/tracks/domain/entities/track_metadata_status.dart';

void main() {
  group('ApiTrackModel', () {
    test('reads hlsUrl when present', () {
      final model = ApiTrackModel.fromJson(const {
        'id': 'track-1',
        'title': 'Track 1',
        'hlsUrl': 'https://example.com/t1.m3u8',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.hlsUrl, 'https://example.com/t1.m3u8');
    });

    test('falls back to audioUrl for backward compatibility', () {
      final model = ApiTrackModel.fromJson(const {
        'id': 'track-2',
        'title': 'Track 2',
        'audioUrl': 'https://example.com/legacy-track.mp3',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.hlsUrl, 'https://example.com/legacy-track.mp3');
    });

    test('parses enriched metadata payload and explicit metadata status', () {
      final model = ApiTrackModel.fromJson(const {
        'id': 'track-3',
        'title': 'AI Track',
        'artist': 'Suno',
        'provider': 'suno',
        'bpm': 128,
        'energyLevel': 0.82,
        'valence': 0.61,
        'hlsUrl': 'https://example.com/ai-track.m3u8',
        'sourceAudioUrl': 'https://example.com/ai-track.wav',
        'transcodeStatus': 'processing',
        'isAiGenerated': true,
        'sunoClipId': 'clip-77',
        'generationPrompt': 'shimmering synthwave',
        'generatedAt': '2026-03-24T08:15:00Z',
        'lyricsUrl': 'https://example.com/lyrics.txt',
        'lastPlayedAt': '2026-03-24T09:00:00Z',
        'metadataStatus': 'metadataPending',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.provider, MusicProviderEnum.suno);
      expect(model.bpm, 128);
      expect(model.energyLevel, 0.82);
      expect(model.valence, 0.61);
      expect(model.hlsUrl, 'https://example.com/ai-track.m3u8');
      expect(model.sourceAudioUrl, 'https://example.com/ai-track.wav');
      expect(model.transcodeStatus, 'processing');
      expect(model.isAiGenerated, isTrue);
      expect(model.sunoClipId, 'clip-77');
      expect(model.generationPrompt, 'shimmering synthwave');
      expect(model.generatedAt, DateTime.parse('2026-03-24T08:15:00Z'));
      expect(model.lyricsUrl, 'https://example.com/lyrics.txt');
      expect(model.lastPlayedAt, DateTime.parse('2026-03-24T09:00:00Z'));
      expect(model.metadataStatus, TrackMetadataStatus.metadataPending);
    });

    test('derives metadata status from metadata fields when override is absent',
        () {
      final model = ApiTrackModel.fromJson(const {
        'id': 'track-4',
        'title': 'Metadata Ready',
        'provider': 1,
        'generatedAt': '2026-03-24T10:00:00Z',
        'createdAt': '2026-03-24T08:00:00Z',
      });

      expect(model.provider, MusicProviderEnum.suno);
      expect(model.hasMeaningfulMetadata, isTrue);
      expect(model.metadataStatus, TrackMetadataStatus.metadataReady);
    });

    test('marks stale metadata-less tracks as metadataUnknown', () {
      final model = ApiTrackModel.fromJson(const {
        'id': 'track-5',
        'title': 'Old Track',
        'hlsUrl': 'https://example.com/ready-track.m3u8',
        'createdAt': '2026-01-01T00:00:00Z',
      });

      expect(model.isStreamReady, isTrue);
      expect(model.metadataStatus, TrackMetadataStatus.metadataUnknown);
    });
  });
}
