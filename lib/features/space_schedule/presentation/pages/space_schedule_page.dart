import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../cams/presentation/bloc/cams_playback_event.dart';
import '../../../cams/presentation/bloc/cams_playback_state.dart';
import '../../domain/entities/schedule_music_item.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/entities/schedule_source.dart';
import '../bloc/space_schedule_bloc.dart';
import '../bloc/space_schedule_event.dart';
import '../bloc/space_schedule_state.dart';
import '../widgets/schedule_controlled_banner.dart';
import '../widgets/schedule_slot_form_sheet.dart';
import '../widgets/schedule_source_form_dialog.dart';

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
    final camsBloc = _maybeCamsBlocOf(context);
    if (camsBloc != null &&
        camsBloc.state.spaceId?.toLowerCase() != spaceId.toLowerCase()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final latestBloc = _maybeCamsBlocOf(context);
        if (latestBloc == null) return;
        if (latestBloc.state.spaceId?.toLowerCase() != spaceId.toLowerCase()) {
          latestBloc.add(CamsInitPlayback(spaceId: spaceId));
        }
      });
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<SpaceScheduleBloc, SpaceScheduleState>(
            listener: (context, state) {
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
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
          ),
          if (camsBloc != null)
            BlocListener<CamsPlaybackBloc, CamsPlaybackState>(
              listenWhen: (previous, current) =>
                  previous.errorMessage != current.errorMessage &&
                  current.errorMessage != null &&
                  current.errorMessage!.isNotEmpty,
              listener: (context, camsState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(camsState.errorMessage!),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
        child: SafeArea(
          child: BlocBuilder<SpaceScheduleBloc, SpaceScheduleState>(
            builder: (context, state) {
              if (state.status == SpaceScheduleStatus.loading &&
                  state.draftSchedule == null &&
                  state.librarySources.isEmpty &&
                  state.templateSources.isEmpty) {
                return const _ScheduleLoadingView();
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

              if (state.isBrandScheduleControlled &&
                  state.draftSchedule == null) {
                return _BrandControlledOnlyView(
                  palette: palette,
                  spaceName: spaceName,
                  onClose: () => context.pop(),
                );
              }

              switch (state.stage) {
                case SpaceScheduleStage.welcome:
                  final isPlaybackDevice =
                      context.read<SessionCubit>().state.isPlaybackDevice;
                  return _ScheduleWelcomeView(
                    palette: palette,
                    onClose: () => context.pop(),
                    onCreateNew: isPlaybackDevice
                        ? () => _showPlaybackDeviceScheduleSnack(context)
                        : () => context
                            .read<SpaceScheduleBloc>()
                            .add(const SpaceScheduleCreateNewRequested()),
                    onLoadSchedule: isPlaybackDevice
                        ? () => _showPlaybackDeviceScheduleSnack(context)
                        : () => context.read<SpaceScheduleBloc>().add(
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
                    spaceId: spaceId,
                    palette: palette,
                    state: state,
                    onClose: () => context.pop(),
                    onAddSlot: () => _openSlotEditor(context, state: state),
                    onSlotTap: (slot) =>
                        _openSlotEditor(context, state: state, slot: slot),
                    onSlotDelete: (slot) => _confirmDeleteSlot(context, slot),
                    onActionSelected: (action) =>
                        _handleEditorAction(context, action, state),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditorAction(
    BuildContext context,
    _EditorAction action,
    SpaceScheduleState state,
  ) async {
    final session = context.read<SessionCubit>().state;
    if (session.isPlaybackDevice) {
      _showPlaybackDeviceScheduleSnack(context);
      return;
    }

    if (state.isBrandScheduleControlled && action != _EditorAction.about) {
      _showBrandControlledSnack(context);
      return;
    }

    switch (action) {
      case _EditorAction.loadSchedule:
        context.read<SpaceScheduleBloc>().add(
              const SpaceScheduleSourcePickerRequested(
                initialTab: ScheduleSourceType.library,
              ),
            );
        break;
      case _EditorAction.saveToLibrary:
        if (session.currentRole != UserRole.brandManager) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Only brand managers can save schedules to the library.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final result = await showDialog<ScheduleSourceFormPayload>(
          context: context,
          builder: (_) => ScheduleSourceFormDialog(
            title: 'Save to library',
            actionLabel: 'Save copy',
            initialTitle:
                state.draftSchedule?.name ?? '${state.spaceName} copy',
            showDescription: false,
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
                'This schedule manages day-part playback for each space and syncs changes through the CMS schedule API.',
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
    if (context.read<SessionCubit>().state.isPlaybackDevice) {
      _showPlaybackDeviceScheduleSnack(context);
      return;
    }

    if (state.isBrandScheduleControlled) {
      _showBrandControlledSnack(context);
      return;
    }

    final result = await showModalBottomSheet<ScheduleSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleSlotFormSheet(
        title: slot == null ? 'Add schedule slot' : 'Edit schedule slot',
        slot: slot,
        initialDay: state.selectedDay,
        musicCatalog: state.musicCatalog,
      ),
    );

    if (!context.mounted || result == null) return;
    context.read<SpaceScheduleBloc>().add(SpaceScheduleSlotSaved(result));
  }

  Future<void> _confirmDeleteSlot(
    BuildContext context,
    ScheduleSlot slot,
  ) async {
    final tokens = context.camsTokens;
    final state = context.read<SpaceScheduleBloc>().state;
    if (context.read<SessionCubit>().state.isPlaybackDevice) {
      _showPlaybackDeviceScheduleSnack(context);
      return;
    }

    if (state.isBrandScheduleControlled) {
      _showBrandControlledSnack(context);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete schedule slot?'),
        content: Text('Remove ${slot.startTime} - ${slot.endTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.error,
              foregroundColor: tokens.textOnAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!context.mounted || shouldDelete != true) return;
    context.read<SpaceScheduleBloc>().add(SpaceScheduleSlotDeleted(slot.id));
  }
}

class _ScheduleLoadingView extends StatelessWidget {
  const _ScheduleLoadingView();

  @override
  Widget build(BuildContext context) {
    return const CamsSkeletonDashboard(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                foregroundColor: palette.textOnAccent,
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

class _BrandControlledOnlyView extends StatelessWidget {
  const _BrandControlledOnlyView({
    required this.palette,
    required this.spaceName,
    required this.onClose,
  });

  final _SchedulePalette palette;
  final String spaceName;
  final VoidCallback onClose;

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
          const Spacer(),
          Icon(LucideIcons.lock, color: palette.accent, size: 38),
          const SizedBox(height: 18),
          Text(
            'Controlled by brand schedule',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 30,
              height: 1.02,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$spaceName follows the brand schedule because its store is in Strict Sync. Local space slots are read-only here.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.textOnAccent,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
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
            subtitle: 'Start from a saved schedule source',
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
                        color: palette.textOnAccent.withValues(alpha: 0.7),
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
    const isLibrary = true;
    final items = state.librarySources;

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
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No library schedules available yet.',
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
    required this.spaceId,
    required this.palette,
    required this.state,
    required this.onClose,
    required this.onAddSlot,
    required this.onSlotTap,
    required this.onSlotDelete,
    required this.onActionSelected,
  });

  final String spaceId;
  final _SchedulePalette palette;
  final SpaceScheduleState state;
  final VoidCallback onClose;
  final VoidCallback onAddSlot;
  final ValueChanged<ScheduleSlot> onSlotTap;
  final ValueChanged<ScheduleSlot> onSlotDelete;
  final Future<void> Function(_EditorAction action) onActionSelected;

  @override
  Widget build(BuildContext context) {
    final draft = state.draftSchedule;
    final isBrandControlled = state.isBrandScheduleControlled;
    final session = context.read<SessionCubit>().state;
    final isPlaybackDevice = session.isPlaybackDevice;
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
                semanticLabel: 'Preview schedule playback',
                background: palette.error,
                foreground: palette.textOnAccent,
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
                semanticLabel: 'Add schedule slot',
                onTap: isBrandControlled
                    ? () => _showBrandControlledSnack(context)
                    : onAddSlot,
              ),
              const SizedBox(width: 10),
              _CircleActionButton(
                palette: palette,
                icon: Icons.more_vert_rounded,
                semanticLabel: 'Schedule options',
                controlKey: const ValueKey('schedule-options-button'),
                onTap: () async {
                  final action = await showModalBottomSheet<_EditorAction>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ScheduleOptionsSheet(
                      palette: palette,
                      canSaveToLibrary:
                          session.currentRole == UserRole.brandManager,
                    ),
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
        if (isBrandControlled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ScheduleControlledBanner(
              backgroundColor: palette.accent.withValues(alpha: 0.12),
              borderColor: palette.accent.withValues(alpha: 0.28),
              iconColor: palette.accent,
              textColor: palette.textPrimary,
              message:
                  'Controlled by brand schedule. This store is in Strict Sync, so local edits and toggles are locked.',
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (draft != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _maybeCamsBlocOf(context) == null
                ? _ScheduleModeControls(
                    palette: palette,
                    configEnabled: draft.enabled,
                    isSaving: state.status == SpaceScheduleStatus.saving,
                    isBrandControlled: isBrandControlled,
                    camsState: null,
                    onConfigChanged: isBrandControlled || isPlaybackDevice
                        ? null
                        : (enabled) => context
                            .read<SpaceScheduleBloc>()
                            .add(SpaceScheduleToggled(enabled)),
                    onRuntimeChanged: null,
                  )
                : BlocBuilder<CamsPlaybackBloc, CamsPlaybackState>(
                    builder: (context, camsState) {
                      return _ScheduleModeControls(
                        palette: palette,
                        configEnabled: draft.enabled,
                        isSaving: state.status == SpaceScheduleStatus.saving ||
                            camsState.isOverriding,
                        isBrandControlled: isBrandControlled,
                        camsState: camsState,
                        onConfigChanged: isBrandControlled || isPlaybackDevice
                            ? null
                            : (enabled) => context
                                .read<SpaceScheduleBloc>()
                                .add(SpaceScheduleToggled(enabled)),
                        onRuntimeChanged: isBrandControlled
                            ? null
                            : (enabled) => context.read<CamsPlaybackBloc>().add(
                                CamsUpdateSchedulingState(
                                    isScheduling: enabled)),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ],
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
                  onAddSlot: isBrandControlled
                      ? () => _showBrandControlledSnack(context)
                      : onAddSlot,
                )
              : _ScheduleTimeline(
                  palette: palette,
                  slots: daySlots,
                  musicCatalog: state.musicCatalog,
                  onSlotTap: isBrandControlled
                      ? (_) => _showBrandControlledSnack(context)
                      : onSlotTap,
                  onSlotDelete: isBrandControlled
                      ? (_) => _showBrandControlledSnack(context)
                      : onSlotDelete,
                ),
        ),
      ],
    );
  }
}

class _ScheduleModeControls extends StatefulWidget {
  const _ScheduleModeControls({
    required this.palette,
    required this.configEnabled,
    required this.isSaving,
    required this.isBrandControlled,
    required this.camsState,
    required this.onConfigChanged,
    required this.onRuntimeChanged,
  });

  final _SchedulePalette palette;
  final bool configEnabled;
  final bool isSaving;
  final bool isBrandControlled;
  final CamsPlaybackState? camsState;
  final ValueChanged<bool>? onConfigChanged;
  final ValueChanged<bool>? onRuntimeChanged;

  @override
  State<_ScheduleModeControls> createState() => _ScheduleModeControlsState();
}

class _ScheduleModeControlsState extends State<_ScheduleModeControls> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  int? _remainingSecondsUntil(DateTime? utcDeadline) {
    if (utcDeadline == null) return null;
    final remaining = utcDeadline.toUtc().difference(DateTime.now().toUtc());
    return remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final playback = widget.camsState?.playbackState;
    final runtimeEnabled = playback?.isScheduling ?? false;
    final remainingSeconds =
        _remainingSecondsUntil(playback?.schedulingEndsAtUtc) ??
            playback?.schedulingRemainingSeconds;
    final runtimeDetails = <String>[
      if (runtimeEnabled && playback?.schedulingOriginLabel != null)
        'Origin: ${playback!.schedulingOriginLabel}',
      if (runtimeEnabled && playback?.schedulingSlotId?.isNotEmpty == true)
        'Slot: ${playback!.schedulingSlotId}',
      if (runtimeEnabled && remainingSeconds != null)
        'Remaining: ${_formatSeconds(remainingSeconds)}',
      if (runtimeEnabled && playback?.schedulingEndsAtUtc != null)
        'Ends: ${_formatDateTime(playback!.schedulingEndsAtUtc!)}',
    ];
    final iotStatusLabel = playback?.iotStatusLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          _ScheduleSwitchRow(
            palette: palette,
            title: widget.isBrandControlled
                ? 'Brand-controlled scheduling'
                : 'Space-level scheduling',
            semanticLabel: 'Schedule configuration toggle',
            subtitle: widget.isBrandControlled
                ? 'This store is in Strict Sync. Local slots are read-only.'
                : widget.configEnabled
                    ? 'Weekly slots are enabled for this space.'
                    : 'Weekly slots are saved but disabled.',
            value: widget.configEnabled,
            enabled: !widget.isSaving && !widget.isBrandControlled,
            onChanged: widget.onConfigChanged,
          ),
          Divider(height: 18, color: palette.line),
          _ScheduleSwitchRow(
            palette: palette,
            title: widget.isBrandControlled
                ? 'Brand schedule runtime'
                : 'Scheduling runtime',
            controlKey: const ValueKey('schedule-runtime-toggle'),
            semanticLabel: 'Scheduling runtime toggle',
            subtitle: widget.isBrandControlled
                ? 'Runtime is activated by the brand schedule from backend.'
                : runtimeDetails.isEmpty
                    ? 'CAMS will report the active slot when scheduling takes ownership.'
                    : runtimeDetails.join('  |  '),
            value: runtimeEnabled,
            enabled: !widget.isSaving &&
                !widget.isBrandControlled &&
                widget.onRuntimeChanged != null,
            onChanged: widget.onRuntimeChanged,
          ),
          if (iotStatusLabel != null) ...[
            Divider(height: 18, color: palette.line),
            _ScheduleIotStatusRow(
              palette: palette,
              playback: playback!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleIotStatusRow extends StatelessWidget {
  const _ScheduleIotStatusRow({
    required this.palette,
    required this.playback,
  });

  final _SchedulePalette palette;
  final SpacePlaybackState playback;

  @override
  Widget build(BuildContext context) {
    final label = playback.iotStatusLabel ?? 'IoT status';
    final isWarning = playback.hasIotWarning;
    final icon = playback.isIotDeviceAssigned == false
        ? LucideIcons.radioReceiver
        : playback.isIotDeviceOffline
            ? LucideIcons.wifiOff
            : LucideIcons.wifi;
    final color = isWarning ? palette.warning : palette.success;
    final subtitle = playback.isIotDeviceAssigned == false
        ? 'Assign a device before relying on live telemetry.'
        : playback.isIotDeviceOffline
            ? 'Runtime can continue, but telemetry is stale.'
            : 'Live telemetry is available for scheduling context.';

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleSwitchRow extends StatelessWidget {
  const _ScheduleSwitchRow({
    required this.palette,
    required this.title,
    required this.semanticLabel,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.controlKey,
  });

  final _SchedulePalette palette;
  final String title;
  final String semanticLabel;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: semanticLabel,
          button: true,
          toggled: value,
          child: Switch.adaptive(
            key: controlKey,
            value: value,
            activeThumbColor: palette.accent,
            onChanged: enabled ? onChanged : null,
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
    required this.semanticLabel,
    this.background,
    this.foreground,
    this.controlKey,
  });

  final _SchedulePalette palette;
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? background;
  final Color? foreground;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        key: controlKey,
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
                foregroundColor: palette.textOnAccent,
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
    required this.onSlotDelete,
  });

  final _SchedulePalette palette;
  final List<ScheduleSlot> slots;
  final List<ScheduleMusicItem> musicCatalog;
  final ValueChanged<ScheduleSlot> onSlotTap;
  final ValueChanged<ScheduleSlot> onSlotDelete;

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
    final compact = cardHeight <= 110;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 10 : 16,
    );
    final artworkWidth = compact ? 52.0 : 70.0;
    final artworkHeight = compact ? 56.0 : 82.0;
    final titleSize = compact ? 14.0 : 18.0;
    final detailSize = compact ? 11.0 : 13.0;
    final actionSize = compact ? 30.0 : 34.0;
    final actionIconSize = compact ? 20.0 : 22.0;

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
            padding: contentPadding,
            child: Row(
              children: [
                _MiniArtwork(
                  label: music?.artworkLabel ?? 'Add\nMusic',
                  primaryHex: music?.primaryHex ?? '#3F3F3F',
                  secondaryHex: music?.secondaryHex ?? '#666666',
                  width: artworkWidth,
                  height: artworkHeight,
                ),
                SizedBox(width: compact ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        music?.title ?? 'Missing music',
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: palette.textOnAccent,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 6),
                      Text(
                        '${slot.startTime} - ${slot.endTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: palette.textOnAccent.withValues(alpha: 0.76),
                          fontSize: detailSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          music?.artist ?? 'Tap to choose music',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.textOnAccent.withValues(alpha: 0.76),
                            fontSize: detailSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: palette.textOnAccent.withValues(alpha: 0.9),
                      size: actionIconSize,
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    IconButton(
                      key: ValueKey('schedule-slot-delete-${slot.id}'),
                      tooltip: 'Delete schedule slot',
                      onPressed: () => onSlotDelete(slot),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: BoxConstraints.tightFor(
                        width: actionSize,
                        height: actionSize,
                      ),
                      icon: Icon(
                        Icons.delete_outline,
                        color: palette.textOnAccent.withValues(alpha: 0.92),
                        size: actionIconSize,
                      ),
                    ),
                  ],
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
    final tokens = context.camsTokens;

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
              color: tokens.textOnAccent,
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
  const _ScheduleOptionsSheet({
    required this.palette,
    required this.canSaveToLibrary,
  });

  final _SchedulePalette palette;
  final bool canSaveToLibrary;

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
            if (canSaveToLibrary)
              _OptionsTile(
                palette: palette,
                icon: LucideIcons.upload,
                title: 'Save to library',
                subtitle: 'Creates a shareable copy of this schedule',
                onTap: () =>
                    Navigator.pop(context, _EditorAction.saveToLibrary),
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
              subtitle: 'Learn how this schedule syncs with playback',
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

class _SchedulePalette {
  final Color background;
  final Color card;
  final Color cardSoft;
  final Color cardMuted;
  final Color line;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color error;
  final Color success;
  final Color warning;
  final Color textOnAccent;
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
    required this.error,
    required this.success,
    required this.warning,
    required this.textOnAccent,
    required this.textOnCard,
    required this.textMutedOnCard,
  });

  factory _SchedulePalette.of(BuildContext context) {
    final tokens = context.camsTokens;
    return _SchedulePalette(
      background: tokens.bgBase,
      card: tokens.bgContainer,
      cardSoft: tokens.bgElevated,
      cardMuted: tokens.bgLayout,
      line: tokens.borderSecondary,
      textPrimary: tokens.textPrimary,
      textMuted: tokens.textSecondary,
      accent: tokens.brandPrimary,
      error: tokens.error,
      success: tokens.success,
      warning: tokens.warning,
      textOnAccent: tokens.textOnAccent,
      textOnCard: tokens.textPrimary,
      textMutedOnCard: tokens.textSecondary,
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

String _formatSeconds(int seconds) {
  final safeSeconds = seconds < 0 ? 0 : seconds;
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  if (minutes > 0) return '${minutes}m';
  return '${safeSeconds}s';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

int _domainDayFromUi(int value) {
  if (value >= 0 && value <= 6) return value;
  if (value == 7) return 0;
  return 0;
}

CamsPlaybackBloc? _maybeCamsBlocOf(BuildContext context) {
  try {
    return context.read<CamsPlaybackBloc>();
  } catch (_) {
    return null;
  }
}

void _showBrandControlledSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'This space follows the brand schedule in Strict Sync mode.',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showPlaybackDeviceScheduleSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Playback devices can view runtime scheduling state, but cannot edit space schedules.',
      ),
      behavior: SnackBarBehavior.floating,
    ),
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
