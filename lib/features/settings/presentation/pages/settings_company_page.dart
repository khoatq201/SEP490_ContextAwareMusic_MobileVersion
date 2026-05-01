import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsCompanyPage extends StatelessWidget {
  const SettingsCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _CompanyPalette.fromContext(context);

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
            icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
          ),
          title: Text(
            'Company',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          titleSpacing: 0,
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.status == SettingsStatus.initial ||
                state.status == SettingsStatus.loading) {
              return const CamsSkeletonList(
                itemCount: 5,
                showLeading: false,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
              );
            }

            if (state.status == SettingsStatus.error ||
                state.snapshot == null) {
              return AppErrorView(
                title: 'Company data unavailable',
                message: state.errorMessage ?? 'Cannot load company data.',
                onRetry: () => context.read<SettingsCubit>().load(),
              );
            }

            final snapshot = state.snapshot!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _SectionLabel(label: 'Organization', palette: palette),
                const SizedBox(height: 10),
                _InfoCard(
                  palette: palette,
                  rows: [
                    _InfoRow(label: 'Name', value: snapshot.companyName),
                    _InfoRow(
                        label: 'Business type', value: snapshot.businessType),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Subscription & tokens', palette: palette),
                const SizedBox(height: 10),
                _InfoCard(
                  palette: palette,
                  rows: [
                    _InfoRow(
                      label: 'Subscription',
                      value: snapshot.subscriptionLabel,
                    ),
                    if (snapshot.subscriptionId?.trim().isNotEmpty == true)
                      _InfoRow(
                        label: 'Subscription ID',
                        value: _shortId(snapshot.subscriptionId!),
                      ),
                    _InfoRow(
                      label: 'Token balance',
                      value: snapshot.tokenBalanceLabel,
                      valueColor: snapshot.walletLocked
                          ? palette.danger
                          : palette.success,
                    ),
                    if (snapshot.walletLocked)
                      _InfoRow(
                        label: 'Wallet status',
                        value: 'Locked',
                        valueColor: palette.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Music control', palette: palette),
                const SizedBox(height: 10),
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
      SnackBar(
          content: Text('$title settings are managed by your admin panel.')),
    );
  }

  String _shortId(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 8) return trimmed;
    return trimmed.substring(0, 8);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});

  final String label;
  final _CompanyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: palette.sectionLabel,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
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
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        color: rows[i].valueColor ?? palette.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            InkWell(
              onTap: () => onPressed(rows[i].title),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: palette.iconBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(rows[i].icon,
                          color: palette.iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i].title,
                        style: GoogleFonts.inter(
                          color: palette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      rows[i].value,
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
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
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color sectionLabel;
  final Color iconBackground;
  final Color iconColor;
  final Color trailingIcon;
  final Color success;
  final Color warning;
  final Color danger;

  const _CompanyPalette({
    required this.background,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.sectionLabel,
    required this.iconBackground,
    required this.iconColor,
    required this.trailingIcon,
    required this.success,
    required this.warning,
    required this.danger,
  });

  factory _CompanyPalette.fromContext(BuildContext context) {
    final tokens = context.camsTokens;
    return _CompanyPalette(
      background: tokens.bgBase,
      card: tokens.bgContainer,
      border: tokens.borderSecondary,
      divider: tokens.divider,
      textPrimary: tokens.textPrimary,
      textSecondary: tokens.textSecondary,
      sectionLabel: tokens.textTertiary,
      iconBackground: tokens.brandPrimarySoft,
      iconColor: tokens.brandPrimary,
      trailingIcon: tokens.textTertiary,
      success: tokens.success,
      warning: tokens.warning,
      danger: tokens.error,
    );
  }
}
