import 'dart:io';

import 'package:hive/hive.dart';

Future<void> main(List<String> args) async {
  final hiveDir = args.isNotEmpty ? args.first : '.tmp';
  final boxName = args.length > 1 ? args[1] : 'auth_box';

  Hive.init(hiveDir);
  final box = await Hive.openBox<dynamic>(boxName);

  stdout.writeln('Box: $boxName');
  stdout.writeln('Path: $hiveDir');
  stdout.writeln('Keys (${box.length}): ${box.keys.toList()}');

  for (final key in box.keys) {
    final value = box.get(key);
    stdout.writeln('--- $key ---');
    stdout.writeln(value);
  }

  await box.close();
}
