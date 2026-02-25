import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../domain/entities/context_rule_entity.dart';

class ContextRulesPage extends StatefulWidget {
  const ContextRulesPage({
    super.key,
    this.showBackButton = true,
    this.createRulePath = '/context-rules/create',
  });

  final bool showBackButton;
  final String createRulePath;

  @override
  State<ContextRulesPage> createState() => _ContextRulesPageState();
}

class _ContextRulesPageState extends State<ContextRulesPage> {
  // ── Mock data — replace with Bloc/repository later ──────────────────────
  final List<ContextRuleEntity> _rules = [
    const ContextRuleEntity(
      id: 'rule-1',
      name: 'Nhiệt cao → Chill',
      conditionType: ConditionType.temperature,
      operator_: ConditionOperator.greaterThan,
      conditionValue: 30,
      actionLabel: 'Phát Chill Retail Playlist',
      targetPlaylistId: 'pl-chill',
      isEnabled: true,
      isTriggered: true, // Demo: sensor is currently above threshold
    ),
    const ContextRuleEntity(
      id: 'rule-2',
      name: 'Đông khách → Energy',
      conditionType: ConditionType.crowd,
      operator_: ConditionOperator.greaterThan,
      conditionValue: 50,
      actionLabel: 'Phát Energy Boost Playlist',
      targetPlaylistId: 'pl-energy',
      isEnabled: true,
    ),
    const ContextRuleEntity(
      id: 'rule-3',
      name: 'Ồn → Focus',
      conditionType: ConditionType.noiseLevel,
      operator_: ConditionOperator.greaterThan,
      conditionValue: 65,
      actionLabel: 'Phát Deep Focus Playlist',
      targetPlaylistId: 'pl-focus',
      isEnabled: false,
    ),
  ];

  void _toggleRule(int index) {
    setState(() {
      _rules[index] =
          _rules[index].copyWith(isEnabled: !_rules[index].isEnabled);
    });
  }

  void _deleteRule(int index) {
    setState(() => _rules.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final rule = _rules.removeAt(oldIndex);
      _rules.insert(newIndex, rule);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.overlay,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(LucideIcons.chevronLeft,
                      color: palette.textPrimary, size: 20),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quản lý tự động hóa',
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_rules.length} luật đang cấu hình',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BlocBuilder<PlayerBloc, ps.PlayerState>(
        builder: (context, playerState) {
          final bottomPad = playerState.hasTrack ? 144.0 : 80.0;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: FloatingActionButton(
                onPressed: () {
                  debugPrint('Navigate to Create Rule Page');
                  context.push(widget.createRulePath);
                },
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              elevation: 6,
              child: const Icon(Icons.add, size: 26),
            ),
          );
        },
      ),
      body: _rules.isEmpty
          ? _EmptyState(palette: palette)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: _rules.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) => Material(
                elevation: 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: child,
              ),
              itemBuilder: (context, index) {
                final rule = _rules[index];
                return _RuleTile(
                  key: ValueKey(rule.id),
                  rule: rule,
                  index: index,
                  palette: palette,
                  isDark: isDark,
                  onToggle: () => _toggleRule(index),
                  onDelete: () => _confirmDelete(context, index, palette),
                  onEdit: () => debugPrint('Navigate to Edit Rule Page'),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, int index, _Palette palette) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xoá luật',
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có muốn xoá luật "${_rules[index].name}" không?',
          style: GoogleFonts.inter(color: palette.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Huỷ', style: GoogleFonts.inter(color: palette.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteRule(index);
            },
            child: Text('Xoá',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rule tile
// ─────────────────────────────────────────────────────────────────────────────
class _RuleTile extends StatelessWidget {
  const _RuleTile({
    super.key,
    required this.rule,
    required this.index,
    required this.palette,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final ContextRuleEntity rule;
  final int index;
  final _Palette palette;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isEnabled = rule.isEnabled;
    final isTriggered = rule.isTriggered;
    final accentColor =
        isEnabled ? palette.accent : palette.textMuted.withOpacity(0.5);

    // Border: green glow when triggered, accent-tinted when enabled, muted when off
    final borderColor = isTriggered
        ? Colors.green
        : isEnabled
            ? palette.accent.withOpacity(0.35)
            : palette.border;

    final boxShadows = <BoxShadow>[
      if (isTriggered)
        BoxShadow(
          color: Colors.green.withOpacity(0.28),
          blurRadius: 14,
          spreadRadius: 2,
        ),
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isTriggered ? 1.5 : 1.0,
        ),
        boxShadow: boxShadows,
      ),
      // Material + InkWell for tap ripple
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Drag handle ──────────────────────────────────────────
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: palette.textMuted.withOpacity(0.45),
                      size: 22,
                    ),
                  ),
                ),

                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: GoogleFonts.poppins(
                          color: isEnabled
                              ? palette.textPrimary
                              : palette.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // "Đang thực thi" badge when triggered
                      if (isTriggered) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Đang thực thi',
                              style: GoogleFonts.inter(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Condition → Action pill row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ConditionPill(
                            label:
                                '${rule.conditionTypeLabel} ${rule.operatorLabel} '
                                '${rule.conditionValue.toStringAsFixed(rule.conditionValue == rule.conditionValue.roundToDouble() ? 0 : 1)}${rule.conditionUnit}',
                            color: accentColor,
                            palette: palette,
                          ),
                          Icon(LucideIcons.arrowRight,
                              size: 12, color: palette.textMuted),
                          _ConditionPill(
                            label: rule.actionLabel,
                            color: palette.accentAlt,
                            palette: palette,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Controls ─────────────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Switch(
                      value: isEnabled,
                      onChanged: (_) => onToggle(),
                      activeColor: palette.accent,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit icon
                        GestureDetector(
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 17,
                              color: palette.textMuted.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Delete icon
                        GestureDetector(
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: Colors.red.shade300.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConditionPill extends StatelessWidget {
  const _ConditionPill(
      {required this.label, required this.color, required this.palette});
  final String label;
  final Color color;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileQuestion,
              size: 64, color: palette.textMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Chưa có luật nào',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bấm + để tạo luật ngữ cảnh đầu tiên',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.textOnAccent,
    required this.shadow,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        overlay: Colors.white.withOpacity(0.06),
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
        accentAlt: AppColors.secondaryLime,
        textOnAccent: AppColors.textDarkPrimary,
        shadow: AppColors.shadowDark,
      );
    }
    return _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      overlay: AppColors.backgroundSecondary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      accentAlt: AppColors.secondaryTeal,
      textOnAccent: AppColors.textInverse,
      shadow: AppColors.shadow,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentAlt;
  final Color textOnAccent;
  final Color shadow;
}
