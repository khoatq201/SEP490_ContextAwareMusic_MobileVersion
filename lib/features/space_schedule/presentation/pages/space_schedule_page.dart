import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/entities/schedule_source.dart';
import '../bloc/space_schedule_bloc.dart';
import '../bloc/space_schedule_event.dart';
import '../bloc/space_schedule_state.dart';

class SpaceSchedulePage extends StatelessWidget {
  final String spaceId;
  final String storeId;
  final String spaceName;

  const SpaceSchedulePage({
    super.key,
    required this.spaceId,
    required this.storeId,
    required this.spaceName,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SchedulePalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocConsumer<SpaceScheduleBloc, SpaceScheduleState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context
                  .read<SpaceScheduleBloc>()
                  .add(const SpaceScheduleFeedbackCleared());
            } else if (state.feedbackMessage != null &&
                state.feedbackMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.feedbackMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context
                  .read<SpaceScheduleBloc>()
                  .add(const SpaceScheduleFeedbackCleared());
            }
          },
          builder: (context, state) {
            if (state.status == SpaceScheduleStatus.loading &&
                state.draftSchedule == null &&
                state.librarySources.isEmpty &&
                state.templateSources.isEmpty) {
              return _ScheduleLoadingView(palette: palette);
            }

            if (state.status == SpaceScheduleStatus.error &&
                state.draftSchedule == null &&
                state.librarySources.isEmpty &&
                state.templateSources.isEmpty) {
              return _ScheduleErrorView(
                palette: palette,
                onRetry: () {
                  context.read<SpaceScheduleBloc>().add(
                        SpaceScheduleStarted(
                          spaceId: spaceId,
                          storeId: storeId,
                          spaceName: spaceName,
                        ),
                      );
                },
              );
            }

            switch (state.stage) {
              case SpaceScheduleStage.welcome:
                return _ScheduleWelcomeView(
                  palette: palette,
                  onClose: () => context.pop(),
                  onCreateNew: () => context
                      .read<SpaceScheduleBloc>()
                      .add(const SpaceScheduleCreateNewRequested()),
                  onLoadSchedule: () => context.read<SpaceScheduleBloc>().add(
                        const SpaceScheduleSourcePickerRequested(
                          initialTab: ScheduleSourceType.library,
                        ),
                      ),
                );
              case SpaceScheduleStage.sourcePicker:
                return _ScheduleSourcePickerView(
                  palette: palette,
                  state: state,
                  onClose: () {
                    if (state.draftSchedule != null) {
                      context
                          .read<SpaceScheduleBloc>()
                          .add(const SpaceScheduleEditorReopened());
                    } else {
                      context.pop();
                    }
                  },
                );
              case SpaceScheduleStage.editor:
                return _ScheduleEditorView(
                  palette: palette,
                  state: state,
                  onClose: () => context.pop(),
                  onAddSlot: () => _openSlotEditor(context, state: state),
                  onSlotTap: (slot) =>
                      _openSlotEditor(context, state: state, slot: slot),
                  onActionSelected: (action) =>
                      _handleEditorAction(context, action, state),
                );
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleEditorAction(
    BuildContext context,
    _EditorAction action,
    SpaceScheduleState state,
  ) async {
    switch (action) {
      case _EditorAction.loadSchedule:
        context.read<SpaceScheduleBloc>().add(
              const SpaceScheduleSourcePickerRequested(
                initialTab: ScheduleSourceType.library,
              ),
            );
        break;
      case _EditorAction.saveToLibrary:
        final result = await showModalBottomSheet<_SaveToLibraryPayload>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SaveToLibrarySheet(
            palette: _SchedulePalette.of(context),
            initialTitle:
                state.draftSchedule?.name ?? '${state.spaceName} copy',
          ),
        );
        if (!context.mounted || result == null) return;
        context.read<SpaceScheduleBloc>().add(
              SpaceScheduleSavedToLibrary(
                title: result.title,
                subtitle: result.subtitle,
              ),
            );
        break;
      case _EditorAction.changeMode:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weekly scheduling mode is the only mode in v1.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case _EditorAction.about:
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _InfoSheet(
            palette: _SchedulePalette.of(context),
            title: 'About the zone schedule',
            description:
                'This mock schedule models day-part playback for each space while backend APIs are still being prepared.',
          ),
        );
        break;
    }
  }

