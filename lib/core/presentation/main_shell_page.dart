import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';
import '../player/player_bloc.dart';
import '../player/player_state.dart' as ps;
import '../player/widgets/mini_player_widget.dart';

/// The main shell page that wraps the 5-tab bottom navigation.
/// Rendered by ShellRoute inside go_router so that each tab branch
/// keeps its own navigation stack.
class MainShellPage extends StatelessWidget {
  /// The current child widget provided by go_router's ShellRoute.
  final Widget child;

  const MainShellPage({super.key, required this.child});

  // Maps each tab index to its root route path.
  static const List<String> _tabRoutes = [
    '/home',
    '/search',
    '/now-playing',
    '/library',
    '/locations',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabRoutes.length; i++) {
      if (location.startsWith(_tabRoutes[i])) return i;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Bottom navigation bar ──────────────────────────────────────────
    final bottomNav = Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                onTap: () => _onTap(context, 0),
                activeColor: colorScheme.primary,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Search',
                onTap: () => _onTap(context, 1),
                activeColor: colorScheme.primary,
              ),
              // Centre "Now Playing" tab – visually prominent
              BlocBuilder<PlayerBloc, ps.PlayerState>(
                builder: (context, playerState) => _NavItemCenter(
                  index: 2,
                  currentIndex: currentIndex,
                  isPlaying: playerState.isPlaying,
                  hasTrack: playerState.hasTrack,
                  onTap: () => _onTap(context, 2),
                  activeColor: colorScheme.primary,
                ),
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                icon: Icons.library_music_outlined,
                activeIcon: Icons.library_music,
                label: 'Library',
                onTap: () => _onTap(context, 3),
                activeColor: colorScheme.primary,
              ),
              _NavItem(
                index: 4,
                currentIndex: currentIndex,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                label: 'Locations',
                onTap: () => _onTap(context, 4),
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );

    // ── Scaffold with Stack: tab content + MiniPlayer above BottomBar ──
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // extendBody lets the body go behind the MiniPlayer + BottomBar area
      extendBody: true,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MiniPlayer sits directly above the BottomNavigationBar
          const MiniPlayerWidget(),
          bottomNav,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? activeColor : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The centre "Now Playing" button – larger and visually elevated.
/// Shows a pulsing dot when a track is actively playing.
class _NavItemCenter extends StatelessWidget {
  final int index;
  final int currentIndex;
  final bool isPlaying;
  final bool hasTrack;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItemCenter({
    required this.index,
    required this.currentIndex,
    required this.isPlaying,
    required this.hasTrack,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isActive || isPlaying
                        ? LinearGradient(
                            colors: [
                              activeColor,
                              activeColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive || isPlaying
                        ? null
                        : activeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: isActive || isPlaying
                        ? [
                            BoxShadow(
                              color: activeColor.withOpacity(0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    LucideIcons.music4,
                    color: isActive || isPlaying ? Colors.white : activeColor,
                    size: 24,
                  ),
                ),
                // Live dot when playing
                if (isPlaying)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF34D399),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Playing',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? activeColor
                    : isPlaying
                        ? activeColor.withOpacity(0.8)
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
