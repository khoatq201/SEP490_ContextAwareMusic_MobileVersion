import 'package:flutter/material.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

/// Stub implementation – swap out `_mockCategories` / `search()` body
/// once the real API endpoint is ready.
class SearchRepositoryImpl implements SearchRepository {
  // Hard-coded categories to match Soundtrack-style "Browse all" grid.
  static final List<SearchCategory> _mockCategories = [
    const SearchCategory(
      id: 'pop',
      name: 'Pop',
      color: Color(0xFFE91E63),
      icon: Icons.music_note,
    ),
    const SearchCategory(
      id: 'chill',
      name: 'Chill',
      color: Color(0xFF2196F3),
      icon: Icons.waves,
    ),
    const SearchCategory(
      id: 'workout',
      name: 'Workout',
      color: Color(0xFFFF5722),
      icon: Icons.fitness_center,
    ),
    const SearchCategory(
      id: 'focus',
      name: 'Focus',
      color: Color(0xFF4CAF50),
      icon: Icons.psychology,
    ),
    const SearchCategory(
      id: 'jazz',
      name: 'Jazz',
      color: Color(0xFF9C27B0),
      icon: Icons.piano,
    ),
    const SearchCategory(
      id: 'rock',
      name: 'Rock',
      color: Color(0xFF607D8B),
      icon: Icons.electric_bolt,
    ),
    const SearchCategory(
      id: 'rnb',
      name: 'R&B / Soul',
      color: Color(0xFFFF9800),
      icon: Icons.mic,
    ),
    const SearchCategory(
      id: 'classical',
      name: 'Classical',
      color: Color(0xFF795548),
      icon: Icons.queue_music,
    ),
    const SearchCategory(
      id: 'electronic',
      name: 'Electronic',
      color: Color(0xFF00BCD4),
      icon: Icons.graphic_eq,
    ),
    const SearchCategory(
      id: 'ambient',
      name: 'Ambient',
      color: Color(0xFF8BC34A),
      icon: Icons.blur_on,
    ),
  ];

  @override
  Future<List<SearchCategory>> getCategories() async {
    // TODO: replace with real API call.
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockCategories;
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    // TODO: replace with real API call.
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) return [];
    // Return mock results that contain the query string.
    return [
      SearchResult(
        id: '1',
        title: '$query - Popular Mix',
        subtitle: 'Playlist',
        type: SearchResultType.playlist,
      ),
      SearchResult(
        id: '2',
        title: 'Best of $query',
        subtitle: 'Auto Station',
        type: SearchResultType.playlist,
      ),
      SearchResult(
        id: '3',
        title: 'Artist: $query',
        subtitle: 'Artist',
        type: SearchResultType.artist,
      ),
    ];
  }
}
