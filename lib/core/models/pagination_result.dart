/// Generic pagination wrapper matching backend PaginationResult<T>.
class PaginationResult<T> {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final List<T> items;

  const PaginationResult({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.items,
  });

  factory PaginationResult.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) fromItemJson,
  }) {
    return PaginationResult<T>(
      currentPage: json['currentPage'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
      hasNext: json['hasNext'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => fromItemJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
