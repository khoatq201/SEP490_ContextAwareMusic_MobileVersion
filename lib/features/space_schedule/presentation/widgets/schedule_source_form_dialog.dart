import 'package:flutter/material.dart';

import '../../domain/entities/schedule_source.dart';

class ScheduleSourceFormPayload {
  const ScheduleSourceFormPayload({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.sourceType,
  });

  final String title;
  final String subtitle;
  final String description;
  final ScheduleSourceType sourceType;
}

class ScheduleSourceFormDialog extends StatefulWidget {
  const ScheduleSourceFormDialog({
    super.key,
    required this.title,
    this.actionLabel = 'Save',
    this.initialTitle = '',
    this.initialSubtitle = '',
    this.initialDescription = '',
    this.initialSourceType = ScheduleSourceType.library,
    this.showDescription = true,
    this.showSourceType = false,
  });

  factory ScheduleSourceFormDialog.fromSource({
    required String title,
    String actionLabel = 'Save',
    required ScheduleSource source,
    bool showDescription = true,
  }) {
    return ScheduleSourceFormDialog(
      title: title,
      actionLabel: actionLabel,
      initialTitle: source.title,
      initialSubtitle: source.subtitle,
      initialDescription: source.description ?? '',
      initialSourceType: source.type,
      showDescription: showDescription,
      showSourceType: false,
    );
  }

  final String title;
  final String actionLabel;
  final String initialTitle;
  final String initialSubtitle;
  final String initialDescription;
  final ScheduleSourceType initialSourceType;
  final bool showDescription;
  final bool showSourceType;

  @override
  State<ScheduleSourceFormDialog> createState() =>
      _ScheduleSourceFormDialogState();
}

class _ScheduleSourceFormDialogState extends State<ScheduleSourceFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;
  late ScheduleSourceType _sourceType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtitleController = TextEditingController(text: widget.initialSubtitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _sourceType = widget.initialSourceType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(labelText: 'Subtitle'),
            ),
            if (widget.showDescription)
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            if (widget.showSourceType) ...[
              const SizedBox(height: 14),
              SegmentedButton<ScheduleSourceType>(
                segments: const [
                  ButtonSegment(
                    value: ScheduleSourceType.template,
                    label: Text('Template'),
                    icon: Icon(Icons.library_music_outlined),
                  ),
                  ButtonSegment(
                    value: ScheduleSourceType.library,
                    label: Text('Library'),
                    icon: Icon(Icons.folder_copy_outlined),
                  ),
                ],
                selected: {_sourceType},
                onSelectionChanged: (selection) {
                  setState(() => _sourceType = selection.single);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    ScheduleSourceFormPayload(
                      title: _titleController.text.trim(),
                      subtitle: _subtitleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      sourceType: _sourceType,
                    ),
                  ),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
