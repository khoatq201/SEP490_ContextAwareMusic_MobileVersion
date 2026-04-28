import '../models/mood_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class MoodRemoteDataSource {
  /// Fetch all active moods (global reference data).
  Future<List<MoodModel>> getMoods();
}

class MoodRemoteDataSourceImpl implements MoodRemoteDataSource {
  final DioClient dioClient;

  MoodRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<MoodModel>> getMoods() async {
    try {
      final response = await dioClient.get(ApiConstants.getMoods);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MoodModel.fromApiResponse(data);
      }
      return [];
    } catch (e) {
      throw ServerException('Failed to fetch moods: $e');
    }
  }
}
