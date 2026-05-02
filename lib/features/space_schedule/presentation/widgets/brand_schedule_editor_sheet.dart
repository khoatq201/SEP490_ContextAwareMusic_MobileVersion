import 'package:flutter/material.dart';

import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../space_control/presentation/utils/mood_color_helper.dart';
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

class BrandScheduleEditorSheetLoader extends StatefulWidget {
  const BrandScheduleEditorSheetLoader({
    super.key,
    required this.brandId,
    required this.loadMusicCatalog,
    required this.remoteDataSource,
  });

  final String brandId;
  final Future<List<ScheduleMusicItem>> Function() loadMusicCatalog;
  final SpaceScheduleRemoteDataSource remoteDataSource;

  @override
  State<BrandScheduleEditorSheetLoader> createState() =>
      _BrandScheduleEditorSheetLoaderState();
}

class _BrandScheduleEditorSheetLoaderState
    extends State<BrandScheduleEditorSheetLoader> {
  List<ScheduleMusicItem>? _musicCatalog;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMusicCatalog();
  }

  Future<void> _loadMusicCatalog() async {
    setState(() {
      _musicCatalog = null;
      _errorMessage = null;
    });

    try {
      final musicCatalog = await widget.loadMusicCatalog();
      if (!mounted) return;
      setState(() => _musicCatalog = musicCatalog);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicCatalog = _musicCatalog;
    if (musicCatalog != null) {
      return BrandScheduleEditorSheet(
        brandId: widget.brandId,
        musicCatalog: musicCatalog,
        remoteDataSource: widget.remoteDataSource,
      );
    }

    final tokens = context.camsTokens;
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (context, controller) => Material(
          color: tokens.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderSecondary,
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
                            'Loading playlists and reusable schedules.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
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
                child: _errorMessage == null
                    ? const _BrandScheduleSkeleton()
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          FilledButton.icon(
                            onPressed: _loadMusicCatalog,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
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

class _BrandScheduleEditorSheetState extends State<BrandScheduleEditorSheet> {
  var _isLoading = true;
  var _isSaving = false;
  String? _errorMessage;
  String? _selectedSourceId;
  var _selectedType = ScheduleSourceType.template;
  var _selectedDay = DateTime.now().weekday % DateTime.sunday;
  List<ScheduleSource> _templateSources = const [];
  List<ScheduleSource> _librarySources = const [];

  List<ScheduleSource> get _visibleSources =>
      _selectedType == ScheduleSourceType.template
          ? _templateSources
          : _librarySources;

  ScheduleSource? get _selectedSource {
    final sources = _visibleSources;
    final selectedId = _selectedSourceId;
    if (selectedId == null) return sources.isEmpty ? null : sources.first;
    for (final source in sources) {
      if (source.id == selectedId) return source;
    }
    return sources.isEmpty ? null : sources.first;
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
      final results = await Future.wait([
        widget.remoteDataSource.getBrandTemplates(widget.brandId),
        widget.remoteDataSource.getBrandLibrary(widget.brandId),
      ]);
      if (!mounted) return;
      setState(() {
        _templateSources = results[0];
        _librarySources = results[1];
        _selectedSourceId = _resolveSelectedSourceId(_visibleSources);
        _isLoading = false;
        _isSaving = false;
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
      builder: (_) => ScheduleSourceFormDialog(
        title: 'Create brand schedule',
        initialSourceType: _selectedType,
        showSourceType: true,
      ),
    );
    if (!mounted || payload == null) return;

    setState(() {
      _selectedType = payload.sourceType;
      _selectedSourceId = null;
    });
    await _runMutation(
      () => widget.remoteDataSource.createBrandSource(
        title: payload.title,
        subtitle: payload.subtitle,
        description: payload.description,
        isTemplate: payload.sourceType == ScheduleSourceType.template,
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
            style: FilledButton.styleFrom(
              backgroundColor: context.camsTokens.error,
            ),
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
        initialDay: slot?.daysOfWeek.firstOrNull ?? _selectedDay,
        musicCatalog: widget.musicCatalog,
        allowMultipleDays: true,
      ),
    );
    if (!mounted || payload == null) return;

    final validationMessage = _validateBrandSlot(source, payload);
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _runMutation(
      () => widget.remoteDataSource.upsertBrandSlot(
        sourceId: source.id,
        slot: payload,
      ),
    );
  }

  String? _validateBrandSlot(ScheduleSource source, ScheduleSlot slot) {
    final hasMusic = widget.musicCatalog.any((item) => item.id == slot.musicId);
    if (!hasMusic) {
      return 'Please select a playlist for this brand schedule slot.';
    }

    final start = _minutesOfDay(slot.startTime);
    final end = _minutesOfDay(slot.endTime);
    if (end <= start) {
      return 'End time must be later than start time.';
    }

    for (final other in source.schedule.slots) {
      if (other.id == slot.id) continue;
      if (!_sharesAnyDay(slot.daysOfWeek, other.daysOfWeek)) continue;
      final otherStart = _minutesOfDay(other.startTime);
      final otherEnd = _minutesOfDay(other.endTime);
      if (start < otherEnd && otherStart < end) {
        return 'This brand schedule slot overlaps another slot on the same day.';
      }
    }

    return null;
  }

  bool _sharesAnyDay(List<int> a, List<int> b) {
    for (final day in a) {
      if (b.contains(day)) return true;
    }
    return false;
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
            style: FilledButton.styleFrom(
              backgroundColor: context.camsTokens.error,
            ),
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
    final tokens = context.camsTokens;
    final selectedSource = _selectedSource;
    final visibleSources = _visibleSources;
    final isTemplateTab = _selectedType == ScheduleSourceType.template;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (context, controller) => Material(
          color: tokens.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderSecondary,
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
                            'Templates power Strict Sync. Library schedules can be copied into spaces.',
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
                    ? const _BrandScheduleSkeleton()
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _createSource,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              isTemplateTab
                                  ? 'Create template'
                                  : 'Create library schedule',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<ScheduleSourceType>(
                            selectedIcon: Icon(
                              Icons.check_rounded,
                              color: tokens.brandPrimary,
                              size: 18,
                            ),
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return tokens.brandPrimarySoft;
                                }
                                return tokens.bgContainer;
                              }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return tokens.brandPrimary;
                                }
                                return tokens.textPrimary;
                              }),
                              iconColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return tokens.brandPrimary;
                                }
                                return tokens.textSecondary;
                              }),
                              side: WidgetStatePropertyAll(
                                BorderSide(color: tokens.borderSecondary),
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: ScheduleSourceType.template,
                                label: Text('Templates'),
                                icon: Icon(Icons.library_music_outlined),
                              ),
                              ButtonSegment(
                                value: ScheduleSourceType.library,
                                label: Text('Library'),
                                icon: Icon(Icons.folder_copy_outlined),
                              ),
                            ],
                            selected: {_selectedType},
                            onSelectionChanged: _isSaving
                                ? null
                                : (selection) {
                                    setState(() {
                                      _selectedType = selection.single;
                                      _selectedSourceId =
                                          _resolveSelectedSourceId(
                                        _visibleSources,
                                      );
                                    });
                                  },
                          ),
                          const SizedBox(height: 14),
                          if (visibleSources.isEmpty)
                            _EmptyBrandScheduleState(
                              sourceType: _selectedType,
                            )
                          else ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: visibleSources
                                  .map(
                                    (source) => ChoiceChip(
                                      label: Text(
                                        '${source.title} (${_sourceTypeLabel(source.type)})',
                                      ),
                                      selected: source.id == selectedSource?.id,
                                      selectedColor: tokens.brandPrimarySoft,
                                      backgroundColor: tokens.bgContainer,
                                      checkmarkColor: tokens.brandPrimary,
                                      side: BorderSide(
                                        color: source.id == selectedSource?.id
                                            ? tokens.brandPrimarySoft
                                            : tokens.borderSecondary,
                                      ),
                                      labelStyle: TextStyle(
                                        color: source.id == selectedSource?.id
                                            ? tokens.brandPrimary
                                            : tokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                selectedDay: _selectedDay,
                                onDaySelected: (day) =>
                                    setState(() => _selectedDay = day),
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
    required this.selectedDay,
    required this.onDaySelected,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSlot,
    required this.onEditSlot,
    required this.onDeleteSlot,
  });

  final ScheduleSource source;
  final List<ScheduleMusicItem> musicCatalog;
  final bool isSaving;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSlot;
  final ValueChanged<ScheduleSlot> onEditSlot;
  final ValueChanged<ScheduleSlot> onDeleteSlot;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final daySlots = source.schedule.slots
        .where((slot) => slot.daysOfWeek.contains(selectedDay))
        .toList()
      ..sort((a, b) => _minutesOfDay(a.startTime).compareTo(
            _minutesOfDay(b.startTime),
          ));

    return Card(
      elevation: 0,
      color: tokens.bgContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderSecondary),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _SourceTypeBadge(type: source.type),
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
            Row(
              children: [
                Expanded(
                  child: _BrandScheduleSummary(
                    source: source,
                    musicCatalog: musicCatalog,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: isSaving ? null : onAddSlot,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add slot'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => _BrandDayChip(
                  label: _shortDayLabels[index],
                  selected: selectedDay == index,
                  onTap: () => onDaySelected(index),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _shortDayLabels.length,
              ),
            ),
            const SizedBox(height: 12),
            if (daySlots.isEmpty)
              _EmptyBrandTimeline(
                sourceType: source.type,
                dayLabel: _shortDayLabels[selectedDay],
                onAddSlot: isSaving ? null : onAddSlot,
              )
            else
              _BrandScheduleTimeline(
                slots: daySlots,
                musicCatalog: musicCatalog,
                onSlotTap: isSaving ? null : onEditSlot,
                onSlotDelete: isSaving ? null : onDeleteSlot,
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandScheduleSummary extends StatelessWidget {
  const _BrandScheduleSummary({
    required this.source,
    required this.musicCatalog,
  });

  final ScheduleSource source;
  final List<ScheduleMusicItem> musicCatalog;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final slotCount = source.schedule.slots.length;
    final playlistCount = source.schedule.slots
        .map((slot) => slot.musicId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .length;
    final knownPlaylistCount = source.schedule.slots
        .map((slot) => _findMusic(musicCatalog, slot.musicId))
        .whereType<ScheduleMusicItem>()
        .map((item) => item.id)
        .toSet()
        .length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricPill(
          icon: Icons.view_week_outlined,
          label: '$slotCount slots',
          color: tokens.brandPrimary,
        ),
        _MetricPill(
          icon: Icons.queue_music_outlined,
          label: '$playlistCount playlists',
          color: tokens.techAccent,
        ),
        if (knownPlaylistCount < playlistCount)
          _MetricPill(
            icon: Icons.warning_amber_rounded,
            label: '${playlistCount - knownPlaylistCount} missing',
            color: tokens.warning,
          ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandDayChip extends StatelessWidget {
  const _BrandDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tokens.brandPrimary : tokens.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? tokens.brandPrimary : tokens.borderSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : tokens.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyBrandTimeline extends StatelessWidget {
  const _EmptyBrandTimeline({
    required this.sourceType,
    required this.dayLabel,
    required this.onAddSlot,
  });

  final ScheduleSourceType sourceType;
  final String dayLabel;
  final VoidCallback? onAddSlot;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final noun = sourceType == ScheduleSourceType.template
        ? 'template'
        : 'library schedule';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, color: tokens.textTertiary),
          const SizedBox(height: 8),
          Text(
            'No $dayLabel slots in this $noun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddSlot,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add slot'),
          ),
        ],
      ),
    );
  }
}

class _BrandScheduleTimeline extends StatelessWidget {
  const _BrandScheduleTimeline({
    required this.slots,
    required this.musicCatalog,
    required this.onSlotTap,
    required this.onSlotDelete,
  });

  final List<ScheduleSlot> slots;
  final List<ScheduleMusicItem> musicCatalog;
  final ValueChanged<ScheduleSlot>? onSlotTap;
  final ValueChanged<ScheduleSlot>? onSlotDelete;

  static const double _hourHeight = 62;
  static const int _startHour = 0;
  static const int _endHour = 24;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    const totalHeight = (_endHour - _startHour) * _hourHeight;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: SizedBox(
        height: totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Column(
                children: List.generate(_endHour - _startHour, (index) {
                  final hour = _startHour + index;
                  return SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          _formatHourLabel(hour),
                          style: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int index = 0; index < _endHour - _startHour; index++)
                    Positioned(
                      top: index * _hourHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: tokens.borderSecondary),
                          ),
                        ),
                      ),
                    ),
                  for (final slot in slots) _buildPositionedSlot(context, slot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedSlot(BuildContext context, ScheduleSlot slot) {
    final tokens = context.camsTokens;
    final music = _findMusic(musicCatalog, slot.musicId);
    final moodGradient = MoodColorHelper.gradientFor(
      music?.collection,
      tokens,
    );
    final shadowColor = MoodColorHelper.shadowColorFor(
      music?.collection,
      tokens,
    );
    final startMinutes = _minutesOfDay(slot.startTime);
    final endMinutes = _minutesOfDay(slot.endTime);
    final top = ((startMinutes - (_startHour * 60)) / 60) * _hourHeight;
    final rawHeight = ((endMinutes - startMinutes) / 60) * _hourHeight;
    final height = rawHeight < 72 ? 72.0 : rawHeight;

    return Positioned(
      top:
          top.clamp(0, ((_endHour - _startHour) * _hourHeight) - 72).toDouble(),
      left: 6,
      right: 10,
      height: height,
      child: InkWell(
        onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: moodGradient,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.42),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _initials(music?.artworkLabel ?? music?.title ?? '?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music?.title ?? 'Missing playlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.startTime} - ${slot.endTime} | ${_daysLabel(slot.daysOfWeek)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete slot',
                onPressed:
                    onSlotDelete == null ? null : () => onSlotDelete!(slot),
                icon: const Icon(Icons.delete_outline),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandScheduleSkeleton extends StatelessWidget {
  const _BrandScheduleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CamsSkeletonBox(height: 44, radius: 22),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CamsSkeletonBox(height: 40, radius: 20)),
              SizedBox(width: 8),
              Expanded(child: CamsSkeletonBox(height: 40, radius: 20)),
            ],
          ),
          SizedBox(height: 16),
          CamsSkeletonLine(width: 180, height: 18),
          SizedBox(height: 12),
          CamsSkeletonList(
            itemCount: 5,
            padding: EdgeInsets.zero,
            showLeading: false,
            showTrailing: true,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.alertErrorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: tokens.error),
      ),
    );
  }
}

