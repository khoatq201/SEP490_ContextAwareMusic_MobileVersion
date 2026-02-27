import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsUserPage extends StatelessWidget {
  const SettingsUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _UserPalette.fromBrightness(Theme.of(context).brightness);

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
            'User',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 28,
            ),
          ),
          titleSpacing: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            final displayName = _displayName(user?.fullName, user?.username);
            final email = user?.email ?? '-';

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: [
                _UserInfoCard(
                  palette: palette,
                  rows: [
                    _UserInfoRow(label: 'Name', value: displayName),
                    _UserInfoRow(label: 'Email', value: email),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'These can be changed from the web interface.',
                    style: GoogleFonts.inter(
                      color: palette.textSecondary,
                      fontSize: 16,
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
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _confirmLogout(context, palette),
                    child: Text(
                      'Log out',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
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
                        fontSize: 20,
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

class _UserInfoCard extends StatelessWidget {
  final List<_UserInfoRow> rows;
  final _UserPalette palette;

  const _UserInfoCard({required this.rows, required this.palette});

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

class _UserInfoRow {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});
}

class _UserPalette {
  final Color background;
  final Color card;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryButton;
  final Color primaryButtonText;

  const _UserPalette({
    required this.background,
    required this.card,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryButton,
    required this.primaryButtonText,
  });

  factory _UserPalette.fromBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _UserPalette(
        background: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        divider: AppColors.borderDarkLight,
        textPrimary: AppColors.textDarkPrimary,
        textSecondary: AppColors.textDarkSecondary,
        primaryButton: AppColors.primaryCyan,
        primaryButtonText: AppColors.backgroundDarkPrimary,
      );
    }

    return const _UserPalette(
      background: AppColors.backgroundSecondary,
      card: Colors.white,
      divider: AppColors.divider,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textTertiary,
      primaryButton: Colors.black,
      primaryButtonText: Colors.white,
    );
  }
}
