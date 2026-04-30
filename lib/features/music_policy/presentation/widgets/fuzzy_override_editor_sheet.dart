import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/store_fuzzy_override_level_enum.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../data/models/fuzzy_override_profile_request.dart';
import '../../domain/entities/fuzzy_override_summary.dart';

class FuzzyOverridePlaylistOption {
  final String id;
  final String label;

  const FuzzyOverridePlaylistOption({
    required this.id,
    required this.label,
  });
}

class FuzzyOverrideEditorSheet extends StatefulWidget {
  const FuzzyOverrideEditorSheet({
    super.key,
    required this.title,
    required this.playlists,
    this.summary,
    this.overrideLevel,
  });

  final String title;
  final List<FuzzyOverridePlaylistOption> playlists;
  final FuzzyOverrideSummary? summary;
  final StoreFuzzyOverrideLevelEnum? overrideLevel;

  @override
  State<FuzzyOverrideEditorSheet> createState() =>
      _FuzzyOverrideEditorSheetState();
}

class _FuzzyOverrideEditorSheetState extends State<FuzzyOverrideEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chillMinController = TextEditingController();
  final _chillMaxController = TextEditingController();
  final _focusMinController = TextEditingController();
  final _focusMaxController = TextEditingController();
  final _energeticMinController = TextEditingController();
  final _energeticMaxController = TextEditingController();
  final _pressureLowController = TextEditingController();
  final _pressureCriticalController = TextEditingController();
  final _stressComfortableController = TextEditingController();
  final _stressHighController = TextEditingController();
  final _densitySparseController = TextEditingController();
  final _densityCrowdedController = TextEditingController();
  final _capacityController = TextEditingController();
  final _defaultDensityController = TextEditingController();
  late final Set<String> _selectedPlaylistIds;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.summary?.headline ?? '';
    _selectedPlaylistIds =
        widget.summary?.allowedPlaylistIds.toSet() ?? <String>{};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chillMinController.dispose();
    _chillMaxController.dispose();
    _focusMinController.dispose();
    _focusMaxController.dispose();
    _energeticMinController.dispose();
    _energeticMaxController.dispose();
    _pressureLowController.dispose();
    _pressureCriticalController.dispose();
    _stressComfortableController.dispose();
    _stressHighController.dispose();
    _densitySparseController.dispose();
    _densityCrowdedController.dispose();
    _capacityController.dispose();
    _defaultDensityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final textPrimary = tokens.textPrimary;
    final textMuted = tokens.textSecondary;
    final sheetBackground = tokens.bgContainer;
    final panelBackground = tokens.bgElevated;
    final borderColor = tokens.borderSecondary;
    final accent = colorScheme.primary;
    final allowsPlaylistOverride =
        widget.overrideLevel?.allowsPlaylistOverride ?? true;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          top: 12,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sheetBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.poppins(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Create and activate a fuzzy override profile for this target.',
                                style: GoogleFonts.inter(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: panelBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.summary?.hasAnyData ?? false) ...[
                            FuzzyOverrideSummaryCard(
                              title: 'Current Summary',
                              summary: widget.summary!,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (widget.overrideLevel != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: panelBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    allowsPlaylistOverride
                                        ? Icons.tune_rounded
                                        : Icons.lock_outline_rounded,
                                    color: accent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Override level: ${widget.overrideLevel!.displayName}',
                                      style: GoogleFonts.inter(
                                        color: textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _nameController,
                            decoration: _decoration(
                              label: 'Profile name (optional)',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTile(
                            title: 'BPM Bands',
                            subtitle:
                                'Tune chill, focus, and energetic ranges.',
                            child: Column(
                              children: [
                                _buildBpmRow(
                                  isDark: isDark,
                                  label: 'Chill',
                                  minController: _chillMinController,
                                  maxController: _chillMaxController,
                                ),
                                const SizedBox(height: 10),
                                _buildBpmRow(
                                  isDark: isDark,
                                  label: 'Focus',
                                  minController: _focusMinController,
                                  maxController: _focusMaxController,
                                ),
                                const SizedBox(height: 10),
                                _buildBpmRow(
                                  isDark: isDark,
                                  label: 'Energetic',
                                  minController: _energeticMinController,
                                  maxController: _energeticMaxController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTile(
                            title: 'Thresholds',
                            subtitle:
                                'Pressure, stress, and density breakpoints.',
                            child: Column(
                              children: [
                                _buildNumberField(
                                  controller: _pressureLowController,
                                  label: 'Pressure low max',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _pressureCriticalController,
                                  label: 'Pressure critical min',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _stressComfortableController,
                                  label: 'Stress comfortable max',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _stressHighController,
                                  label: 'Stress high min',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _densitySparseController,
                                  label: 'Density sparse max',
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _densityCrowdedController,
                                  label: 'Density crowded min',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTile(
                            title: 'Capacity',
                            subtitle:
                                'Optional context values for density fallback.',
                            child: Column(
                              children: [
                                _buildNumberField(
                                  controller: _capacityController,
                                  label: 'Space capacity',
                                  isDark: isDark,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 10),
                                _buildNumberField(
                                  controller: _defaultDensityController,
                                  label: 'Default density ratio when null',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTile(
                            title: 'Allowed Playlists',
                            subtitle: allowsPlaylistOverride
                                ? 'Restrict the profile to specific playlists if needed.'
                                : 'This target cannot override allowed playlists at the current level.',
                            child: allowsPlaylistOverride
                                ? _AllowedPlaylistPicker(
                                    options: widget.playlists,
                                    selectedIds: _selectedPlaylistIds,
                                    onToggle: (playlistId) {
                                      setState(() {
                                        if (_selectedPlaylistIds
                                            .contains(playlistId)) {
                                          _selectedPlaylistIds
                                              .remove(playlistId);
                                        } else {
                                          _selectedPlaylistIds.add(playlistId);
                                        }
                                      });
                                    },
                                  )
                                : Text(
                                    'Playlist overrides stay locked to the brand-level policy.',
                                    style: GoogleFonts.inter(
                                      color: textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: panelBackground,
                      border: Border(
                        top: BorderSide(color: borderColor),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          Navigator.pop(
                            context,
                            FuzzyOverrideProfileRequest(
                              name: _nullable(_nameController.text),
                              chillBpmMin: _parseInt(_chillMinController.text),
                              chillBpmMax: _parseInt(_chillMaxController.text),
                              focusBpmMin: _parseInt(_focusMinController.text),
                              focusBpmMax: _parseInt(_focusMaxController.text),
                              energeticBpmMin:
                                  _parseInt(_energeticMinController.text),
                              energeticBpmMax:
                                  _parseInt(_energeticMaxController.text),
                              pressureLowMax:
                                  _parseDouble(_pressureLowController.text),
                              pressureCriticalMin: _parseDouble(
                                  _pressureCriticalController.text),
                              stressComfortableMax: _parseDouble(
                                  _stressComfortableController.text),
                              stressHighMin:
                                  _parseDouble(_stressHighController.text),
                              densitySparseMax:
                                  _parseDouble(_densitySparseController.text),
                              densityCrowdedMin:
                                  _parseDouble(_densityCrowdedController.text),
                              spaceCapacity:
                                  _parseInt(_capacityController.text),
                              defaultDensityRatioWhenNull:
                                  _parseDouble(_defaultDensityController.text),
                              allowedPlaylistIds: allowsPlaylistOverride
                                  ? _selectedPlaylistIds.toList(growable: false)
                                  : null,
                            ),
                          );
                        },
                        child: const Text('Save Override'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBpmRow({
    required bool isDark,
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            controller: minController,
            label: '$label min',
            isDark: isDark,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildNumberField(
            controller: maxController,
            label: '$label max',
            isDark: isDark,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return null;
        return num.tryParse(trimmed) == null ? 'Enter a valid number.' : null;
      },
      decoration: _decoration(label: label, isDark: isDark),
    );
  }

  InputDecoration _decoration({
    required String label,
    required bool isDark,
  }) {
    final tokens = context.camsTokens;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: tokens.textSecondary,
        fontSize: 12,
      ),
      filled: true,
      fillColor: tokens.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class FuzzyOverrideSummaryCard extends StatelessWidget {
  const FuzzyOverrideSummaryCard({
    super.key,
    required this.title,
    required this.summary,
  });

  final String title;
  final FuzzyOverrideSummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final textPrimary = tokens.textPrimary;
    final textMuted = tokens.textSecondary;
    final chips = <String>[
      if (summary.templateName?.trim().isNotEmpty ?? false)
        summary.templateName!.trim(),
      if (summary.aiGenerationMode != null)
        summary.aiGenerationMode!.displayName,
      if (summary.overrideLevel != null) summary.overrideLevel!.displayName,
      if (summary.playlistSummary != null) summary.playlistSummary!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.headline ?? 'Fuzzy override is configured',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.bgContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chip,
                        style: GoogleFonts.inter(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final textPrimary = tokens.textPrimary;
    final textMuted = tokens.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AllowedPlaylistPicker extends StatelessWidget {
  const _AllowedPlaylistPicker({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<FuzzyOverridePlaylistOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final textMuted = context.camsTokens.textSecondary;
    if (options.isEmpty) {
      return Text(
        'No playlists available for this store yet.',
        style: GoogleFonts.inter(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = selectedIds.contains(option.id);
        return FilterChip(
          label: Text(option.label),
          selected: selected,
          onSelected: (_) => onToggle(option.id),
        );
      }).toList(),
    );
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _parseInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}
