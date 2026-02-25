import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsCompanyPage extends StatelessWidget {
  const SettingsCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _CompanyPalette.fromBrightness(Theme.of(context).brightness);

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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(Icons.arrow_back_ios_new, color: palette.textPrimary),
          ),
          title: Text(
            'Company',
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
              return Center(
                child: Text(
                  state.errorMessage ?? 'Cannot load company data.',
                  style: GoogleFonts.inter(color: palette.textSecondary),
                ),
              );
            }

            final snapshot = state.snapshot!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: [
                _InfoCard(
                  palette: palette,
                  rows: [
                    _InfoRow(label: 'Name', value: snapshot.companyName),
                    _InfoRow(label: 'Business type', value: snapshot.businessType),
                    _InfoRow(label: 'Plan', value: snapshot.planName),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'MUSIC CONTROL',
                    style: GoogleFonts.inter(
                      color: palette.sectionLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _ControlCard(
                  palette: palette,
                  rows: [
                    _ControlRow(
                      icon: Icons.explicit_outlined,
                      title: 'Explicit music',
                      value: snapshot.explicitMusicLabel,
                    ),
                    _ControlRow(
                      icon: Icons.block,
                      title: 'Blocking songs',
                      value: snapshot.blockingSongsLabel,
                    ),
                  ],
                  onPressed: (title) => _showControlHint(context, title),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showControlHint(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title settings are managed by your admin panel.')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  final _CompanyPalette palette;

  const _InfoCard({required this.rows, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 14),
                height: 1,
                color: palette.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final List<_ControlRow> rows;
  final _CompanyPalette palette;
  final ValueChanged<String> onPressed;

  const _ControlCard({
    required this.rows,
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            InkWell(
              onTap: () => onPressed(rows[i].title),
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
                      child: Icon(rows[i].icon, color: palette.iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i].title,
                        style: GoogleFonts.inter(
                          color: palette.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      rows[i].value,
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.trailingIcon,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (i < rows.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 52),
                height: 1,
                color: palette.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}

class _ControlRow {
  final IconData icon;
  final String title;
  final String value;

  const _ControlRow({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _CompanyPalette {
  final Color background;
  final Color card;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color sectionLabel;
  final Color iconBackground;
  final Color iconColor;
  final Color trailingIcon;

  const _CompanyPalette({
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

  factory _CompanyPalette.fromBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _CompanyPalette(
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

    return _CompanyPalette(
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
