import 'package:flutter/material.dart';

/// A browsable music category (e.g. "Pop", "Chill", "Workout").
class SearchCategory {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const SearchCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}
