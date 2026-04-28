import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cams/domain/usecases/pairing_usecases.dart';
import '../../../music_policy/data/datasources/fuzzy_music_profile_remote_datasource.dart';
import '../../../music_policy/domain/entities/fuzzy_music_profile.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.fromBrightness(
      Theme.of(context).brightness,
    );
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomPadding = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final isPlayback = context.read<SessionCubit>().state.isPlaybackDevice;
        if (!isPlayback && state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              Text(
                'CAMS workspace, appearance, and access',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.status == SettingsStatus.initial ||
                state.status == SettingsStatus.loading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }

            if (state.status == SettingsStatus.error ||
                state.snapshot == null) {
              return _SettingsErrorView(
                message:
                    state.errorMessage ?? 'Cannot load settings right now.',
                onRetry: () => context.read<SettingsCubit>().load(),
                palette: palette,
              );
            }

            final session = context.watch<SessionCubit>().state;
            final authState = context.watch<AuthBloc>().state;
            final themeProvider = context.watch<ThemeProvider>();
            final snapshot = state.snapshot!;
            final isPlayback = session.isPlaybackDevice;
            final user = authState.user;
            final displayName = isPlayback
                ? (session.currentSpace?.name ?? 'Playback Device')
                : _displayName(user);

            return ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
              children: [
                _SettingsHeroCard(
                  palette: palette,
                  title: displayName,
                  subtitle: isPlayback
                      ? 'Locked to one playback space'
                      : user?.email ?? 'Remote music control account',
                  modeLabel: session.appMode.label,
                  roleLabel: session.currentRole.label,
                  storeName: session.currentStore?.name,
                  spaceName: session.currentSpace?.name,
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Workspace', palette: palette),
                const SizedBox(height: 10),
                _InfoPanel(
                  palette: palette,
                  children: [
                    _InfoDivider(palette: palette),
                    _InfoRow(
                      icon: LucideIcons.store,
                      label: 'Current store',
                      value: session.currentStore?.name ?? 'No store selected',
                      palette: palette,
                    ),
                    _InfoDivider(palette: palette),
                    _InfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Current space',
                      value: session.currentSpace?.name ?? 'No space targeted',
                      palette: palette,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Appearance', palette: palette),
                const SizedBox(height: 10),
                _ThemeModeCard(
                  palette: palette,
                  themeMode: themeProvider.themeMode,
                  onChanged: themeProvider.setThemeMode,
                ),
                if (!isPlayback) ...[
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'Playback', palette: palette),
                  const SizedBox(height: 10),
                  _ManagerPlaybackPreferenceCard(
                    palette: palette,
                    enabled: session.managerLocalPlaybackEnabled,
                    onChanged: (enabled) => context
                        .read<SessionCubit>()
                        .setManagerLocalPlaybackEnabled(enabled),
                  ),
                  if (session.currentStore != null) ...[
                    const SizedBox(height: 12),
                    _AutoVolumeSettingsCard(
                      palette: palette,
                      storeId: session.currentStore!.id,
                      spaceId: session.currentSpace?.id,
                      useStoreSessionScope:
                          session.currentRole != UserRole.brandManager,
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                _SectionTitle(title: 'Quick Access', palette: palette),
                const SizedBox(height: 10),
                _ActionPanel(
                  palette: palette,
                  children: _buildQuickAccess(
                    context: context,
                    isPlayback: isPlayback,
                    user: user,
                    companySummary:
                        '${snapshot.businessType} · ${snapshot.planName}',
                    palette: palette,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Music Policy', palette: palette),
                const SizedBox(height: 10),
                _PolicyPanel(
                  palette: palette,
                  explicitMusicLabel: snapshot.explicitMusicLabel,
                  blockingSongsLabel: snapshot.blockingSongsLabel,
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Session', palette: palette),
                const SizedBox(height: 10),
                _DangerPanel(
                  palette: palette,
                  title: isPlayback ? 'Unpair device' : 'Log out',
                  subtitle: isPlayback
                      ? 'Remove this playback session and return to the pairing screen.'
                      : 'End this manager session on the current device.',
                  icon: isPlayback ? LucideIcons.unlink : LucideIcons.logOut,
                  onTap: () => isPlayback
                      ? _confirmUnpairPlaybackDevice(context, palette)
                      : _confirmLogout(context, palette),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildQuickAccess({
    required BuildContext context,
    required bool isPlayback,
    required User? user,
    required String companySummary,
    required _SettingsPalette palette,
  }) {
    final children = <Widget>[];

    if (!isPlayback) {
      children.add(
        _ActionTile(
          icon: LucideIcons.user,
          title: 'Account',
          subtitle: user?.email ?? 'Profile and sign-out options',
          palette: palette,
          onTap: () => context.push('/settings/user'),
        ),
      );
      children.add(_InfoDivider(palette: palette));
      children.add(
        _ActionTile(
          icon: LucideIcons.briefcase,
          title: 'Organization',
          subtitle: companySummary,
          palette: palette,
          onTap: () => context.push('/settings/company'),
        ),
      );
      children.add(_InfoDivider(palette: palette));
    }

    children.add(
      _ActionTile(
        icon: LucideIcons.info,
        title: 'About CAMS',
        subtitle: 'Version, legal, and product details',
        palette: palette,
        onTap: () => _showAbout(context),
      ),
    );

    return children;
  }

  static String _displayName(User? user) {
    final fullName = user?.fullName;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final username = user?.username;
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'Manager';
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CAMS Store Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Connected Adaptive Music System',
    );
  }

  void _confirmLogout(BuildContext context, _SettingsPalette palette) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text(
            'Log out',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Do you want to sign out of this manager session?',
            style: GoogleFonts.inter(color: palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  void _confirmUnpairPlaybackDevice(
    BuildContext context,
    _SettingsPalette palette,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unpair this device?'),
          content: const Text(
            'This will revoke the current playback-device session and take you back to the pairing screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final session = context.read<SessionCubit>().state;
                final spaceId = session.currentSpace?.id;
                if (spaceId == null) {
                  return;
                }

                final result = await sl<UnpairPlaybackDevice>()(spaceId);
                if (!context.mounted) return;

                result.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: palette.dangerForeground,
                      ),
                    );
                  },
                  (_) async {
                    await sl<LocalStorageService>().clearDeviceSession();
                    if (!context.mounted) return;
                    context.read<SessionCubit>().reset();
                    context.go('/pair-device');
                  },
                );
              },
              child: const Text('Unpair'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.modeLabel,
    required this.roleLabel,
    required this.storeName,
    required this.spaceName,
  });

  final _SettingsPalette palette;
  final String title;
  final String subtitle;
  final String modeLabel;
  final String roleLabel;
  final String? storeName;
  final String? spaceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.accent.withAlpha(24),
            palette.card,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: modeLabel,
                palette: palette,
                icon: LucideIcons.radio,
              ),
              _StatusPill(
                label: roleLabel,
                palette: palette,
                icon: LucideIcons.shieldCheck,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ContextBlock(
                  label: 'Store',
                  value: storeName ?? 'Not selected',
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContextBlock(
                  label: 'Space',
                  value: spaceName ?? 'Not selected',
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextBlock extends StatelessWidget {
  const _ContextBlock({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.palette,
    required this.icon,
  });

  final String label;
  final _SettingsPalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.accent.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: palette.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.palette});

  final String title;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: palette.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.palette,
    required this.children,
  });

  final _SettingsPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: palette.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.palette,
    required this.children,
  });

  final _SettingsPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _SettingsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
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
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.palette,
    required this.themeMode,
    required this.onChanged,
  });

  final _SettingsPalette palette;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.panel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  themeMode == ThemeMode.dark
                      ? LucideIcons.moonStar
                      : themeMode == ThemeMode.system
                          ? LucideIcons.monitorSmartphone
                          : LucideIcons.sun,
                  color: palette.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App theme',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Apply light, dark, or follow the device theme across the whole app.',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ThemeModeChip(
                label: 'Light',
                icon: LucideIcons.sun,
                selected: themeMode == ThemeMode.light,
                palette: palette,
                onTap: () => onChanged(ThemeMode.light),
              ),
              _ThemeModeChip(
                label: 'Dark',
                icon: LucideIcons.moonStar,
                selected: themeMode == ThemeMode.dark,
                palette: palette,
                onTap: () => onChanged(ThemeMode.dark),
              ),
              _ThemeModeChip(
                label: 'System',
                icon: LucideIcons.monitorSmartphone,
                selected: themeMode == ThemeMode.system,
                palette: palette,
                onTap: () => onChanged(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _SettingsPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? palette.accent.withAlpha(20) : palette.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? palette.accent : palette.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? palette.accent : palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerPlaybackPreferenceCard extends StatelessWidget {
  const _ManagerPlaybackPreferenceCard({
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final _SettingsPalette palette;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              enabled ? LucideIcons.volume2 : LucideIcons.volumeX,
              size: 18,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Play CAMS audio on this manager device',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  enabled
                      ? 'This phone will play the live CAMS stream for the selected space.'
                      : 'This phone will only monitor metadata and transport state without outputting audio.',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: palette.accent,
            activeTrackColor: palette.accent.withAlpha(72),
          ),
        ],
      ),
    );
  }
}

class _AutoVolumeSettingsCard extends StatefulWidget {
  const _AutoVolumeSettingsCard({
    required this.palette,
    required this.storeId,
    required this.spaceId,
    required this.useStoreSessionScope,
  });

  final _SettingsPalette palette;
  final String storeId;
  final String? spaceId;
  final bool useStoreSessionScope;

  @override
  State<_AutoVolumeSettingsCard> createState() =>
      _AutoVolumeSettingsCardState();
}

class _AutoVolumeSettingsCardState extends State<_AutoVolumeSettingsCard> {
  FuzzyMusicProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _AutoVolumeSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId ||
        oldWidget.spaceId != widget.spaceId ||
        oldWidget.useStoreSessionScope != widget.useStoreSessionScope) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = sl<FuzzyMusicProfileRemoteDataSource>();
      FuzzyMusicProfile profile;
      final spaceId = widget.spaceId?.trim();
      if (spaceId != null && spaceId.isNotEmpty) {
        try {
          profile = await dataSource.getSpaceProfile(spaceId);
        } catch (_) {
          profile = widget.useStoreSessionScope
              ? await dataSource.getCurrentStoreProfile()
              : await dataSource.getStoreProfile(widget.storeId);
        }
      } else {
        profile = widget.useStoreSessionScope
            ? await dataSource.getCurrentStoreProfile()
            : await dataSource.getStoreProfile(widget.storeId);
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _setAutoVolume(bool enabled) async {
    final current = _profile;
    if (current == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _profile = current.copyWith(autoVolumeEnabled: enabled);
    });

    try {
      final dataSource = sl<FuzzyMusicProfileRemoteDataSource>();
      final spaceId = widget.spaceId?.trim();
      if (spaceId != null && spaceId.isNotEmpty) {
        await dataSource.setSpaceAutoVolume(
          spaceId: spaceId,
          enabled: enabled,
        );
      } else if (widget.useStoreSessionScope) {
        await dataSource.setCurrentStoreAutoVolume(enabled: enabled);
      } else {
        await dataSource.setStoreAutoVolume(
          storeId: widget.storeId,
          enabled: enabled,
        );
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = current;
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final profile = _profile;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.activity,
              size: 18,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto Volume',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (_isLoading)
                  Text(
                    'Loading music profile...',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (profile == null)
                  _AutoVolumeErrorRow(
                    palette: palette,
                    message: 'Music profile unavailable.',
                    onRetry: _loadProfile,
                  )
                else ...[
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AutoVolumeMetric(
                        label: 'Range',
                        value: profile.autoVolumeRangeLabel,
                        palette: palette,
                      ),
                      _AutoVolumeMetric(
                        label: 'Quiet/Mod/Loud',
                        value: profile.autoVolumeStepsLabel,
                        palette: palette,
                      ),
                      _AutoVolumeMetric(
                        label: 'Deadband',
                        value: '${profile.autoVolumeDeadbandPercent}%',
                        palette: palette,
                      ),
                    ],
                  ),
                ],
                if (_errorMessage != null && profile != null) ...[
                  const SizedBox(height: 10),
                  _AutoVolumeErrorRow(
                    palette: palette,
                    message: 'Update failed.',
                    onRetry: _loadProfile,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: profile?.autoVolumeEnabled ?? false,
              onChanged: profile == null || _isSaving ? null : _setAutoVolume,
              activeThumbColor: palette.accent,
              activeTrackColor: palette.accent.withAlpha(72),
            ),
        ],
      ),
    );
  }
}

