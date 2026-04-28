import '../../../../core/error/exceptions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/space_hub_binding_model.dart';

class SpaceHubStubDataSource {
  SpaceHubStubDataSource({required this.localStorage});

  final LocalStorageService localStorage;

  static const _bindingKeyPrefix = 'space_hub_binding/';

  Future<SpaceHubBindingModel?> getBinding(String spaceId) async {
    final raw = localStorage.getSetting(_key(spaceId));
    if (raw == null) return null;
    if (raw is Map) {
      return SpaceHubBindingModel.fromJson(Map<String, dynamic>.from(raw));
    }
    throw CacheException('Invalid local hub binding cache for $spaceId');
  }

  Future<SpaceHubBindingModel> upsertBinding(
      SpaceHubBindingModel binding) async {
    await localStorage.saveSetting(_key(binding.spaceId), binding.toJson());
    return binding;
  }

  Future<void> deleteBinding(String spaceId) {
    return localStorage.removeSetting(_key(spaceId));
  }

  Future<void> restartHub(String spaceId) async {
    final binding = await getBinding(spaceId);
    if (binding == null) {
      throw CacheException('No hub binding found for $spaceId');
    }
  }

  String _key(String spaceId) => '$_bindingKeyPrefix$spaceId';
}
