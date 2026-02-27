import re

def patch_file(filepath, patches):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old_str, new_str in patches:
        if old_str not in content:
            print(f"Warning: Snippet not found. Retrying without \\r.")
            if old_str.replace('\r', '') in content.replace('\r', ''):
                content = content.replace('\r', '')
                old_str = old_str.replace('\r', '')
        content = content.replace(old_str, new_str)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 2. now_playing_tab_page.dart
np_file = "d:/Document/SEP490/Mobile/lib/features/now_playing/presentation/pages/now_playing_tab_page.dart"
np_patches = [
    (
        "import '../../../../features/space_control/domain/entities/sensor_data.dart';",
        "import '../../../../features/space_control/domain/entities/sensor_data.dart';\nimport '../../../../core/session/session_cubit.dart';"
    ),
    (
        "  Widget build(BuildContext context) {\n    final palette = _NPPalette.fromBrightness(Theme.of(context).brightness);\n\n    return BlocBuilder<PlayerBloc, ps.PlayerState>(",
        "  Widget build(BuildContext context) {\n    final palette = _NPPalette.fromBrightness(Theme.of(context).brightness);\n    final session = context.watch<SessionCubit>().state;\n    final isPlayback = session.isPlaybackDevice;\n\n    return BlocBuilder<PlayerBloc, ps.PlayerState>("
    ),
    (
        "                        title: _SpaceNameTitle(\n                          spaceName: spaceState.space?.name ??\n                              playerState.activeSpaceName ??\n                              'Now Playing',\n                          isOnline: spaceState.space?.isOnline ?? false,\n                          hasTrack: playerState.hasTrack,\n                          canSwap: playerState.availableSpaces.length > 1,\n                          palette: palette,\n                          onTap: playerState.availableSpaces.length > 1\n                              ? () => showModalBottomSheet(\n                                    context: context,\n                                    useRootNavigator: true,\n                                    backgroundColor: Colors.transparent,\n                                    isScrollControlled: true,\n                                    builder: (_) => _SpaceSwapSheet(\n                                      playerState: playerState,\n                                      palette: palette,\n                                    ),\n                                  )\n                              : null,\n                        ),",
        "                        title: _SpaceNameTitle(\n                          spaceName: isPlayback ? '🔊 Now Playing' : '🎛 Remote Controlling · ${spaceState.space?.name ?? playerState.activeSpaceName ?? 'No Space'}',\n                          isOnline: spaceState.space?.isOnline ?? false,\n                          hasTrack: playerState.hasTrack,\n                          canSwap: !isPlayback && playerState.availableSpaces.length > 1,\n                          palette: palette,\n                          onTap: (!isPlayback && playerState.availableSpaces.length > 1)\n                              ? () => showModalBottomSheet(\n                                    context: context,\n                                    useRootNavigator: true,\n                                    backgroundColor: Colors.transparent,\n                                    isScrollControlled: true,\n                                    builder: (_) => _SpaceSwapSheet(\n                                      playerState: playerState,\n                                      palette: palette,\n                                    ),\n                                  )\n                              : null,\n                        ),"
    ),
    (
        "    _NPPalette palette,\n  ) {\n    final track = playerState.currentTrack;",
        "    _NPPalette palette,\n  ) {\n    final session = context.watch<SessionCubit>().state;\n    final isPlayback = session.isPlaybackDevice;\n    final track = playerState.currentTrack;"
    ),
    (
        "                // ── Mood CTA ────────────────────────────────────────────────\n                if (!hasNoContext) ...[\n                  const SizedBox(height: 24),\n                  _OverrideMoodCTA(\n                    currentMood: mood,\n                    palette: palette,\n                    spaceId: spaceState.space?.id ?? '',\n                  ),\n                ],",
        "                // ── Mood CTA ────────────────────────────────────────────────\n                if (!hasNoContext && !isPlayback) ...[\n                  const SizedBox(height: 24),\n                  _OverrideMoodCTA(\n                    currentMood: mood,\n                    palette: palette,\n                    spaceId: spaceState.space?.id ?? '',\n                  ),\n                ],"
    )
]

patch_file(np_file, np_patches)
print("Finished patching now_playing_tab_page.dart")
