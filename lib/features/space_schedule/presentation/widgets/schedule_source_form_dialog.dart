import 'package:flutter/material.dart';

import '../../domain/entities/schedule_source.dart';

class ScheduleSourceFormPayload {
  const ScheduleSourceFormPayload({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;
}

class ScheduleSourceFormDialog extends StatefulWidget {
  const ScheduleSourceFormDialog({
    super.key,
    required this.title,
    this.actionLabel = 'Save',
    this.initialTitle = '',
    this.initialSubtitle = '',
    this.initialDescription = '',
    this.showDescription = true,
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
      showDescription: showDescription,
    );
  }

  final String title;
  final String actionLabel;
  final String initialTitle;
  final String initialSubtitle;
  final String initialDescription;
  final bool showDescription;

  @override
  State<ScheduleSourceFormDialog> createState() =>
      _ScheduleSourceFormDialogState();
}

class _ScheduleSourceFormDialogState extends State<ScheduleSourceFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtitleController = TextEditingController(text: widget.initialSubtitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
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
                    ),
                  ),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
