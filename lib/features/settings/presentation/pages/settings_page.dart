import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsPage — màn hình Cài đặt (standalone, đè lên Bottom Nav Bar)
// ─────────────────────────────────────────────────────────────────────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDarkPrimary
            : AppColors.backgroundPrimary,
        appBar: AppBar(
          title: Text(
            'Cài đặt',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: isDark
              ? AppColors.backgroundDarkPrimary
              : AppColors.backgroundPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            final displayName =
                user?.fullName ?? user?.username ?? 'Người dùng';
            final email = user?.email ?? '';
            final words = displayName.trim().split(' ');
            final initials = words.length >= 2
                ? '${words.first[0]}${words.last[0]}'
                : displayName.isNotEmpty
                    ? displayName[0]
                    : 'U';

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Nhóm: TÀI KHOẢN ──────────────────────────────────────
                _SectionHeader(label: 'TÀI KHOẢN', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    // Profile row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppColors.primaryOrange.withOpacity(0.15),
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? Text(
                                    initials.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primaryOrange,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDarkPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.06)),
                    // Chỉnh sửa hồ sơ
                    ListTile(
                      leading: const Icon(Icons.person_outline,
                          color: AppColors.primaryOrange),
                      title: Text('Chỉnh sửa hồ sơ', style: _tileStyle(isDark)),
                      trailing: Icon(Icons.chevron_right,
                          size: 20,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary),
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Nhóm: HIỂN THỊ & GIAO DIỆN ───────────────────────────
                _SectionHeader(label: 'HIỂN THỊ & GIAO DIỆN', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    // Dark Mode toggle
                    ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: AppColors.primaryOrange,
                      ),
                      title: Text('Chế độ Tối (Dark Mode)',
                          style: _tileStyle(isDark)),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: AppColors.primaryOrange,
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.06)),
                    // Ngôn ngữ
                    ListTile(
                      leading: const Icon(Icons.language,
                          color: AppColors.secondaryTeal),
                      title: Text('Ngôn ngữ', style: _tileStyle(isDark)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tiếng Việt',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 20,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textSecondary),
                        ],
                      ),
                      onTap: () {
                        /* TODO: language picker */
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Nhóm: HỆ THỐNG ───────────────────────────────────────
                _SectionHeader(label: 'HỆ THỐNG', isDark: isDark),
                const SizedBox(height: 8),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(
                        'Đăng xuất',
                        style: _tileStyle(isDark).copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _confirmLogout(context, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TextStyle _tileStyle(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      );

  void _confirmLogout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.backgroundDarkSecondary : Colors.white,
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất không?',
          style: GoogleFonts.inter(
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Huỷ',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader — grey uppercase label above each group
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SettingsCard — rounded card container for a group of ListTiles
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkSecondary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}