class _AutoVolumeMetric extends StatelessWidget {
  const _AutoVolumeMetric({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          color: palette.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AutoVolumeErrorRow extends StatelessWidget {
  const _AutoVolumeErrorRow({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final _SettingsPalette palette;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: palette.dangerForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _PolicyPanel extends StatelessWidget {
  const _PolicyPanel({
    required this.palette,
    required this.explicitMusicLabel,
    required this.blockingSongsLabel,
  });

  final _SettingsPalette palette;
  final String explicitMusicLabel;
  final String blockingSongsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PolicyMetric(
              label: 'Explicit music',
              value: explicitMusicLabel,
              palette: palette,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PolicyMetric(
              label: 'Blocking songs',
              value: blockingSongsLabel,
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyMetric extends StatelessWidget {
  const _PolicyMetric({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    final normalized = value.toLowerCase();
    final isAllowed = normalized.contains('allow');
    final accentColor = isAllowed ? palette.success : palette.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerPanel extends StatelessWidget {
  const _DangerPanel({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final _SettingsPalette palette;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.dangerBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.dangerBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: palette.dangerForeground,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider({required this.palette});

  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: palette.border,
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({
    required this.message,
    required this.onRetry,
    required this.palette,
  });

  final String message;
  final VoidCallback onRetry;
  final _SettingsPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, color: palette.warning, size: 30),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: palette.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.background,
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.dangerBackground,
    required this.dangerBorder,
    required this.dangerForeground,
  });

  final Color background;
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color dangerBackground;
  final Color dangerBorder;
  final Color dangerForeground;

  factory _SettingsPalette.fromBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _SettingsPalette(
        background: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        panel: AppColors.surfaceDarkElevated,
        border: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textSecondary: AppColors.textDarkSecondary,
        textMuted: AppColors.textDarkTertiary,
        accent: AppColors.primaryCyan,
        shadow: AppColors.shadowDark,
        success: AppColors.successNeon,
        warning: AppColors.warningNeon,
        dangerBackground: Color(0x33FF1744),
        dangerBorder: Color(0x66FF1744),
        dangerForeground: AppColors.errorNeon,
      );
    }

    return const _SettingsPalette(
      background: AppColors.backgroundPrimary,
      card: AppColors.surface,
      panel: AppColors.backgroundSecondary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      shadow: AppColors.shadow,
      success: AppColors.successDark,
      warning: AppColors.warningDark,
      dangerBackground: AppColors.errorPale,
      dangerBorder: AppColors.errorLight,
      dangerForeground: AppColors.errorDark,
    );
  }
}
