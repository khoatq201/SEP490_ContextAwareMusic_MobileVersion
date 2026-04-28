import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums/queue_insert_mode_enum.dart';

Future<QueueInsertModeEnum?> showQueueModePickerBottomSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  QueueInsertModeEnum defaultMode = QueueInsertModeEnum.playNow,
}) {
  const options = [
    (
      mode: QueueInsertModeEnum.playNow,
      title: 'Play now',
      subtitle: 'Switch immediately to this selection.',
      icon: Icons.play_circle_fill,
    ),
    (
      mode: QueueInsertModeEnum.playNext,
      title: 'Play next',
      subtitle: 'Insert right after the current playing item.',
      icon: Icons.skip_next_rounded,
    ),
    (
      mode: QueueInsertModeEnum.addToQueue,
      title: 'Add to queue',
      subtitle: 'Append to the end of the queue.',
      icon: Icons.queue_music_rounded,
    ),
  ];

  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final dividerColor = Theme.of(context).dividerColor;

  return showModalBottomSheet<QueueInsertModeEnum>(
    context: context,
    useRootNavigator: true,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: colorScheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < options.length; i++) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(options[i].icon, color: colorScheme.primary),
                  title: Text(
                    options[i].title,
                    style: GoogleFonts.inter(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    options[i].subtitle,
                    style: GoogleFonts.inter(
                      color: textTheme.bodySmall?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: options[i].mode == defaultMode
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(
                    sheetContext,
                    rootNavigator: true,
                  ).pop(options[i].mode),
                ),
                if (i != options.length - 1)
                  Divider(
                      color: dividerColor.withValues(alpha: 0.5), height: 1),
              ],
            ],
          ),
        ),
      );
    },
  );
}