  Future<void> _openSlotEditor(
    BuildContext context, {
    required SpaceScheduleState state,
    ScheduleSlot? slot,
  }) async {
    final result = await showModalBottomSheet<ScheduleSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotEditorSheet(
        palette: _SchedulePalette.of(context),
        slot: slot,
        selectedDay: state.selectedDay,
        musicCatalog: state.musicCatalog,
      ),
    );

    if (!context.mounted || result == null) return;
    context.read<SpaceScheduleBloc>().add(SpaceScheduleSlotSaved(result));
  }
}

class _ScheduleLoadingView extends StatelessWidget {
  const _ScheduleLoadingView({required this.palette});

  final _SchedulePalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: palette.accent),
          const SizedBox(height: 16),
          Text(
            'Loading schedule...',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleErrorView extends StatelessWidget {
  const _ScheduleErrorView({
    required this.palette,
    required this.onRetry,
  });

  final _SchedulePalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarX2, color: palette.textMuted, size: 40),
            const SizedBox(height: 16),
            Text(
              'We could not load this schedule.',
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try again to rebuild the draft and available schedule sources.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleWelcomeView extends StatelessWidget {
  const _ScheduleWelcomeView({
    required this.palette,
    required this.onClose,
    required this.onCreateNew,
    required this.onLoadSchedule,
  });

  final _SchedulePalette palette;
  final VoidCallback onClose;
  final VoidCallback onCreateNew;
  final VoidCallback onLoadSchedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: palette.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'First schedule,\nlet\'s go.',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 38,
              height: 0.96,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 26),
          _WelcomeActionCard(
            palette: palette,
            title: 'Load schedule',
            subtitle: 'Start from your own schedule or a template',
            onTap: onLoadSchedule,
            primaryHex: '#4C117F',
            secondaryHex: '#9E5FFF',
            topLabel: 'READY-MADE',
          ),
          const SizedBox(height: 12),
          _WelcomeActionCard(
            palette: palette,
            title: 'Create new',
            subtitle: 'A blank canvas for all your favorite playlists',
            onTap: onCreateNew,
            primaryHex: '#48147C',
            secondaryHex: '#67D0E7',
            topLabel: 'BLANK',
          ),
        ],
      ),
    );
  }
}

class _WelcomeActionCard extends StatelessWidget {
  const _WelcomeActionCard({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.primaryHex,
    required this.secondaryHex,
    required this.topLabel,
  });

