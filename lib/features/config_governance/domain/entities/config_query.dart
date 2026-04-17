import 'package:equatable/equatable.dart';

import 'config_governance_enums.dart';

class ConfigQuery extends Equatable {
  final int page;
  final int pageSize;
  final ConfigDomain? domain;
  final String? keyPrefix;

  const ConfigQuery({
    this.page = 1,
    this.pageSize = 20,
    this.domain,
    this.keyPrefix,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'pageSize': pageSize,
      if (domain != null && domain != ConfigDomain.unknown)
        'domain': domain!.value,
      if (keyPrefix != null && keyPrefix!.trim().isNotEmpty)
        'keyPrefix': keyPrefix!.trim(),
    };
  }

  @override
  List<Object?> get props => [page, pageSize, domain, keyPrefix];
}
