import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/brand_update_request.dart';
import '../models/brand_detail_model.dart';
import '../models/store_summary_model.dart';

abstract class StoreSelectionRemoteDataSource {
  Future<List<StoreSummaryModel>> getUserStores();

  Future<BrandDetailModel> getBrandDetail(String brandId);

  Future<String> updateBrandDetail({
    required String brandId,
    required BrandUpdateRequest request,
  });
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

  @override
  Future<BrandDetailModel> getBrandDetail(String brandId) async {
    if (ApiConstants.useMockData) {
      return _getMockBrandDetail(brandId);
    }

    try {
      final response = await dioClient.get(
        ApiConstants.getBrandDetail(brandId),
      );
      final data = response.data as Map<String, dynamic>;
      final apiResult = ApiResult<BrandDetailModel>.fromJson(
        data,
        fromData: BrandDetailModel.fromJson,
      );
      if (!apiResult.isSuccess || apiResult.data == null) {
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not load the brand profile right now.',
        );
      }
      return apiResult.data!;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not load the brand profile right now.',
      );
    }
  }

  @override
  Future<String> updateBrandDetail({
    required String brandId,
    required BrandUpdateRequest request,
  }) async {
    if (ApiConstants.useMockData) {
      await Future.delayed(const Duration(milliseconds: 350));
      return 'Brand updated successfully';
    }

    try {
      final response = await dioClient.patch(
        ApiConstants.updateBrand(brandId),
        data: FormData.fromMap(request.toFormFields()),
        options: Options(contentType: 'multipart/form-data'),
      );
      final apiResult = ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!apiResult.isSuccess) {
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not update the brand profile right now.',
        );
      }
      return apiResult.message ?? 'Brand updated successfully';
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not update the brand profile right now.',
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

  Future<BrandDetailModel> _getMockBrandDetail(String brandId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return BrandDetailModel(
      id: brandId,
      name: 'Highlands Coffee',
      logoUrl: null,
      industry: 'F&B',
      primaryContactName: 'Brand Operations',
      contactEmail: 'ops@highlands.example',
      contactPhone: '0123456789',
      description: 'Retail coffee brand profile used for store operations.',
      website: 'https://www.highlandscoffee.com.vn',
      legalName: 'Highlands Coffee Service Joint Stock Company',
      billingAddress: 'Ho Chi Minh City',
      technicalContactEmail: 'iot@highlands.example',
      defaultTimeZone: 'SE Asia Standard Time',
      status: EntityStatusEnum.active,
    );
  }
}
