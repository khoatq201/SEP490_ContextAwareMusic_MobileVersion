import '../../../../core/models/pagination_result.dart';
import '../models/location_space_model.dart';

abstract class LocationRemoteDataSource {
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId);
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(String storeId, {int page = 1, int pageSize = 10});
  Future<Map<String, PaginationResult<LocationSpaceModel>>> getSpacesForBrand(List<String> storeIds, {int page = 1, int pageSize = 10});
}

