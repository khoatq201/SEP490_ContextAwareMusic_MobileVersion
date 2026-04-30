import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/cams_theme_tokens.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    return Drawer(
      backgroundColor: tokens.bgContainer,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.onPrimary,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.refresh,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Demo Administrator',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'admin@cams-demo.com',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront),
                  title: const Text('3 Stores'),
                  trailing: Text(
                    'Switch',
                    style: TextStyle(
                      color: tokens.techAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/store-selection');
                  },
                ),
                Container(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: Icon(Icons.dashboard, color: colorScheme.primary),
                    title: Text(
                      'Dashboard',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: const Text('Playlists'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/playlists');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/profile');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: tokens.error,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: tokens.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
