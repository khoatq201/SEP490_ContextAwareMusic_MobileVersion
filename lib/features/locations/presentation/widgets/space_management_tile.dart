import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../space_control/domain/entities/space.dart';
import '../../../store_dashboard/domain/entities/store.dart';
import '../../domain/entities/location_space.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import 'space_settings_sheet.dart';

/// A role-aware card representing a single space inside the Location tab.
/// It highlights the targeted space, shows live playback context when possible,
/// and lets managers quickly swap the active space.
class SpaceManagementTile extends StatelessWidget {
  final LocationSpace space;
  final bool showStoreName;

  const SpaceManagementTile({
    super.key,
    required this.space,
    this.showStoreName = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _SpacePalette.of(context);
    final session = context.watch<SessionCubit>().state;
    final playerState = context.watch<PlayerBloc>().state;
    final camsState = context.watch<CamsPlaybackBloc>().state;
    final locationState = context.watch<LocationBloc>().state;
    final isTargeted = session.currentSpace?.id == space.id;
    final isPairActionBusy = locationState.busySpaceIds.contains(space.id);
    final isTargetedLocalPreview =
        isTargeted && session.isPlaybackDevice && playerState.isLocalPreview;

    final displayMood = _firstNonEmpty([
      if (isTargeted) camsState.currentMoodName,
      space.currentMoodName,
    ]);
    final displayPlaylist = _firstNonEmpty([
      if (isTargeted) camsState.currentPlaylistName,
      space.currentPlaylistName,
    ]);
    final displayTrackName = _firstNonEmpty([
      if (isTargeted && playerState.isSyncedCamsPlayback)
        playerState.currentTrack?.title,
      space.currentTrackName,
      if (isTargetedLocalPreview) playerState.currentTrack?.title,
    ]);
    final displayTrackArtist = _firstNonEmpty([
      if (isTargeted && playerState.isSyncedCamsPlayback)
        playerState.currentTrack?.artist,
      space.currentTrackArtist,
      if (isTargetedLocalPreview) 'Playing locally on this device only',
    ]);
    final isOnline = space.status.isActive || space.isOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTargeted ? palette.accent.withAlpha(130) : palette.border,
          width: isTargeted ? 1.4 : 1,
        ),
        boxShadow: isTargeted
            ? [
                BoxShadow(
                  color: palette.accent.withAlpha(18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accent.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isOnline ? LucideIcons.radio : LucideIcons.radioReceiver,
                    color: palette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              space.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: palette.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isTargeted)
                            _HeaderBadge(
                              icon: LucideIcons.crosshair,
                              label: 'TARGET',
                              color: palette.accent,
                            ),
                          if (isTargeted) const SizedBox(width: 8),
                          if (isTargetedLocalPreview)
                            const _HeaderBadge(
                              icon: LucideIcons.smartphone,
                              label: 'LOCAL',
                              color: Color(0xFFB7791F),
                            ),
                          if (isTargetedLocalPreview) const SizedBox(width: 8),
                          _StatusBadge(isOnline: isOnline, palette: palette),
                        ],
                      ),
                      if (showStoreName && space.storeName != null) ...[
                        const SizedBox(height: 6),
                        _StorePill(
                          storeName: space.storeName!,
                          palette: palette,
                        ),
                      ],
                      if (space.description != null &&
                          space.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          space.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: LucideIcons.layoutTemplate,
                  label: space.type.displayName,
                  palette: palette,
                ),
                _MetaChip(
                  icon: LucideIcons.sparkles,
                  label: displayMood ?? 'No mood',
                  palette: palette,
                ),
                _MetaChip(
                  icon: LucideIcons.listMusic,
                  label: displayPlaylist ?? 'Idle',
                  palette: palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      displayTrackName != null
                          ? LucideIcons.music4
                          : Icons.graphic_eq,
                      color: palette.accent,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTrackName ?? 'No active track',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTrackArtist ??
                              (space.hasLivePlayback
                                  ? 'Streaming in this space'
                                  : 'Waiting for playback'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!session.isPlaybackDevice) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PairingSection(
                space: space,
                palette: palette,
                isBusy: isPairActionBusy,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(height: 1, color: palette.border),
          _ActionRow(
            space: space,
            palette: palette,
            isTargeted: isTargeted,
            isPlaybackDevice: session.isPlaybackDevice,
            onSwap: () => _activateTarget(context, openSpace: false),
            onSchedule: () => context.push(_buildSpaceScheduleLocation(space)),
            onOpen: () => _activateTarget(context, openSpace: true),
          ),
        ],
      ),
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  void _activateTarget(
    BuildContext context, {
    required bool openSpace,
  }) {
    final sessionCubit = context.read<SessionCubit>();
    final session = sessionCubit.state;

    final targetStoreName =
        space.storeName ?? session.currentStore?.name ?? 'Store';
    final targetStore = Store(
      id: space.storeId,
      name: targetStoreName,
      brandId: session.currentStore?.brandId ?? '',
    );
    final targetSpace = Space(
      id: space.id,
      name: space.name,
      storeId: space.storeId,
      type: space.type,
      description: space.description,
      status: space.status,
      currentPlaylistId: space.currentPlaylistId,
      currentMood: space.currentMoodName,
    );

    if (session.currentStore?.id != space.storeId) {
      sessionCubit.changeStore(targetStore);
    }
    sessionCubit.changeSpace(targetSpace);

    if (openSpace) {
      context.go('/now-playing');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Targeting ${space.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PairingSection extends StatelessWidget {
  const _PairingSection({
    required this.space,
    required this.palette,
    required this.isBusy,
  });

  final LocationSpace space;
  final _SpacePalette palette;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final pairInfo = space.pairDeviceInfo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.accent.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  space.hasPairedPlaybackDevice
                      ? LucideIcons.smartphone
                      : space.hasActivePairCode
                          ? LucideIcons.keyRound
                          : LucideIcons.link2Off,
                  color: palette.accent,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playback device',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      space.pairingStatusLabel,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                ),
            ],
          ),
          if (space.hasActivePairCode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      space.activePairCode!.displayCode,
                      style: GoogleFonts.outfit(
                        color: palette.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  _PairCodeCountdown(
                    expiresAt: space.activePairCode!.expiresAt,
                    palette: palette,
                  ),
                ],
              ),
            ),
          ] else if (space.hasPairedPlaybackDevice &&
              pairInfo?.lastActiveAtUtc != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last active ${_formatRelative(pairInfo!.lastActiveAtUtc!)}',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!space.hasPairedPlaybackDevice)
                _PairActionChip(
                  label: space.hasActivePairCode
                      ? 'Generate new code'
                      : 'Generate code',
                  icon: LucideIcons.badgePlus,
                  palette: palette,
                  enabled: !isBusy,
                  onTap: () => context
                      .read<LocationBloc>()
                      .add(LocationGeneratePairCodeRequested(space.id)),
                ),
              if (space.hasActivePairCode)
                _PairActionChip(
                  label: 'Revoke',
                  icon: LucideIcons.shield,
                  palette: palette,
                  enabled: !isBusy,
                  onTap: () => context
                      .read<LocationBloc>()
                      .add(LocationRevokePairCodeRequested(space.id)),
                ),
              if (space.hasPairedPlaybackDevice)
                _PairActionChip(
                  label: 'Unpair',
                  icon: LucideIcons.unlink,
                  palette: palette,
                  enabled: !isBusy,
                  onTap: () => context
                      .read<LocationBloc>()
                      .add(LocationUnpairDeviceRequested(space.id)),
                  destructive: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRelative(DateTime value) {
    final diff = DateTime.now().toUtc().difference(value.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PairCodeCountdown extends StatefulWidget {
  const _PairCodeCountdown({
    required this.expiresAt,
    required this.palette,
  });

  final DateTime expiresAt;
  final _SpacePalette palette;

  @override
  State<_PairCodeCountdown> createState() => _PairCodeCountdownState();
}

class _PairCodeCountdownState extends State<_PairCodeCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    final remaining = widget.expiresAt.difference(DateTime.now().toUtc());
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.palette.accent.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$minutes:$seconds',
        style: GoogleFonts.inter(
          color: widget.palette.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PairActionChip extends StatelessWidget {
  const _PairActionChip({
    required this.label,
    required this.icon,
    required this.palette,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final _SpacePalette palette;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accentColor = destructive ? AppColors.error : palette.accent;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(enabled ? 18 : 8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accentColor.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorePill extends StatelessWidget {
  const _StorePill({
    required this.storeName,
    required this.palette,
  });

  final String storeName;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.store, size: 13, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            storeName,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOnline, required this.palette});
  final bool isOnline;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.error;
    final label = isOnline ? 'ONLINE' : 'OFFLINE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final _SpacePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.space,
    required this.palette,
    required this.isTargeted,
    required this.isPlaybackDevice,
    required this.onSwap,
    required this.onSchedule,
    required this.onOpen,
  });

  final LocationSpace space;
  final _SpacePalette palette;
  final bool isTargeted;
  final bool isPlaybackDevice;
  final VoidCallback onSwap;
  final VoidCallback onSchedule;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: isPlaybackDevice
                ? LucideIcons.link2
                : isTargeted
                    ? LucideIcons.checkCircle2
                    : LucideIcons.arrowRightLeft,
            label: isPlaybackDevice
                ? 'Paired'
                : isTargeted
                    ? 'Targeted'
                    : 'Swap here',
            palette: palette,
            enabled: !isPlaybackDevice && !isTargeted,
            onTap: onSwap,
          ),
        ),
        Container(width: 1, height: 52, color: palette.border),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.calendar,
            label: 'Schedule',
            palette: palette,
            onTap: onSchedule,
          ),
        ),
        Container(width: 1, height: 52, color: palette.border),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.panelTopOpen,
            label: 'Open',
            palette: palette,
            onTap: onOpen,
          ),
        ),
        Container(width: 1, height: 52, color: palette.border),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.settings,
            label: 'Settings',
            palette: palette,
            onTap: () {
              final session = context.read<SessionCubit>().state;
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SpaceSettingsSheet(
                  space: space,
                  isPlaybackDevice: session.isPlaybackDevice,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _buildSpaceScheduleLocation(LocationSpace space) {
  return Uri(
    path: '/space-schedule',
    queryParameters: {
      'spaceId': space.id,
      'storeId': space.storeId,
      'spaceName': space.name,
    },
  ).toString();
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final _SpacePalette palette;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? palette.textPrimary : palette.textMuted.withAlpha(140);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpacePalette {
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _SpacePalette({
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  factory _SpacePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _SpacePalette(
        card: AppColors.surfaceDark,
        panel: Color(0xFF121B26),
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
      );
    }
    return const _SpacePalette(
      card: AppColors.surface,
      panel: Color(0xFFF8F6F2),
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
    );
  }
}
