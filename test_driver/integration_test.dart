import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final evidenceDir = Directory(
    'test_results_report5/submission_evidence/schedule_smoke',
  )..createSync(recursive: true);

  await integrationDriver(
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('${evidenceDir.path}/$screenshotName.png');
      file.writeAsBytesSync(screenshotBytes);
      return true;
    },
  );
}
