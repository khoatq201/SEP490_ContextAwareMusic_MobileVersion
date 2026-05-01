import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/services/session_data_cache.dart';
import 'package:cams_store_manager/features/home/data/datasources/home_remote_datasource.dart';
import 'package:cams_store_manager/features/home/data/repositories/home_repository_impl.dart';
import 'package:cams_store_manager/features/home/domain/entities/category_entity.dart';
import 'package:cams_store_manager/features/home/domain/entities/sensor_entity.dart';

void main() {
  test('HomeRepositoryImpl caches categories until force refresh', () async {
    final dataSource = _CountingHomeRemoteDataSource();
    final repository = HomeRepositoryImpl(
      dataSource: dataSource,
      sessionDataCache: SessionDataCache(),
    );

    final first = await repository.getCategories();
    final second = await repository.getCategories();
    final refreshed = await repository.getCategories(forceRefresh: true);

    expect(dataSource.categoryCalls, 2);
    expect(first.getOrElse(() => const []).single.title, 'Category 1');
    expect(second.getOrElse(() => const []).single.title, 'Category 1');
    expect(refreshed.getOrElse(() => const []).single.title, 'Category 2');
  });
}

class _CountingHomeRemoteDataSource implements HomeRemoteDataSource {
  int categoryCalls = 0;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    categoryCalls += 1;
    return [
      CategoryEntity(
          id: 'cat-$categoryCalls', title: 'Category $categoryCalls'),
    ];
  }

  @override
  Future<List<SensorEntity>> getSensorData({
    String? storeId,
    String? spaceId,
    bool forceRefresh = false,
  }) async {
    return const [];
  }
}
