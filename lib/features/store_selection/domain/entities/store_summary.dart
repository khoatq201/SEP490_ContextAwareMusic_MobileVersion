import 'package:equatable/equatable.dart';

/// Represents a summary of a store for selection purposes
class StoreSummary extends Equatable {
  final String id;
  final String name;
  final String address;
  final int spacesCount;
  final String? imageUrl;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.spacesCount,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, address, spacesCount, imageUrl];
}
