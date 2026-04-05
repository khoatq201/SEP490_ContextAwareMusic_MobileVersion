import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../hub_management/presentation/pages/space_hub_page.dart';
import '../../../music_policy/data/models/fuzzy_override_profile_request.dart';
import '../../../music_policy/presentation/widgets/fuzzy_override_editor_sheet.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../../domain/entities/location_space.dart';
import '../../domain/usecases/location_usecases.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';

class SpaceSettingsSheet extends StatelessWidget {
  const SpaceSettingsSheet({
    super.key,
    required this.space,
    required this.isPlaybackDevice,
  });

  final LocationSpace space;
  final bool isPlaybackDevice;

  bool _canManageSpace(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    return !isPlaybackDevice &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
  }

  Future<void> _editSpace(BuildContext context) async {
    final nameController = TextEditingController(text: space.name);
    final descriptionController =
        TextEditingController(text: space.description ?? '');
    var selectedType = space.type;

    final request = await showDialog<SpaceMutationRequest>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Space'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Space name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SpaceTypeEnum>(
                      initialValue: selectedType,
                      items: SpaceTypeEnum.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedType = value);
                      },
                      decoration:
                          const InputDecoration(labelText: 'Space type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar(
                        context,
                        'Space name is required.',
                        isError: true,
                      );
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      SpaceMutationRequest(
                        name: name,
                        type: selectedType.value,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (request == null) return;

    final result = await sl<UpdateSpace>()(space.id, request);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showSnackBar(context, failure.message, isError: true),
      (success) {
        _reloadLocations(context);
        _showSnackBar(
          context,
          success.message ?? 'Space updated successfully.',
        );
      },
    );
  }

  Future<void> _toggleSpaceStatus(BuildContext context) async {
    final result = await sl<ToggleSpaceStatus>()(space.id);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showSnackBar(context, failure.message, isError: true),
      (success) {
        _reloadLocations(context);
        _showSnackBar(
          context,
          success.message ?? 'Space status updated successfully.',
        );
      },
    );
  }

  Future<void> _deleteSpace(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete space?'),
        content: Text(
          'This will remove "${space.name}" from the selected store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await sl<DeleteSpace>()(space.id);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showSnackBar(context, failure.message, isError: true),
      (success) {
        _reloadLocations(context);
        Navigator.pop(context);
        _showSnackBar(
          context,
          success.message ?? 'Space deleted successfully.',
        );
      },
    );
  }

  void _reloadLocations(BuildContext context) {
    try {
      context.read<LocationBloc>().add(const LoadLocationsRequested());
    } catch (_) {
      // The sheet can be opened from places without LocationBloc in scope.
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<List<FuzzyOverridePlaylistOption>> _loadSpacePlaylistOptions() async {
    final response = await sl<PlaylistRemoteDataSource>().getPlaylists(
      page: 1,
      pageSize: 100,
      storeId: space.storeId,
    );
    return response.items
        .map(
          (playlist) => FuzzyOverridePlaylistOption(
            id: playlist.id,
            label: playlist.name,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _showMusicPolicyEditor(BuildContext context) async {
    List<FuzzyOverridePlaylistOption> playlists;
    try {
      playlists = await _loadSpacePlaylistOptions();
    } catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Failed to load playlists for music policy: $error',
        isError: true,
      );
      return;
    }
    if (!context.mounted) return;

    final request = await showModalBottomSheet<FuzzyOverrideProfileRequest>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuzzyOverrideEditorSheet(
        title: 'Space Music Policy',
        playlists: playlists,
        summary: space.fuzzyOverrideSummary,
        overrideLevel: space.fuzzyOverrideLevel,
      ),
    );

    if (request == null || !context.mounted) return;

    final result =
        await sl<CreateSpaceFuzzyOverrideProfile>()(space.id, request);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showSnackBar(context, failure.message, isError: true),
      (success) {
        _reloadLocations(context);
        _showSnackBar(
          context,
          success.message ?? 'Space music policy updated successfully.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SheetPalette.of(context);
    final router = GoRouter.of(context);
    final canManageSpace = _canManageSpace(context);
    final hubStatusLabel = space.hubBinding == null
        ? 'Hub pending'
        : space.hubBinding!.isSyncPending
            ? 'Hub sync pending'
            : 'Hub configured';

    return SafeArea(
      bottom: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: palette.border),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CAMS Space Settings',
                              style: GoogleFonts.poppins(
                                color: palette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage policies, provisioning, and companion controls for this space.',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: palette.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: palette.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SpaceContextCard(
                  palette: palette,
                  space: space,
                  hubStatusLabel: hubStatusLabel,
                ),
                const SizedBox(height: 16),
                _SectionLabel(
                  palette: palette,
                  label: 'SPACE TOOLS',
                ),
                const SizedBox(height: 8),
                _SectionCard(
                  palette: palette,
                  child: Column(
                    children: [
                      _NavTile(
                        icon: LucideIcons.music4,
                        iconColor: palette.accent,
                        label: 'Music policy',
                        subtitle:
                            'Tune BPM bands, thresholds, and allowed playlists for this space.',
                        trailing: SizedBox(
                          width: 96,
                          child: Text(
                            space.fuzzyOverrideSummary?.headline ??
                                space.fuzzyOverrideLevel?.displayName ??
                                'Inherited',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        palette: palette,
                        onTap: () => canManageSpace
                            ? _showMusicPolicyEditor(context)
                            : _showSnackBar(
                                context,
                                'Only managers can edit music policy.',
                                isError: true,
                              ),
                      ),
                      const SizedBox(height: 10),
                      _NavTile(
                        icon: LucideIcons.router,
                        iconColor: palette.accent,
                        label: 'IoT Hub & Wi-Fi',
                        subtitle:
                            'Provision the ESP32 over BLE and review the saved hub binding.',
                        trailing: SizedBox(
                          width: 120,
                          child: Text(
                            space.hubBinding == null
                                ? 'Not configured'
                                : space.hubBinding!.isSyncPending
                                    ? 'Sync pending'
                                    : space.hubBinding!.wifiSsid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              color: palette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        palette: palette,
                        onTap: () async {
                          LocationBloc? locationBloc;
                          try {
                            locationBloc = context.read<LocationBloc>();
                          } catch (_) {
                            locationBloc = null;
                          }
                          Navigator.pop(context);
                          final didMutate = await router.push<bool>(
                            buildSpaceHubLocation(
                              spaceId: space.id,
                              storeId: space.storeId,
                              spaceName: space.name,
                            ),
                          );
                          if (didMutate == true) {
                            locationBloc?.add(const LoadLocationsRequested());
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _NavTile(
                        icon: LucideIcons.calendar,
                        iconColor: palette.accent,
                        label: 'Space schedule',
                        subtitle:
                            'Control when this space follows automatic schedules.',
                        palette: palette,
                        onTap: () {
                          Navigator.pop(context);
                          router.push(_buildSpaceScheduleLocation(space));
                        },
                      ),
                      const SizedBox(height: 10),
                      _NavTile(
                        icon: LucideIcons.clock,
                        iconColor: palette.accent,
                        label: 'Recently played songs',
                        subtitle:
                            'Review what has been played recently in this space.',
                        palette: palette,
                        onTap: () =>
                            _comingSoon(context, 'Recently played songs'),
                      ),
                      const SizedBox(height: 10),
                      _NavTile(
                        icon: LucideIcons.ban,
                        iconColor: AppColors.error,
                        label: 'Blocked songs',
                        subtitle:
                            'Manage tracks that should never play in this space.',
                        palette: palette,
                        onTap: () => _comingSoon(context, 'Blocked songs'),
                      ),
                    ],
                  ),
                ),
                if (canManageSpace) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                    palette: palette,
                    label: 'SPACE MANAGEMENT',
                  ),
                  const SizedBox(height: 8),
                  _SectionCard(
                    palette: palette,
                    child: Column(
                      children: [
                        _NavTile(
                          icon: Icons.edit_rounded,
                          iconColor: palette.accent,
                          label: 'Edit space',
                          subtitle:
                              'Rename the space and update its description.',
                          palette: palette,
                          onTap: () => _editSpace(context),
                        ),
                        const SizedBox(height: 10),
                        _NavTile(
                          icon: space.status.isActive
                              ? LucideIcons.toggleRight
                              : LucideIcons.toggleLeft,
                          iconColor: space.status.isActive
                              ? AppColors.warning
                              : AppColors.success,
                          label: space.status.isActive
                              ? 'Set inactive'
                              : 'Set active',
                          subtitle: space.status.isActive
                              ? 'Pause this space without deleting it.'
                              : 'Bring this space back into active operation.',
                          palette: palette,
                          onTap: () => _toggleSpaceStatus(context),
                        ),
                        const SizedBox(height: 10),
                        _NavTile(
                          icon: LucideIcons.trash2,
                          iconColor: AppColors.error,
                          label: 'Delete space',
                          subtitle:
                              'Remove this space from the currently selected store.',
                          palette: palette,
                          onTap: () => _deleteSpace(context),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isPlaybackDevice) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                    palette: palette,
                    label: 'CAMS REMOTE',
                  ),
                  const SizedBox(height: 8),
                  _SectionCard(
                    palette: palette,
                    child: _NavTile(
                      icon: LucideIcons.smartphone,
                      iconColor: palette.accent,
                      label: 'CAMS Remote',
                      subtitle:
                          'Quick remote controls and companion tools for this space.',
                      trailing: Text(
                        'Enabled',
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      palette: palette,
                      onTap: () => _comingSoon(context, 'CAMS Remote'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
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

class _SpaceContextCard extends StatelessWidget {
  const _SpaceContextCard({
    required this.palette,
    required this.space,
    required this.hubStatusLabel,
  });

  final _SheetPalette palette;
  final LocationSpace space;
  final String hubStatusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.18 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.layoutTemplate,
              color: palette.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.name,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (space.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    space.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      palette: palette,
                      label: space.type.displayName,
                    ),
                    _InfoPill(
                      palette: palette,
                      label: space.status.displayName,
                    ),
                    _InfoPill(
                      palette: palette,
                      label: hubStatusLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.palette,
    required this.label,
  });

  final _SheetPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.child,
  });

  final _SheetPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.palette,
    required this.label,
  });

  final _SheetPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: palette.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.palette,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final _SheetPalette palette;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null) ...[
              Flexible(child: trailing!),
              const SizedBox(width: 6),
            ],
            Icon(
              LucideIcons.chevronRight,
              color: palette.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPalette {
  const _SheetPalette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  final bool isDark;
  final Color bg;
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  factory _SheetPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SheetPalette(
      isDark: isDark,
      bg: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      card: isDark ? AppColors.surfaceDark : Colors.white,
      panel:
          isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundPrimary,
      border: isDark ? AppColors.borderDarkLight : AppColors.borderLight,
      textPrimary: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      textMuted: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
      accent: isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
    );
  }
}
