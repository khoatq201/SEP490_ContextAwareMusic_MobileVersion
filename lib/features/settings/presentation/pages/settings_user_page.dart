import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsUserPage extends StatelessWidget {
  const SettingsUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _UserPalette.fromContext(context);

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
            'Account',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          titleSpacing: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState.status == AuthStatus.loading) {
              return const CamsSkeletonList(
                itemCount: 4,
                showLeading: false,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
              );
            }

            final user = authState.user;
            final displayName = _displayName(user?.fullName, user?.username);
            final email = user?.email ?? '-';
            final role = user?.role.trim().isEmpty == true || user == null
                ? '-'
                : user.role;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _AccountHeaderCard(
                  palette: palette,
                  displayName: displayName,
                  email: email,
                  role: role,
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Profile', palette: palette),
                const SizedBox(height: 10),
                _UserInfoCard(
                  palette: palette,
                  rows: [
                    _UserInfoRow(label: 'Name', value: displayName),
                    _UserInfoRow(label: 'Email', value: email),
                    _UserInfoRow(label: 'Role', value: role),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'These can be changed from the web interface.',
                    style: GoogleFonts.inter(
                      color: palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryButton,
                      foregroundColor: palette.primaryButtonText,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _confirmLogout(context, palette),
                    child: Text(
                      'Log out',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => _showDeleteAccountHint(context),
                    child: Text(
                      'Delete my user account',
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _displayName(String? fullName, String? username) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'User';
  }

  void _confirmLogout(BuildContext context, _UserPalette palette) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text(
            'Log out',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Do you want to log out of your account?',
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

  void _showDeleteAccountHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please contact support to remove your account.'),
      ),
    );
  }
}

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({
    required this.palette,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final _UserPalette palette;
  final String displayName;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.user,
              color: palette.primaryButton,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      color: palette.primaryButton,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});

  final String label;
  final _UserPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: palette.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final List<_UserInfoRow> rows;
  final _UserPalette palette;

  const _UserInfoCard({required this.rows, required this.palette});

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
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
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

class _UserInfoRow {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});
}

class _UserPalette {
  final Color background;
  final Color card;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentSoft;
  final Color shadow;
  final Color primaryButton;
  final Color primaryButtonText;

  const _UserPalette({
    required this.background,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentSoft,
    required this.shadow,
    required this.primaryButton,
    required this.primaryButtonText,
  });

  factory _UserPalette.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.camsTokens;
    return _UserPalette(
      background: tokens.bgBase,
      card: tokens.bgContainer,
      border: tokens.borderSecondary,
      divider: tokens.divider,
      textPrimary: tokens.textPrimary,
      textSecondary: tokens.textSecondary,
      accentSoft: tokens.brandPrimarySoft,
      shadow: tokens.shadow,
      primaryButton: theme.colorScheme.primary,
      primaryButtonText: tokens.textOnAccent,
    );
  }
}