  final _SchedulePalette palette;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String primaryHex;
  final String secondaryHex;
  final String topLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: palette.textOnCard,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: palette.textMutedOnCard,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 112,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(22),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _colorFromHex(primaryHex),
                    _colorFromHex(secondaryHex),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Text(
                      topLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 18,
                    child: _MiniArtwork(
                      label: 'Indie Pop',
                      primaryHex: secondaryHex,
                      secondaryHex: '#E7A3FF',
                      angle: -0.1,
                    ),
                  ),
                  const Positioned(
                    bottom: 14,
                    left: 10,
                    child: _MiniArtwork(
                      label: 'Ambient',
                      primaryHex: '#4F73D6',
                      secondaryHex: '#88E7F2',
                      angle: 0.14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSourcePickerView extends StatelessWidget {
  const _ScheduleSourcePickerView({
    required this.palette,
    required this.state,
    required this.onClose,
  });

  final _SchedulePalette palette;
  final SpaceScheduleState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isLibrary = state.sourcePickerTab == ScheduleSourceType.library;
    final items = isLibrary
        ? state.librarySources
        : state.templateSources.cast<ScheduleSource>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Load schedule',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse what\'s available and change what\'s playing in your zone schedule.',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: palette.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _SourceFilterChip(
                palette: palette,
                label: 'Library',
                selected: isLibrary,
                onTap: () => context.read<SpaceScheduleBloc>().add(
                      const SpaceScheduleSourceTabChanged(
                          ScheduleSourceType.library),
                    ),
              ),
              const SizedBox(width: 10),
              _SourceFilterChip(
                palette: palette,
                label: 'Templates',
                selected: !isLibrary,
                onTap: () => context.read<SpaceScheduleBloc>().add(
                      const SpaceScheduleSourceTabChanged(
                          ScheduleSourceType.template),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No schedule sources available yet.',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 14,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ScheduleSourceCard(
                      palette: palette,
                      source: item,
                      musicCatalog: state.musicCatalog,
                      onTap: () => context
                          .read<SpaceScheduleBloc>()
                          .add(SpaceScheduleSourceSelected(item)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SourceFilterChip extends StatelessWidget {
  const _SourceFilterChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _SchedulePalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? palette.cardMuted : Colors.transparent,
          border:
              Border.all(color: selected ? Colors.transparent : palette.line),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScheduleSourceCard extends StatelessWidget {
  const _ScheduleSourceCard({
    required this.palette,
    required this.source,
    required this.musicCatalog,
    required this.onTap,
  });

  final _SchedulePalette palette;
  final ScheduleSource source;
  final List<ScheduleMusicItem> musicCatalog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewMusic = source.schedule.slots
        .map((slot) => _findMusic(musicCatalog, slot.musicId))
        .whereType<ScheduleMusicItem>()
        .take(2)
        .toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: palette.cardSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.line.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.calendarDays, color: palette.textMuted, size: 18),
            const SizedBox(height: 10),
            Text(
              source.type == ScheduleSourceType.template
                  ? 'READY-MADE'
                  : 'LIBRARY',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: _MiniArtwork(
                      label: previewMusic.isNotEmpty
                          ? previewMusic.first.artworkLabel
                          : 'Blank\nSlot',
                      primaryHex: previewMusic.isNotEmpty
                          ? previewMusic.first.primaryHex
                          : '#444444',
                      secondaryHex: previewMusic.isNotEmpty
                          ? previewMusic.first.secondaryHex
                          : '#777777',
                      angle: -0.08,
                      width: 78,
                      height: 86,
                    ),
                  ),
                  if (previewMusic.length > 1)
                    Positioned(
                      top: 0,
                      right: 4,
                      child: _MiniArtwork(
                        label: previewMusic[1].artworkLabel,
                        primaryHex: previewMusic[1].primaryHex,
                        secondaryHex: previewMusic[1].secondaryHex,
                        angle: 0.08,
                        width: 70,
                        height: 82,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              source.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEditorView extends StatelessWidget {
  const _ScheduleEditorView({
    required this.palette,
    required this.state,
    required this.onClose,
    required this.onAddSlot,
    required this.onSlotTap,
    required this.onActionSelected,
  });

  final _SchedulePalette palette;
  final SpaceScheduleState state;
  final VoidCallback onClose;
  final VoidCallback onAddSlot;
  final ValueChanged<ScheduleSlot> onSlotTap;
  final Future<void> Function(_EditorAction action) onActionSelected;

  @override
  Widget build(BuildContext context) {
    final draft = state.draftSchedule;
    final allSlots = draft?.slots ?? const <ScheduleSlot>[];
    final daySlots = allSlots
        .where(
          (slot) =>
              slot.daysOfWeek.contains(_domainDayFromUi(state.selectedDay)),
        )
        .toList()
      ..sort((a, b) => _minutesOfDay(a.startTime).compareTo(
            _minutesOfDay(b.startTime),
          ));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: palette.textMuted),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCHEDULE',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.spaceName ?? 'Schedule',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleActionButton(
                palette: palette,
                icon: Icons.play_arrow_rounded,
                background: AppColors.error,
                foreground: Colors.white,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Playback preview will be connected later.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _CircleActionButton(
                palette: palette,
                icon: Icons.add,
                onTap: onAddSlot,
              ),
              const SizedBox(width: 10),
              _CircleActionButton(
                palette: palette,
                icon: Icons.more_vert_rounded,
                onTap: () async {
                  final action = await showModalBottomSheet<_EditorAction>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ScheduleOptionsSheet(palette: palette),
                  );
                  if (action != null && context.mounted) {
                    await onActionSelected(action);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final selected = state.selectedDay == index;
              return _DayChip(
                palette: palette,
                label: _uiDayLabels[index],
                selected: selected,
                onTap: () => context
                    .read<SpaceScheduleBloc>()
                    .add(SpaceScheduleDaySelected(index)),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _uiDayLabels.length,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: daySlots.isEmpty
              ? _EmptyTimelineView(
                  palette: palette,
                  onAddSlot: onAddSlot,
                )
              : _ScheduleTimeline(
                  palette: palette,
                  slots: daySlots,
                  musicCatalog: state.musicCatalog,
                  onSlotTap: onSlotTap,
                ),
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.palette,
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
  });

  final _SchedulePalette palette;
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? palette.cardMuted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: foreground ?? palette.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _SchedulePalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? palette.cardMuted : Colors.transparent,
          border: Border.all(color: palette.line),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTimelineView extends StatelessWidget {
  const _EmptyTimelineView({
    required this.palette,
    required this.onAddSlot,
  });

  final _SchedulePalette palette;
  final VoidCallback onAddSlot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: palette.cardSoft,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: palette.line),
              ),
              child: Icon(LucideIcons.calendarPlus,
                  color: palette.textMuted, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No music scheduled yet.',
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first weekly slot to start shaping the vibe for this space.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddSlot,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'Add slot',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTimeline extends StatelessWidget {
  const _ScheduleTimeline({
    required this.palette,
    required this.slots,
    required this.musicCatalog,
    required this.onSlotTap,
  });

  final _SchedulePalette palette;
  final List<ScheduleSlot> slots;
  final List<ScheduleMusicItem> musicCatalog;
  final ValueChanged<ScheduleSlot> onSlotTap;

  static const double _hourHeight = 88;
  static const int _startHour = 8;
  static const int _endHour = 23;

  @override
  Widget build(BuildContext context) {
    const totalHeight = (_endHour - _startHour) * _hourHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: SizedBox(
        height: totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              child: Column(
                children: List.generate(_endHour - _startHour, (index) {
                  final hour = _startHour + index;
                  return SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        _formatHourLabel(hour),
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Stack(
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
                            top: BorderSide(
                              color: palette.line.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (final slot in slots) _buildPositionedSlot(slot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedSlot(ScheduleSlot slot) {
    final music = _findMusic(musicCatalog, slot.musicId);
    final startMinutes = _minutesOfDay(slot.startTime);
    final endMinutes = _minutesOfDay(slot.endTime);
    final top = ((startMinutes - (_startHour * 60)) / 60) * _hourHeight;
    final rawHeight = ((endMinutes - startMinutes) / 60) * _hourHeight;
    final cardHeight = rawHeight < 96 ? 96.0 : rawHeight;

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: cardHeight,
      child: InkWell(
        onTap: () => onSlotTap(slot),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _colorFromHex(music?.primaryHex ?? '#491183'),
                _colorFromHex(music?.secondaryHex ?? '#7B44C3'),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _colorFromHex(music?.secondaryHex ?? '#7B44C3')
                    .withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniArtwork(
                  label: music?.artworkLabel ?? 'Add\nMusic',
                  primaryHex: music?.primaryHex ?? '#3F3F3F',
                  secondaryHex: music?.secondaryHex ?? '#666666',
                  width: 70,
                  height: 82,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        music?.title ?? 'Missing music',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${slot.startTime} - ${slot.endTime}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        music?.artist ?? 'Tap to choose music',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({
    required this.label,
    required this.primaryHex,
    required this.secondaryHex,
    this.angle = 0,
    this.width = 74,
    this.height = 84,
  });

  final String label;
  final String primaryHex;
  final String secondaryHex;
  final double angle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _colorFromHex(primaryHex),
              _colorFromHex(secondaryHex),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleOptionsSheet extends StatelessWidget {
  const _ScheduleOptionsSheet({required this.palette});

  final _SchedulePalette palette;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            _OptionsTile(
              palette: palette,
              icon: LucideIcons.download,
              title: 'Load schedule',
              subtitle: 'Copies music from another schedule',
              onTap: () => Navigator.pop(context, _EditorAction.loadSchedule),
            ),
            _OptionsTile(
              palette: palette,
              icon: LucideIcons.upload,
              title: 'Save to library',
              subtitle: 'Creates a shareable copy of this schedule',
              onTap: () => Navigator.pop(context, _EditorAction.saveToLibrary),
            ),
            _OptionsTile(
              palette: palette,
              icon: LucideIcons.calendarRange,
              title: 'Change scheduling mode',
              subtitle: 'You\'re using weekly scheduling',
              onTap: () => Navigator.pop(context, _EditorAction.changeMode),
            ),
            _OptionsTile(
              palette: palette,
              icon: LucideIcons.info,
              title: 'About the zone schedule',
              subtitle: 'Learn what this mock schedule does in v1',
              onTap: () => Navigator.pop(context, _EditorAction.about),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsTile extends StatelessWidget {
  const _OptionsTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final _SchedulePalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(icon, color: palette.textMuted, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.palette,
    required this.title,
    required this.description,
  });

  final _SchedulePalette palette;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotEditorSheet extends StatefulWidget {
  const _SlotEditorSheet({
    required this.palette,
    required this.slot,
    required this.selectedDay,
    required this.musicCatalog,
  });

  final _SchedulePalette palette;
  final ScheduleSlot? slot;
  final int selectedDay;
  final List<ScheduleMusicItem> musicCatalog;

  @override
  State<_SlotEditorSheet> createState() => _SlotEditorSheetState();
}

class _SlotEditorSheetState extends State<_SlotEditorSheet> {
  late int _selectedDay;
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;
  ScheduleMusicItem? _selectedMusic;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.slot?.daysOfWeek.isNotEmpty == true
        ? _uiDayFromDomainDay(widget.slot!.daysOfWeek.first)
        : widget.selectedDay;
    _fromTime = _timeOfDayFromString(widget.slot?.startTime ?? '14:00');
    _toTime = _timeOfDayFromString(widget.slot?.endTime ?? '16:00');
    _selectedMusic = widget.slot == null
        ? null
        : _findMusic(widget.musicCatalog, widget.slot!.musicId);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final durationMinutes = _toTime.hour * 60 +
        _toTime.minute -
        (_fromTime.hour * 60 + _fromTime.minute);
    final isLocallyValid = _selectedMusic != null && durationMinutes > 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Day & Time',
                        style: GoogleFonts.poppins(
                          color: palette.textPrimary,
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: palette.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DecoratedField(
                  palette: palette,
                  label: 'Day',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedDay,
                      dropdownColor: palette.cardMuted,
                      isExpanded: true,
                      iconEnabledColor: palette.textMuted,
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      items: List.generate(
                        _uiDayLabels.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(_fullDayLabels[index]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedDay = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        palette: palette,
                        label: 'From',
                        time: _fromTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _fromTime,
                          );
                          if (picked != null) {
                            setState(() => _fromTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeField(
                        palette: palette,
                        label: 'To',
                        time: _toTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _toTime,
                          );
                          if (picked != null) {
                            setState(() => _toTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DecoratedField(
                        palette: palette,
                        label: 'Duration',
                        child: Text(
                          durationMinutes > 0
                              ? _formatDuration(durationMinutes)
                              : 'Invalid',
                          style: GoogleFonts.inter(
                            color: durationMinutes > 0
                                ? palette.textPrimary
                                : AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'Music',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Add something to get started!',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final music = await showModalBottomSheet<ScheduleMusicItem>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _MusicPickerSheet(
                        palette: palette,
                        musicCatalog: widget.musicCatalog,
                      ),
                    );
                    if (music != null) {
                      setState(() => _selectedMusic = music);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 148,
                    height: 212,
                    decoration: BoxDecoration(
                      color: palette.cardSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.line),
                    ),
                    child: _selectedMusic == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  color: palette.textMuted, size: 40),
                              const SizedBox(height: 10),
                              Text(
                                'Add music',
                                style: GoogleFonts.inter(
                                  color: palette.textMuted,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _MiniArtwork(
                                    label: _selectedMusic!.artworkLabel,
                                    primaryHex: _selectedMusic!.primaryHex,
                                    secondaryHex: _selectedMusic!.secondaryHex,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedMusic!.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: palette.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedMusic!.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: palette.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLocallyValid
                        ? () {
                            Navigator.pop(
                              context,
                              ScheduleSlot(
                                id: widget.slot?.id ??
                                    'slot-${DateTime.now().millisecondsSinceEpoch}',
                                daysOfWeek: [_domainDayFromUi(_selectedDay)],
                                startTime: _formatTime(_fromTime),
                                endTime: _formatTime(_toTime),
                                musicId: _selectedMusic!.id,
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      disabledBackgroundColor:
                          AppColors.error.withValues(alpha: 0.35),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    key: const ValueKey('slot-editor-save'),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecoratedField extends StatelessWidget {
  const _DecoratedField({
    required this.palette,
    required this.label,
    required this.child,
  });

  final _SchedulePalette palette;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.palette,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final _SchedulePalette palette;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _DecoratedField(
        palette: palette,
        label: label,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatTimeLabel(time),
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MusicPickerSheet extends StatelessWidget {
  const _MusicPickerSheet({
    required this.palette,
    required this.musicCatalog,
  });

  final _SchedulePalette palette;
  final List<ScheduleMusicItem> musicCatalog;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add music',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                shrinkWrap: true,
                itemCount: musicCatalog.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final music = musicCatalog[index];
                  return InkWell(
                    key: ValueKey('music-option-${music.id}'),
                    onTap: () => Navigator.pop(context, music),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.cardSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.line),
                      ),
                      child: Row(
                        children: [
                          _MiniArtwork(
                            label: music.artworkLabel,
                            primaryHex: music.primaryHex,
                            secondaryHex: music.secondaryHex,
                            width: 76,
                            height: 86,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  music.title,
                                  style: GoogleFonts.poppins(
                                    color: palette.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  music.artist,
                                  style: GoogleFonts.inter(
                                    color: palette.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (music.collection != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    music.collection!,
                                    style: GoogleFonts.inter(
                                      color: palette.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.add_circle_outline,
                              color: palette.textMuted, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveToLibrarySheet extends StatefulWidget {
  const _SaveToLibrarySheet({
    required this.palette,
    required this.initialTitle,
  });

  final _SchedulePalette palette;
  final String initialTitle;

  @override
  State<_SaveToLibrarySheet> createState() => _SaveToLibrarySheetState();
}

class _SaveToLibrarySheetState extends State<_SaveToLibrarySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtitleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Save to library',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a reusable schedule source you can load into any space later.',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(color: palette.textPrimary),
                decoration: _inputDecoration(
                  palette,
                  'Title',
                  'Lunch Rush Copy',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subtitleController,
                style: GoogleFonts.inter(color: palette.textPrimary),
                decoration: _inputDecoration(
                  palette,
                  'Subtitle',
                  'Optional note for your team',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _titleController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            _SaveToLibraryPayload(
                              title: _titleController.text.trim(),
                              subtitle: _subtitleController.text.trim().isEmpty
                                  ? null
                                  : _subtitleController.text.trim(),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Save copy',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    _SchedulePalette palette,
    String label,
    String hint,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: palette.textMuted),
      hintStyle: GoogleFonts.inter(color: palette.textMuted),
      filled: true,
      fillColor: palette.cardMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SaveToLibraryPayload {
  final String title;
  final String? subtitle;

  const _SaveToLibraryPayload({
    required this.title,
    this.subtitle,
  });
}

class _SchedulePalette {
  final Color background;
  final Color card;
  final Color cardSoft;
  final Color cardMuted;
  final Color line;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color textOnCard;
  final Color textMutedOnCard;

  const _SchedulePalette({
    required this.background,
    required this.card,
    required this.cardSoft,
    required this.cardMuted,
    required this.line,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.textOnCard,
    required this.textMutedOnCard,
  });

  factory _SchedulePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SchedulePalette(
        background: Color(0xFF101010),
        card: Color(0xFFF7F7F7),
        cardSoft: Color(0xFF171717),
        cardMuted: Color(0xFF2A2A2A),
        line: Color(0xFF313131),
        textPrimary: Colors.white,
        textMuted: Color(0xFFB1B1B1),
        accent: AppColors.primaryCyan,
        textOnCard: Color(0xFF181818),
        textMutedOnCard: Color(0xFF676767),
      );
    }
    return const _SchedulePalette(
      background: Color(0xFFF5F5F5),
      card: Colors.white,
      cardSoft: Colors.white,
      cardMuted: Color(0xFFEAEAEA),
      line: Color(0xFFD6D6D6),
      textPrimary: Color(0xFF151515),
      textMuted: Color(0xFF666666),
      accent: AppColors.primaryOrange,
      textOnCard: Color(0xFF181818),
      textMutedOnCard: Color(0xFF676767),
    );
  }
}

enum _EditorAction { loadSchedule, saveToLibrary, changeMode, about }

const List<String> _uiDayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];
const List<String> _fullDayLabels = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

String _formatHourLabel(int hour) {
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final normalized = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$normalized:00 $suffix';
}

int _minutesOfDay(String value) {
  final segments = value.split(':');
  final hour = int.tryParse(segments.first) ?? 0;
  final minute = int.tryParse(segments.last) ?? 0;
  return hour * 60 + minute;
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours > 0 && remaining > 0) {
    return '${hours}h ${remaining}m';
  }
  if (hours > 0) {
    return '$hours hours';
  }
  return '$minutes min';
}

int _domainDayFromUi(int value) => value == 0 ? 7 : value;

int _uiDayFromDomainDay(int value) => value == 7 ? 0 : value;

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimeLabel(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

TimeOfDay _timeOfDayFromString(String value) {
  final segments = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(segments.first) ?? 0,
    minute: int.tryParse(segments.last) ?? 0,
  );
}

ScheduleMusicItem? _findMusic(
  List<ScheduleMusicItem> catalog,
  String musicId,
) {
  for (final item in catalog) {
    if (item.id == musicId) return item;
  }
  return null;
}

Color _colorFromHex(String value) {
  final buffer = StringBuffer();
  final hex = value.replaceFirst('#', '');
  if (hex.length == 6) buffer.write('ff');
  buffer.write(hex);
  return Color(int.parse(buffer.toString(), radix: 16));
}
