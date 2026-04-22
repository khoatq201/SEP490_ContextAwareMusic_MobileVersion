import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/space_schedule_remote_datasource.dart';
import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/entities/schedule_source.dart';
import 'schedule_slot_form_sheet.dart';
import 'schedule_source_form_dialog.dart';

class BrandScheduleEditorSheet extends StatefulWidget {
  const BrandScheduleEditorSheet({
    super.key,
    required this.brandId,
    required this.musicCatalog,
    required this.remoteDataSource,
  });

  final String brandId;
  final List<ScheduleMusicItem> musicCatalog;
  final SpaceScheduleRemoteDataSource remoteDataSource;

  @override
  State<BrandScheduleEditorSheet> createState() =>
      _BrandScheduleEditorSheetState();
}

class _BrandScheduleEditorSheetState extends State<BrandScheduleEditorSheet> {
  var _isLoading = true;
  var _isSaving = false;
  String? _errorMessage;
  String? _selectedSourceId;
  List<ScheduleSource> _sources = const [];

  ScheduleSource? get _selectedSource {
    final selectedId = _selectedSourceId;
    if (selectedId == null) return _sources.isEmpty ? null : _sources.first;
    for (final source in _sources) {
      if (source.id == selectedId) return source;
    }
    return _sources.isEmpty ? null : _sources.first;
  }

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sources = await widget.remoteDataSource.getBrandLibrary(
        widget.brandId,
      );
      if (!mounted) return;
      setState(() {
        _sources = sources;
        _selectedSourceId = _resolveSelectedSourceId(sources);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String? _resolveSelectedSourceId(List<ScheduleSource> sources) {
    if (sources.isEmpty) return null;
    final currentId = _selectedSourceId;
    if (currentId != null && sources.any((source) => source.id == currentId)) {
      return currentId;
    }
    return sources.first.id;
  }

  Future<void> _createSource() async {
    final payload = await showDialog<ScheduleSourceFormPayload>(
      context: context,
      builder: (_) => const ScheduleSourceFormDialog(
        title: 'Create brand schedule',
      ),
    );
    if (!mounted || payload == null) return;

    await _runMutation(
      () => widget.remoteDataSource.createBrandSource(
        title: payload.title,
        subtitle: payload.subtitle,
        description: payload.description,
      ),
    );
  }

  Future<void> _editSource(ScheduleSource source) async {
    final payload = await showDialog<ScheduleSourceFormPayload>(
      context: context,
      builder: (_) => ScheduleSourceFormDialog.fromSource(
        title: 'Edit brand schedule',
        source: source,
      ),
    );
    if (!mounted || payload == null) return;

    await _runMutation(
      () => widget.remoteDataSource.updateBrandSource(
        sourceId: source.id,
        title: payload.title,
        subtitle: payload.subtitle,
        description: payload.description,
      ),
    );
  }

  Future<void> _deleteSource(ScheduleSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete brand schedule?'),
        content: Text(
          'Remove ${source.title}? Stores in Strict Sync will stop receiving this source after backend sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(
      () => widget.remoteDataSource.deleteBrandSource(sourceId: source.id),
    );
  }

  Future<void> _upsertSlot(ScheduleSource source, [ScheduleSlot? slot]) async {
    final payload = await showModalBottomSheet<ScheduleSlot>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleSlotFormSheet(
        title: slot == null ? 'Add brand slot' : 'Edit brand slot',
        slot: slot,
        initialDay: DateTime.now().weekday % DateTime.sunday,
        musicCatalog: widget.musicCatalog,
        allowMultipleDays: true,
        generatedIdPrefix: 'brand-slot',
      ),
    );
    if (!mounted || payload == null) return;

    await _runMutation(
      () => widget.remoteDataSource.upsertBrandSlot(
        sourceId: source.id,
        slot: payload,
      ),
    );
  }

  Future<void> _deleteSlot(ScheduleSource source, ScheduleSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete brand slot?'),
        content: Text('Remove ${slot.startTime} - ${slot.endTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(
      () => widget.remoteDataSource.deleteBrandSlot(
        sourceId: source.id,
        slotId: slot.id,
      ),
    );
  }

  Future<void> _runMutation(Future<String> Function() mutate) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final message = await mutate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadSources();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSource = _selectedSource;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (context, controller) => Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brand schedule',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sources used by Strict Sync stores.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isSaving ? null : _loadSources,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _InlineError(message: _errorMessage!),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _createSource,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create brand schedule'),
                          ),
                          const SizedBox(height: 14),
                          if (_sources.isEmpty)
                            const _EmptyBrandScheduleState()
                          else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sources
                                  .map(
                                    (source) => ChoiceChip(
                                      label: Text(source.title),
                                      selected: source.id == selectedSource?.id,
                                      onSelected: (_) => setState(
                                        () => _selectedSourceId = source.id,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 14),
                            if (selectedSource != null)
                              _BrandSourcePanel(
                                source: selectedSource,
                                musicCatalog: widget.musicCatalog,
                                isSaving: _isSaving,
                                onEdit: () => _editSource(selectedSource),
                                onDelete: () => _deleteSource(selectedSource),
                                onAddSlot: () => _upsertSlot(selectedSource),
                                onEditSlot: (slot) =>
                                    _upsertSlot(selectedSource, slot),
                                onDeleteSlot: (slot) =>
                                    _deleteSlot(selectedSource, slot),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandSourcePanel extends StatelessWidget {
  const _BrandSourcePanel({
    required this.source,
    required this.musicCatalog,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSlot,
    required this.onEditSlot,
    required this.onDeleteSlot,
  });

  final ScheduleSource source;
  final List<ScheduleMusicItem> musicCatalog;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSlot;
  final ValueChanged<ScheduleSlot> onEditSlot;
  final ValueChanged<ScheduleSlot> onDeleteSlot;

  @override
  Widget build(BuildContext context) {
    final slots = [...source.schedule.slots]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (source.subtitle.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(source.subtitle),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit source',
                  onPressed: isSaving ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete source',
                  onPressed: isSaving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSaving ? null : onAddSlot,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add brand slot'),
            ),
            const SizedBox(height: 12),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text('No brand slots yet.'),
                ),
              )
            else
              ...slots.map(
                (slot) => _BrandSlotTile(
                  slot: slot,
                  music: _findMusic(musicCatalog, slot.musicId),
                  onTap: isSaving ? null : () => onEditSlot(slot),
                  onDelete: isSaving ? null : () => onDeleteSlot(slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandSlotTile extends StatelessWidget {
  const _BrandSlotTile({
    required this.slot,
    required this.music,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleSlot slot;
  final ScheduleMusicItem? music;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.schedule_rounded)),
      title: Text(music?.title ?? 'Missing playlist'),
      subtitle: Text(
        '${_daysLabel(slot.daysOfWeek)} | ${slot.startTime} - ${slot.endTime}',
      ),
      trailing: IconButton(
        tooltip: 'Delete slot',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
      onTap: onTap,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}

class _EmptyBrandScheduleState extends StatelessWidget {
  const _EmptyBrandScheduleState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text('No brand schedules yet.'),
      ),
    );
  }
}

const _shortDayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

ScheduleMusicItem? _findMusic(List<ScheduleMusicItem> catalog, String musicId) {
  for (final item in catalog) {
    if (item.id == musicId) return item;
  }
  return null;
}

String _daysLabel(List<int> days) {
  if (days.length == 7) return 'Every day';
  final normalized = days.where((day) => day >= 0 && day <= 6).toList()..sort();
  return normalized.map((day) => _shortDayLabels[day]).join(', ');
}