class _EmptyBrandScheduleState extends StatelessWidget {
  const _EmptyBrandScheduleState({required this.sourceType});

  final ScheduleSourceType sourceType;

  @override
  Widget build(BuildContext context) {
    final noun =
        sourceType == ScheduleSourceType.template ? 'templates' : 'library';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text('No brand $noun schedules yet.'),
      ),
    );
  }
}

class _SourceTypeBadge extends StatelessWidget {
  const _SourceTypeBadge({required this.type});

  final ScheduleSourceType type;

  @override
  Widget build(BuildContext context) {
    final isTemplate = type == ScheduleSourceType.template;
    final tokens = context.camsTokens;
    final color = isTemplate ? tokens.brandPrimary : tokens.techAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        _sourceTypeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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

String _formatHourLabel(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display $period';
}

int _minutesOfDay(String value) {
  final segments = value.split(':');
  if (segments.length != 2) return 0;
  final hour = int.tryParse(segments[0]) ?? 0;
  final minute = int.tryParse(segments[1]) ?? 0;
  return (hour * 60) + minute;
}

String _initials(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first
        .substring(0, words.first.length < 2 ? 1 : 2)
        .toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

String _sourceTypeLabel(ScheduleSourceType type) {
  return type == ScheduleSourceType.template ? 'Template' : 'Library';
}
