import 'dart:convert';
import 'dart:io';

enum EspDevelopModePreset {
  lowPeopleLowDecibel('low_people_low_decibel'),
  highPeopleLowDecibel('high_people_low_decibel'),
  highPeopleHighDecibel('high_people_high_decibel');

  const EspDevelopModePreset(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case EspDevelopModePreset.lowPeopleLowDecibel:
        return 'Low people · Low dB';
      case EspDevelopModePreset.highPeopleLowDecibel:
        return 'High people · Low dB';
      case EspDevelopModePreset.highPeopleHighDecibel:
        return 'High people · High dB';
    }
  }

  static EspDevelopModePreset fromApiValue(String? raw) {
    return EspDevelopModePreset.values.firstWhere(
      (preset) => preset.apiValue == raw,
      orElse: () => EspDevelopModePreset.lowPeopleLowDecibel,
    );
  }
}

class EspDevelopModeStatus {
  const EspDevelopModeStatus({
    required this.enabled,
    required this.preset,
    this.previewBaseUrl,
    this.lastPeopleCount,
    this.lastDecibel,
    this.lastPublishIsoUtc,
  });

  final bool enabled;
  final EspDevelopModePreset preset;
  final String? previewBaseUrl;
  final int? lastPeopleCount;
  final double? lastDecibel;
  final String? lastPublishIsoUtc;
  bool get hasUploadedImage => false;
  int? get manualPeopleCount => null;
  double? get manualDecibel => null;
  double? get lastConfidence => null;
  String? get lastMode => preset.apiValue;

  factory EspDevelopModeStatus.fromJson(Map<String, dynamic> json) {
    return EspDevelopModeStatus(
      enabled: json['enabled'] == true,
      preset: EspDevelopModePreset.fromApiValue(json['preset']?.toString()),
      previewBaseUrl: json['preview_base_url']?.toString(),
      lastPeopleCount: (json['last_people_count'] as num?)?.toInt(),
      lastDecibel: (json['last_decibel'] as num?)?.toDouble(),
      lastPublishIsoUtc: json['last_publish_iso_utc']?.toString(),
    );
  }
}

class EspDevelopModeClient {
  String normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException(
        'Enter the ESP32 preview server URL or IP address.',
      );
    }

    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'http://$trimmed';
    final uri = Uri.parse(withScheme);
    final host = uri.host.trim();
    if (host.isEmpty) {
      throw const FormatException('Enter a valid ESP32 host or IP address.');
    }

    return Uri(
      scheme: uri.scheme.isEmpty ? 'http' : uri.scheme,
      host: host,
      port: uri.hasPort ? uri.port : 8080,
    ).toString();
  }

  Future<EspDevelopModeStatus> fetchStatus(String baseUrl) async {
    final response = await _sendRequest(
      Uri.parse('${normalizeBaseUrl(baseUrl)}/develop-mode/status'),
      method: 'GET',
    );
    return EspDevelopModeStatus.fromJson(response);
  }

  Future<EspDevelopModeStatus> configure(
    String baseUrl, {
    required bool enabled,
    required EspDevelopModePreset preset,
  }) async {
    final base = Uri.parse('${normalizeBaseUrl(baseUrl)}/develop-mode/config');
    final uri = base.replace(
      queryParameters: <String, String>{
        'enabled': enabled ? '1' : '0',
        'preset': preset.apiValue,
      },
    );
    final response = await _sendRequest(
      uri,
      method: 'POST',
      body: <String, Object?>{
        'enabled': enabled,
        'preset': preset.apiValue,
      },
    );
    return EspDevelopModeStatus.fromJson(response);
  }

  Future<EspDevelopModeStatus> setEnabled(
    String baseUrl, {
    required bool enabled,
    int? manualPeopleCount,
    double? manualDecibel,
  }) {
    return configure(
      baseUrl,
      enabled: enabled,
      preset: EspDevelopModePreset.lowPeopleLowDecibel,
    );
  }

  Future<void> uploadImage(String baseUrl, dynamic imageBytes) async {}

  Future<LegacyPublishResult> publish(
    String baseUrl, {
    int? manualPeopleCount,
    double? manualDecibel,
  }) async {
    final status = await fetchStatus(baseUrl);
    return LegacyPublishResult(
      peopleCount: status.lastPeopleCount ?? 0,
      decibel: status.lastDecibel ?? 0,
      mode: status.preset.apiValue,
    );
  }

  Future<Map<String, dynamic>> _sendRequest(
    Uri uri, {
    required String method,
    Map<String, Object?>? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = method == 'GET'
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      if (body != null) {
        final payload = jsonEncode(body);
        request.headers.contentType = ContentType.json;
        request.headers.contentLength = utf8.encode(payload).length;
        request.write(payload);
      }
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          responseBody.isEmpty
              ? 'ESP32 develop mode request failed with HTTP ${response.statusCode}.'
              : responseBody,
          uri: uri,
        );
      }
      if (responseBody.trim().isEmpty) {
        return const <String, dynamic>{};
      }
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('ESP32 returned an unexpected response.');
    } finally {
      client.close(force: true);
    }
  }
}

class LegacyPublishResult {
  const LegacyPublishResult({
    required this.peopleCount,
    required this.decibel,
    required this.mode,
  });

  final int peopleCount;
  final double decibel;
  final String mode;
}
