import '../models/schedule_music_item_model.dart';
import '../models/schedule_source_model.dart';
import '../models/schedule_slot_model.dart';
import '../models/space_schedule_model.dart';
import '../../domain/entities/schedule_source.dart';

class SpaceScheduleMockDataSource {
  Future<List<ScheduleMusicItemModel>> getMusicCatalog() async {
    await Future.delayed(const Duration(milliseconds: 120));

    return const [
      ScheduleMusicItemModel(
        id: 'music-001',
        title: 'Indie Pop Pillow',
        artist: 'Coplyp Mix',
        collection: 'Frontline Pop',
        artworkLabel: 'Indie Pop\nPillow',
        primaryHex: '#5A1593',
        secondaryHex: '#7B38C6',
      ),
      ScheduleMusicItemModel(
        id: 'music-002',
        title: 'Fourth World Ambient',
        artist: 'Coplyp Mix',
        collection: 'Atmosphere',
        artworkLabel: 'Fourth World\nAmbient',
        primaryHex: '#4A2EA1',
        secondaryHex: '#4FB2D6',
      ),
      ScheduleMusicItemModel(
        id: 'music-003',
        title: 'Feel-good Dining',
        artist: 'Restaurant Set',
        collection: 'Ready-made',
        artworkLabel: 'Feel-good\nDining',
        primaryHex: '#824B19',
        secondaryHex: '#D0A667',
      ),
      ScheduleMusicItemModel(
        id: 'music-004',
        title: 'Fast Food Pop',
        artist: 'Restaurant Set',
        collection: 'Ready-made',
        artworkLabel: 'Fast Food\nPop',
        primaryHex: '#A7232C',
        secondaryHex: '#E76D4A',
      ),
      ScheduleMusicItemModel(
        id: 'music-005',
        title: 'Family Friendly & Current',
        artist: 'Restaurant Set',
        collection: 'Ready-made',
        artworkLabel: 'Family Friendly\n& Current',
        primaryHex: '#C9454F',
        secondaryHex: '#ED8B8D',
      ),
      ScheduleMusicItemModel(
        id: 'music-006',
        title: 'Dinner Classics',
        artist: 'Evening Set',
        collection: 'Ready-made',
        artworkLabel: 'Dinner\nClassics',
        primaryHex: '#3E2D6E',
        secondaryHex: '#9E83D7',
      ),
    ];
  }

  Future<List<ScheduleTemplate>> getTemplateSources() async {
    await Future.delayed(const Duration(milliseconds: 160));

    return [
      ScheduleTemplate(
        id: 'template-restaurant-feelgood',
        title: 'Feelgood Restaurant',
        subtitle: 'Happy vibes from open to close.',
        description: 'Built for cafe and all-day dining spaces.',
        schedule: _schedule(
          id: 'schedule-template-001',
          name: 'Feelgood Restaurant',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-template-001',
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
              startTime: '08:00',
              endTime: '12:00',
              musicId: 'music-003',
            ),
            ScheduleSlotModel(
              id: 'slot-template-002',
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
              startTime: '12:00',
              endTime: '16:00',
              musicId: 'music-001',
            ),
            ScheduleSlotModel(
              id: 'slot-template-003',
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
              startTime: '16:00',
              endTime: '21:00',
              musicId: 'music-006',
            ),
          ],
        ),
      ),
      ScheduleTemplate(
        id: 'template-restaurant-pop',
        title: 'Restaurant Pop',
        subtitle: 'A full day of fast food tracks.',
        description: 'Higher energy for quick-service spaces.',
        schedule: _schedule(
          id: 'schedule-template-002',
          name: 'Restaurant Pop',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-template-004',
              daysOfWeek: [1, 2, 3, 4, 5],
              startTime: '09:00',
              endTime: '14:00',
              musicId: 'music-004',
            ),
            ScheduleSlotModel(
              id: 'slot-template-005',
              daysOfWeek: [1, 2, 3, 4, 5],
              startTime: '14:00',
              endTime: '18:00',
              musicId: 'music-005',
            ),
          ],
        ),
      ),
      ScheduleTemplate(
        id: 'template-family-friendly',
        title: 'Family-friendly Restaurant',
        subtitle: 'Inclusive pop from brunch to dinner.',
        description: 'Soft transitions for family-focused service hours.',
        schedule: _schedule(
          id: 'schedule-template-003',
          name: 'Family-friendly Restaurant',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-template-006',
              daysOfWeek: [6, 7],
              startTime: '10:00',
              endTime: '15:00',
              musicId: 'music-005',
            ),
            ScheduleSlotModel(
              id: 'slot-template-007',
              daysOfWeek: [6, 7],
              startTime: '15:00',
              endTime: '20:00',
              musicId: 'music-003',
            ),
          ],
        ),
      ),
      ScheduleTemplate(
        id: 'template-diner-nostalgia',
        title: 'Diner Nostalgia',
        subtitle: 'Oldies goldies all day.',
        description: 'A calm all-day mix for retro-inspired spaces.',
        schedule: _schedule(
          id: 'schedule-template-004',
          name: 'Diner Nostalgia',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-template-008',
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
              startTime: '11:00',
              endTime: '21:00',
              musicId: 'music-006',
            ),
          ],
        ),
      ),
    ];
  }

  Future<List<ScheduleSourceModel>> getSeedLibrarySources() async {
    await Future.delayed(const Duration(milliseconds: 150));

    return [
      ScheduleSourceModel(
        id: 'library-seed-001',
        title: 'Ready-made Lunch Rush',
        subtitle: 'Perfect for high-turnover lunch service.',
        description: 'Saved from another space in your brand.',
        type: ScheduleSourceType.library,
        schedule: _schedule(
          id: 'schedule-library-001',
          name: 'Ready-made Lunch Rush',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-library-001',
              daysOfWeek: [1, 2, 3, 4, 5],
              startTime: '11:30',
              endTime: '14:30',
              musicId: 'music-004',
            ),
            ScheduleSlotModel(
              id: 'slot-library-002',
              daysOfWeek: [1, 2, 3, 4, 5],
              startTime: '14:30',
              endTime: '17:00',
              musicId: 'music-001',
            ),
          ],
        ),
      ),
      ScheduleSourceModel(
        id: 'library-seed-002',
        title: 'Weekend Lounge',
        subtitle: 'Ambient comfort for slower afternoons.',
        description: 'Shared by Coplyp HQ.',
        type: ScheduleSourceType.library,
        schedule: _schedule(
          id: 'schedule-library-002',
          name: 'Weekend Lounge',
          slots: const [
            ScheduleSlotModel(
              id: 'slot-library-003',
              daysOfWeek: [6, 7],
              startTime: '13:00',
              endTime: '17:00',
              musicId: 'music-002',
            ),
            ScheduleSlotModel(
              id: 'slot-library-004',
              daysOfWeek: [6, 7],
              startTime: '17:00',
              endTime: '21:00',
              musicId: 'music-006',
            ),
          ],
        ),
      ),
    ];
  }

  SpaceScheduleModel _schedule({
    required String id,
    required String name,
    required List<ScheduleSlotModel> slots,
  }) {
    return SpaceScheduleModel(
      id: id,
      name: name,
      spaceId: null,
      slots: slots,
      enabled: true,
      updatedAt: DateTime(2026, 3, 15, 8),
    );
  }
}
