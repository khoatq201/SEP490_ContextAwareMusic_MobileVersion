import '../models/location_space_model.dart';

abstract class LocationRemoteDataSource {
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId);
  Future<List<LocationSpaceModel>> getSpacesForStore(String storeId);
  Future<Map<String, List<LocationSpaceModel>>> getSpacesForBrand(List<String> storeIds);
}
