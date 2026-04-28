import 'package:flutter/material.dart';

const String kManagerPlaylistOnlyMessage =
    'Manager devices can only control playback from CAMS playlists right now.';

const String kLocalPreviewOnlyMessage =
    'Playing locally on this device only. Other devices sync only for CAMS playlist streams.';

void showLocalPreviewStartedSnackBar(
  BuildContext context, {
  String? spaceName,
}) {
  final targetName = spaceName?.trim();
  final content = (targetName == null || targetName.isEmpty)
      ? kLocalPreviewOnlyMessage
      : 'Playing locally on $targetName only. Other devices sync only for CAMS playlist streams.';

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(content),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
