import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _headerBlue = Color(0xFF42A5F5);
  static const Color _menuBlue = Color(0xFF1E88E5);
  static const Color _selectedBackground = Color(0xFFE3F2FD);
  static const Color _switchBlue = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _headerBlue,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: _menuBlue,
                        size: 30,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.refresh,
                      color: Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Demo Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'admin@cams-demo.com',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
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
                  trailing: const Text(
                    'Switch',
                    style: TextStyle(
                      color: _switchBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/store-selection');
                  },
                ),
                Container(
                  color: _selectedBackground,
                  child: ListTile(
                    leading: const Icon(Icons.dashboard, color: _menuBlue),
                    title: const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: _menuBlue,
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
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
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
