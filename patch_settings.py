import re

def patch_file(filepath, patches):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old_str, new_str in patches:
        if old_str not in content:
            print(f"Warning: Snippet not found in {filepath}. Retrying without \\r.")
            if old_str.replace('\r', '') in content.replace('\r', ''):
                content = content.replace('\r', '')
                old_str = old_str.replace('\r', '')
        content = content.replace(old_str, new_str)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 3. settings_page.dart
settings_file = "d:/Document/SEP490/Mobile/lib/features/settings/presentation/pages/settings_page.dart"
settings_patches = [
    (
        "import '../bloc/settings_cubit.dart';\nimport '../bloc/settings_state.dart';",
        "import '../bloc/settings_cubit.dart';\nimport '../bloc/settings_state.dart';\nimport '../../../../core/session/session_cubit.dart';"
    ),
    (
        "            final authState = context.watch<AuthBloc>().state;\n            final user = authState.user;\n            final displayName = _getDisplayName(user?.fullName, user?.username);",
        "            final session = context.watch<SessionCubit>().state;\n            final isPlayback = session.isPlaybackDevice;\n            final authState = context.watch<AuthBloc>().state;\n            final user = authState.user;\n            final displayName = isPlayback ? (session.currentSpace?.name ?? 'Device') : _getDisplayName(user?.fullName, user?.username);"
    ),
    (
        "                    _SettingsTile(\n                      icon: Icons.person_outline_rounded,\n                      title: 'User',\n                      trailingText: displayName,",
        "                    _SettingsTile(\n                      icon: isPlayback ? Icons.speaker_group_outlined : Icons.person_outline_rounded,\n                      title: isPlayback ? 'Device' : 'User',\n                      trailingText: displayName,"
    ),
    (
        "                const SizedBox(height: 20),\n                _SectionLabel(label: 'COMPANY', palette: palette),\n                const SizedBox(height: 8),\n                _SettingsGroup(\n                  palette: palette,\n                  children: [\n                    _SettingsTile(\n                      icon: Icons.storefront_outlined,\n                      title: snapshot.companyName,\n                      palette: palette,\n                      onTap: () => context.push('/settings/company'),\n                    ),\n                    _Divider(palette: palette),\n                    _SettingsTile(\n                      icon: Icons.explicit_outlined,\n                      title: 'Explicit music',\n                      trailingText: snapshot.explicitMusicLabel,\n                      palette: palette,\n                      onTap: () => context.push('/settings/company'),\n                    ),\n                  ],\n                ),\n",
        "                if (!isPlayback) ...[\n                  const SizedBox(height: 20),\n                  _SectionLabel(label: 'COMPANY', palette: palette),\n                  const SizedBox(height: 8),\n                  _SettingsGroup(\n                    palette: palette,\n                    children: [\n                      _SettingsTile(\n                        icon: Icons.storefront_outlined,\n                        title: snapshot.companyName,\n                        palette: palette,\n                        onTap: () => context.push('/settings/company'),\n                      ),\n                      _Divider(palette: palette),\n                      _SettingsTile(\n                        icon: Icons.explicit_outlined,\n                        title: 'Explicit music',\n                        trailingText: snapshot.explicitMusicLabel,\n                        palette: palette,\n                        onTap: () => context.push('/settings/company'),\n                      ),\n                    ],\n                  ),\n                ],\n"
    )
]

patch_file(settings_file, settings_patches)
print("Finished patching settings_page.dart")

# 4. song_options_bottom_sheet.dart
song_file = "d:/Document/SEP490/Mobile/lib/core/widgets/song_options_bottom_sheet.dart"
song_patches = [
    (
        "import '../../features/home/domain/entities/song_entity.dart';",
        "import '../../features/home/domain/entities/song_entity.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport '../../core/session/session_cubit.dart';"
    ),
    (
        "  Widget build(BuildContext context) {\n    final isDark = Theme.of(context).brightness == Brightness.dark;",
        "  Widget build(BuildContext context) {\n    final session = context.watch<SessionCubit>().state;\n    final isPlayback = session.isPlaybackDevice;\n    final isDark = Theme.of(context).brightness == Brightness.dark;"
    ),
    (
        "            const SizedBox(height: 8),\n            Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),\n\n            // ── Thêm vào Playlist ────────────────────────────────────────\n            ListTile(",
        "            const SizedBox(height: 8),\n            Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),\n\n            if (!isPlayback)\n              // ── Thêm vào Playlist ────────────────────────────────────────\n              ListTile("
    )
]

patch_file(song_file, song_patches)
print("Finished patching song_options_bottom_sheet.dart")
