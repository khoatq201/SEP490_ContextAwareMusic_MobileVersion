import re

def patch_file(filepath, patches):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old_str, new_str in patches:
        if old_str not in content:
            print(f"Warning: Could not find target string in {filepath}")
            # Try removing \r just in case
            if old_str.replace('\r', '') in content.replace('\r', ''):
                print(f"Found it if ignoring \\r")
                content = content.replace('\r', '')
                old_str = old_str.replace('\r', '')
            else:
                print("Snippet not found at all")
        content = content.replace(old_str, new_str)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. home_tab_page.dart
home_file = "d:/Document/SEP490/Mobile/lib/features/home/presentation/pages/home_tab_page.dart"
home_patches = [
    (
        "import '../bloc/home_state.dart';",
        "import '../bloc/home_state.dart';\nimport '../../../../core/session/session_cubit.dart';"
    ),
    (
        "  Widget build(BuildContext context) {\n    return SliverAppBar(\n      pinned: true,\n      floating: false,\n      backgroundColor: palette.bg,\n      surfaceTintColor: Colors.transparent,\n      elevation: 0,\n      expandedHeight: 86,\n      flexibleSpace: FlexibleSpaceBar(\n        collapseMode: CollapseMode.pin,\n        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),\n        title: GestureDetector(\n          onTap: () => _showSpaceSheet(context),",
        "  Widget build(BuildContext context) {\n    final session = context.watch<SessionCubit>().state;\n    final isPlayback = session.isPlaybackDevice;\n\n    return SliverAppBar(\n      pinned: true,\n      floating: false,\n      backgroundColor: palette.bg,\n      surfaceTintColor: Colors.transparent,\n      elevation: 0,\n      expandedHeight: 86,\n      flexibleSpace: FlexibleSpaceBar(\n        collapseMode: CollapseMode.pin,\n        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),\n        title: GestureDetector(\n          onTap: isPlayback ? null : () => _showSpaceSheet(context),"
    ),
    (
        "              Text(\n                'REMOTE CONTROLLING',\n                style: GoogleFonts.inter(\n                  color: palette.textMuted,\n                  fontSize: 9,\n                  fontWeight: FontWeight.w700,\n                  letterSpacing: 1.4,\n                ),\n              ),\n              const SizedBox(height: 1),\n              Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Text(\n                    'Sảnh Chính',\n                    style: GoogleFonts.poppins(\n                      color: palette.textPrimary,\n                      fontSize: 18,\n                      fontWeight: FontWeight.w700,\n                      letterSpacing: -0.3,\n                    ),\n                  ),\n                  const SizedBox(width: 4),\n                  Icon(LucideIcons.chevronsUpDown,\n                      color: palette.accent, size: 14),\n                ],\n              ),",
        "              Text(\n                isPlayback ? 'PLAYBACK DEVICE' : 'REMOTE CONTROLLING',\n                style: GoogleFonts.inter(\n                  color: palette.textMuted,\n                  fontSize: 9,\n                  fontWeight: FontWeight.w700,\n                  letterSpacing: 1.4,\n                ),\n              ),\n              const SizedBox(height: 1),\n              Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Text(\n                    isPlayback ? (session.currentSpace?.name ?? 'Unknown Space') : 'Sảnh Chính',\n                    style: GoogleFonts.poppins(\n                      color: palette.textPrimary,\n                      fontSize: 18,\n                      fontWeight: FontWeight.w700,\n                      letterSpacing: -0.3,\n                    ),\n                  ),\n                  if (!isPlayback) ...[\n                    const SizedBox(width: 4),\n                    Icon(LucideIcons.chevronsUpDown,\n                        color: palette.accent, size: 14),\n                  ],\n                ],\n              ),"
    )
]

patch_file(home_file, home_patches)
print("Finished patching home_tab_page.dart")
