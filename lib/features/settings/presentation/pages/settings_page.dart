import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.fromBrightness(Theme.of(context).brightness);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
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
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new, color: palette.textPrimary),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 28,
            ),
          ),
          titleSpacing: 0,
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

            if (state.status == SettingsStatus.error || state.snapshot == null) {
              return _SettingsErrorView(
                message: state.errorMessage ?? 'Cannot load settings right now.',
                onRetry: () => context.read<SettingsCubit>().load(),
                palette: palette,
              );
            }

            final authState = context.watch<AuthBloc>().state;
            final user = authState.user;
            final displayName = _getDisplayName(user?.fullName, user?.username);
            final snapshot = state.snapshot!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: [
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'User',
                      trailingText: displayName,
                      palette: palette,
                      onTap: () => context.push('/settings/user'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: 'COMPANY', palette: palette),
                const SizedBox(height: 8),
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsTile(
                      icon: Icons.storefront_outlined,
                      title: snapshot.companyName,
                      palette: palette,
                      onTap: () => context.push('/settings/company'),
                    ),
                    _Divider(palette: palette),
                    _SettingsTile(
                      icon: Icons.explicit_outlined,
                      title: 'Explicit music',
                      trailingText: snapshot.explicitMusicLabel,
                      palette: palette,
                      onTap: () => context.push('/settings/company'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: 'APP', palette: palette),
                const SizedBox(height: 8),
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsTile(
                      icon: Icons.tune,
                      title: 'Preferences',
                      palette: palette,
                      onTap: () => _showComingSoon(context, 'Preferences'),
                    ),
                    _Divider(palette: palette),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      palette: palette,
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsGroup(
                  palette: palette,
                  children: [
                    _SettingsTile(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Buy Soundtrack Player',
                      palette: palette,
                      showExternalIcon: true,
                      showChevron: false,
                      onTap: () => _showComingSoon(context, 'Buy Soundtrack Player'),
                    ),
                    _Divider(palette: palette),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      palette: palette,
                      showExternalIcon: true,
                      showChevron: false,
                      onTap: () => _showComingSoon(context, 'Help & support'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _getDisplayName(String? fullName, String? username) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'User';
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CAMS Store Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: 'CAMS Music Platform',
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final _SettingsPalette palette;

  const _SectionLabel({required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: palette.sectionLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final _SettingsPalette palette;

  const _SettingsGroup({required this.children, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final _SettingsPalette palette;

  const _Divider({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 52),
      height: 1,
      color: palette.divider,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final bool showChevron;
  final bool showExternalIcon;
  final _SettingsPalette palette;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.palette,
    required this.onTap,
    this.trailingText,
    this.showChevron = true,
    this.showExternalIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = showExternalIcon
        ? Icons.open_in_new_rounded
        : showChevron
            ? Icons.chevron_right_rounded
            : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: palette.iconBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: palette.iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: GoogleFonts.inter(
                  color: palette.textSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (iconData != null)
              Icon(iconData, color: palette.trailingIcon, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final _SettingsPalette palette;

  const _SettingsErrorView({
    required this.message,
    required this.onRetry,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.trailingIcon, size: 30),
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
  final Color background;
  final Color card;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color sectionLabel;
  final Color iconBackground;
  final Color iconColor;
  final Color trailingIcon;

  const _SettingsPalette({
    required this.background,
    required this.card,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.sectionLabel,
    required this.iconBackground,
    required this.iconColor,
    required this.trailingIcon,
  });

  factory _SettingsPalette.fromBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _SettingsPalette(
        background: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        divider: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textSecondary: AppColors.textDarkSecondary,
        sectionLabel: AppColors.textDarkTertiary,
        iconBackground: AppColors.surfaceDarkElevated,
        iconColor: AppColors.primaryCyan,
        trailingIcon: AppColors.textDarkTertiary,
      );
    }

    return _SettingsPalette(
      background: AppColors.backgroundSecondary,
      card: Colors.white,
      divider: AppColors.divider,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textTertiary,
      sectionLabel: AppColors.textTertiary,
      iconBackground: AppColors.primaryOrange.withOpacity(0.14),
      iconColor: AppColors.primaryOrange,
      trailingIcon: AppColors.textTertiary,
    );
  }
}
