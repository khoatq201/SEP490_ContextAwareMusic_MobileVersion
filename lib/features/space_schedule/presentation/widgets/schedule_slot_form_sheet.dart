import 'package:flutter/material.dart';

import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_slot.dart';

class ScheduleSlotFormSheet extends StatefulWidget {
  const ScheduleSlotFormSheet({
    super.key,
    required this.title,
    required this.slot,
    required this.initialDay,
    required this.musicCatalog,
    this.allowMultipleDays = false,
    this.generatedIdPrefix = 'slot',
  });

  final String title;
  final ScheduleSlot? slot;
  final int initialDay;
  final List<ScheduleMusicItem> musicCatalog;
  final bool allowMultipleDays;
  final String generatedIdPrefix;

  @override
  State<ScheduleSlotFormSheet> createState() => _ScheduleSlotFormSheetState();
}

class _ScheduleSlotFormSheetState extends State<ScheduleSlotFormSheet> {
  late final Set<int> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _musicId;

  @override
  void initState() {
    super.initState();
    final initialDays = widget.slot?.daysOfWeek
            .map(_uiDayFromDomainDay)
            .where((day) => day >= 0 && day <= 6)
            .toSet() ??
        <int>{_uiDayFromDomainDay(widget.initialDay)};
    _selectedDays = initialDays.isEmpty
        ? <int>{DateTime.now().weekday % DateTime.sunday}
        : initialDays;
    _startTime = _parseTime(widget.slot?.startTime ?? '09:00');
    _endTime = _parseTime(widget.slot?.endTime ?? '12:00');

    final slotMusicId = widget.slot?.musicId;
    _musicId = widget.musicCatalog.any((item) => item.id == slotMusicId)
        ? slotMusicId
        : (widget.musicCatalog.isEmpty ? null : widget.musicCatalog.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _selectedDays.isNotEmpty &&
        _musicId != null &&
        _minutes(_endTime) > _minutes(_startTime);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.allowMultipleDays ? 'Days' : 'Day',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (day) {
                    final selected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(_shortDayLabels[day]),
                      selected: selected,
                      onSelected: (value) => _updateDay(day, value),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Start',
                        time: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeButton(
                        label: 'End',
                        time: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _musicId,
                  decoration: const InputDecoration(
                    labelText: 'Playlist',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.musicCatalog
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            item.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _musicId = value),
                ),
                if (_minutes(_endTime) <= _minutes(_startTime)) ...[
                  const SizedBox(height: 10),
                  Text(
                    'End time must be later than start time.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('slot-editor-save'),
                    onPressed: isValid ? _submit : null,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateDay(int day, bool selected) {
    setState(() {
      if (!widget.allowMultipleDays) {
        _selectedDays
          ..clear()
          ..add(day);
        return;
      }

      if (selected) {
        _selectedDays.add(day);
      } else if (_selectedDays.length > 1) {
        _selectedDays.remove(day);
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  void _submit() {
    final days = _selectedDays.map(_domainDayFromUi).toSet().toList()..sort();
    Navigator.pop(
      context,
      ScheduleSlot(
        id: widget.slot?.id ??
            '${widget.generatedIdPrefix}-${DateTime.now().millisecondsSinceEpoch}',
        daysOfWeek: days,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        musicId: _musicId!,
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label ${_formatTime(time)}'),
    );
  }
}

const _shortDayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 0,
    minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

int _uiDayFromDomainDay(int value) {
  if (value == 7) return 0;
  if (value >= 0 && value <= 6) return value;
  return 0;
}

int _domainDayFromUi(int value) {
  if (value >= 0 && value <= 6) return value;
  if (value == 7) return 0;
  return 0;
}
