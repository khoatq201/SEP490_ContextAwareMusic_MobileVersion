import 'dart:math';

final Random _guidRandom = Random.secure();

String generateGuidV4() {
  final bytes = List<int>.generate(16, (_) => _guidRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(hexByte).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
