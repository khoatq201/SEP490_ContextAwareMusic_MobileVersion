import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/usecases/change_password.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsUserPage extends StatelessWidget {
  const SettingsUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _UserPalette.fromContext(context);
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomPadding = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 28,
    );

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
              return CamsSkeletonList(
                itemCount: 4,
                showLeading: false,
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
              );
            }

            final user = authState.user;
            final displayName = _displayName(user?.fullName, user?.username);
            final email = user?.email ?? '-';
            final role = user?.role.trim().isEmpty == true || user == null
                ? '-'
                : user.role;
            final session = context.watch<SessionCubit>().state;
            final canChangePassword = !session.isPlaybackDevice &&
                (user?.isBrandManager == true || user?.isStoreManager == true);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
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
                if (canChangePassword) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Security', palette: palette),
                  const SizedBox(height: 10),
                  _ChangePasswordCard(
                    palette: palette,
                    onTap: () => _showChangePasswordSheet(context, palette),
                  ),
                ],
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
                // const SizedBox(height: 18),
                // Center(
                //   child: TextButton(
                //     onPressed: () => _showDeleteAccountHint(context),
                //     child: Text(
                //       'Delete my user account',
                //       style: GoogleFonts.inter(
                //         color: palette.textSecondary,
                //         fontSize: 13,
                //         fontWeight: FontWeight.w700,
                //         decoration: TextDecoration.underline,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, _UserPalette palette) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: palette.card,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ChangePasswordSheet(palette: palette),
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

class _ChangePasswordCard extends StatelessWidget {
  const _ChangePasswordCard({
    required this.palette,
    required this.onTap,
  });

  final _UserPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.keyRound,
                  color: palette.primaryButton,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change password',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update the password for this manager account.',
                      style: GoogleFonts.inter(
                        color: palette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                color: palette.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.palette});

  final _UserPalette palette;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await sl<ChangePassword>()(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 18, 20, safeBottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Change password',
                        style: GoogleFonts.poppins(
                          color: palette.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Use a password with at least 6 characters.',
                  style: GoogleFonts.inter(
                    color: palette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                _PasswordField(
                  controller: _currentPasswordController,
                  label: 'Current password',
                  palette: palette,
                  obscureText: _hideCurrentPassword,
                  onToggleVisibility: () => setState(
                    () => _hideCurrentPassword = !_hideCurrentPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _newPasswordController,
                  label: 'New password',
                  palette: palette,
                  obscureText: _hideNewPassword,
                  onToggleVisibility: () => setState(
                    () => _hideNewPassword = !_hideNewPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a new password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  palette: palette,
                  obscureText: _hideConfirmPassword,
                  onToggleVisibility: () => setState(
                    () => _hideConfirmPassword = !_hideConfirmPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your new password.';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.errorBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.errorBorder),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: palette.errorText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryButton,
                      foregroundColor: palette.primaryButtonText,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.primaryButtonText,
                            ),
                          )
                        : Text(
                            'Save password',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.palette,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final _UserPalette palette;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(
        color: palette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: palette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          LucideIcons.lock,
          color: palette.textSecondary,
          size: 18,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
            color: palette.textSecondary,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: palette.fieldBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primaryButton, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.errorText),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.errorText, width: 1.4),
        ),
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
  final Color fieldBackground;
  final Color errorBackground;
  final Color errorBorder;
  final Color errorText;

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
    required this.fieldBackground,
    required this.errorBackground,
    required this.errorBorder,
    required this.errorText,
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
      fieldBackground: tokens.bgElevated,
      errorBackground: tokens.alertErrorBg,
      errorBorder: tokens.error.withValues(alpha: 0.4),
      errorText: tokens.error,
    );
  }
}
