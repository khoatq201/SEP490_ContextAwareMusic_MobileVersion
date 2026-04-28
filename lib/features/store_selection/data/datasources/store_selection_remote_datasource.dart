import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../models/store_summary_model.dart';

abstract class StoreSelectionRemoteDataSource {
  Future<List<StoreSummaryModel>> getUserStores();
}

class StoreSelectionRemoteDataSourceImpl
    implements StoreSelectionRemoteDataSource {
  StoreSelectionRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<List<StoreSummaryModel>> getUserStores() async {
    if (ApiConstants.useMockData) {
      return _getMockStores();
    }

    try {
      final response = await dioClient.get(
        ApiConstants.getStoresEndpoint,
        queryParameters: {'pageSize': 500},
      );

      final data = response.data as Map<String, dynamic>;
      final apiResult = ApiResult<void>.fromJson(data);
      if (!apiResult.isSuccess) {
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not load your stores right now.',
        );
      }

      final Map<String, dynamic> paginatedData;
      if (data.containsKey('items')) {
        paginatedData = data;
      } else if (data['data'] is Map<String, dynamic>) {
        paginatedData = data['data'] as Map<String, dynamic>;
      } else {
        throw ErrorMapper.fromApiResponsePayload(
          data,
          fallbackMessage: 'Unexpected response format for stores.',
        );
      }

      final paginationResult = PaginationResult<StoreSummaryModel>.fromJson(
        paginatedData,
        fromItemJson: StoreSummaryModel.fromJson,
      );

      return paginationResult.items;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not load your stores right now.',
      );
    }
  }

  Future<List<StoreSummaryModel>> _getMockStores() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      StoreSummaryModel(
        id: 'store-1',
        brandId: 'brand-001',
        name: 'Highlands Coffee',
        address: '123 Main Street',
        city: 'Ho Chi Minh City',
        district: 'District 1',
        status: EntityStatusEnum.active,
      ),
      StoreSummaryModel(
        id: 'store-2',
        brandId: 'brand-001',
        name: 'The Coffee House',
        address: '456 Nguyen Hue',
        city: 'Ho Chi Minh City',
        district: 'District 1',
        status: EntityStatusEnum.active,
      ),
      StoreSummaryModel(
        id: 'store-3',
        brandId: 'brand-001',
        name: 'Airport Store',
        address: 'Tan Son Nhat Airport',
        city: 'Ho Chi Minh City',
        district: 'Tan Binh District',
        status: EntityStatusEnum.pending,
      ),
    ];
  }
}
