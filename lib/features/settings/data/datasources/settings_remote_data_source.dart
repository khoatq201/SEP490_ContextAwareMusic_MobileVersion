import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/profile_response_model.dart';
import '../../../store_selection/data/models/brand_detail_model.dart';
import 'settings_mock_data_source.dart';
import '../models/settings_snapshot_model.dart';

class SettingsRemoteDataSource implements SettingsDataSource {
  const SettingsRemoteDataSource({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<SettingsSnapshotModel> getSettingsSnapshot() async {
    try {
      final profile = await _getProfile();
      final brandId = profile.brandId;
      final brand = brandId == null ? null : await _getBrandDetail(brandId);
      final wallet = await _getWallet();
      final subscriptionId = brand?.currentSubscriptionId?.trim();

      return SettingsSnapshotModel(
        companyName: _fallback(brand?.name, 'Company'),
        businessType: _fallback(brand?.industry, 'Not set'),
        planName: subscriptionId == null || subscriptionId.isEmpty
            ? 'No active subscription'
            : 'Active subscription',
        subscriptionId: subscriptionId == null || subscriptionId.isEmpty
            ? null
            : subscriptionId,
        tokenBalance: wallet?.balanceTokens,
        walletLocked: wallet?.isLocked ?? false,
        explicitMusicAllowed: true,
        blockingSongsAllowed: true,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Unable to load settings right now.',
      );
    }
  }

  Future<ProfileResponseModel> _getProfile() async {
    final response = await dioClient.get(ApiConstants.profile);
    final apiResult = ApiResult<ProfileResponseModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromData: (data) =>
          ProfileResponseModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResult.isSuccess || apiResult.data == null) {
      throw ErrorMapper.fromApiErrorDetails(
        apiResult.errorDetails,
        fallbackMessage: 'We could not load your profile right now.',
      );
    }
    return apiResult.data!;
  }

  Future<BrandDetailModel> _getBrandDetail(String brandId) async {
    final response = await dioClient.get(ApiConstants.getBrandDetail(brandId));
    final apiResult = ApiResult<BrandDetailModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromData: BrandDetailModel.fromJson,
    );
    if (!apiResult.isSuccess || apiResult.data == null) {
      throw ErrorMapper.fromApiErrorDetails(
        apiResult.errorDetails,
        fallbackMessage: 'We could not load the brand profile right now.',
      );
    }
    return apiResult.data!;
  }

  Future<_BillingWallet?> _getWallet() async {
    try {
      final response = await dioClient.get(ApiConstants.billingWallet);
      final apiResult = ApiResult<_BillingWallet>.fromJson(
        response.data as Map<String, dynamic>,
        fromData: (data) => _BillingWallet.fromJson(
          data as Map<String, dynamic>,
        ),
      );
      if (!apiResult.isSuccess) return null;
      return apiResult.data;
    } catch (_) {
      return null;
    }
  }

  String _fallback(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

class _BillingWallet {
  const _BillingWallet({
    required this.balanceTokens,
    required this.isLocked,
  });

  final int balanceTokens;
  final bool isLocked;

  factory _BillingWallet.fromJson(Map<String, dynamic> json) {
    return _BillingWallet(
      balanceTokens: (json['balanceTokens'] as num?)?.round() ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}
