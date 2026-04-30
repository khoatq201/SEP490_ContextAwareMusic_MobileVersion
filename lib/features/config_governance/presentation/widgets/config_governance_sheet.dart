import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/config_flat_row.dart';
import '../../domain/entities/config_governance_enums.dart';
import '../../domain/entities/config_key_metadata.dart';
import '../../domain/entities/config_query.dart';
import '../bloc/config_governance_cubit.dart';
import '../bloc/config_governance_state.dart';

class ConfigAffectedSpaceOption {
  final String id;
  final String name;

  const ConfigAffectedSpaceOption({
    required this.id,
    required this.name,
  });
}

class ConfigGovernanceSheet extends StatelessWidget {
  const ConfigGovernanceSheet.brand({
    super.key,
    required this.targetName,
    List<ConfigAffectedSpaceOption> childStoreOptions = const [],
  })  : scope = ConfigGovernanceScope.brand,
        storeId = null,
        spaceId = null,
        childSpaceOptions = childStoreOptions;

  const ConfigGovernanceSheet.store({
    super.key,
    this.storeId,
    required this.targetName,
    this.childSpaceOptions = const [],
  })  : scope = ConfigGovernanceScope.store,
        spaceId = null;

  const ConfigGovernanceSheet.space({
    super.key,
    required this.spaceId,
    required this.targetName,
  })  : scope = ConfigGovernanceScope.space,
        storeId = null,
        childSpaceOptions = const [];

  final ConfigGovernanceScope scope;
  final String? storeId;
  final String? spaceId;
  final String targetName;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ConfigGovernanceCubit>();
        switch (scope) {
          case ConfigGovernanceScope.brand:
            cubit.loadBrand(query: const ConfigQuery(pageSize: 50));
            break;
          case ConfigGovernanceScope.store:
            cubit.loadStore(
              storeId: storeId,
              query: const ConfigQuery(pageSize: 50),
            );
            break;
          case ConfigGovernanceScope.space:
            cubit.loadSpace(
              spaceId: spaceId!,
              query: const ConfigQuery(pageSize: 50),
            );
            break;
        }
        return cubit;
      },
      child: _ConfigGovernanceSheetView(
        scope: scope,
        targetName: targetName,
        childSpaceOptions: childSpaceOptions,
      ),
    );
  }
}

class _ConfigGovernanceSheetView extends StatefulWidget {
  const _ConfigGovernanceSheetView({
    required this.scope,
    required this.targetName,
    required this.childSpaceOptions,
  });

  final ConfigGovernanceScope scope;
  final String targetName;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  State<_ConfigGovernanceSheetView> createState() =>
      _ConfigGovernanceSheetViewState();
}

class _ConfigGovernanceSheetViewState
    extends State<_ConfigGovernanceSheetView> {
  final _keyPrefixController = TextEditingController();

  @override
  void dispose() {
    _keyPrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ConfigPalette.of(context);
    final title = switch (widget.scope) {
      ConfigGovernanceScope.brand => 'Brand Config Governance',
      ConfigGovernanceScope.store => 'Store Config Governance',
      ConfigGovernanceScope.space => 'Space Config Governance',
    };
    final subtitle = widget.targetName;

    return BlocListener<ConfigGovernanceCubit, ConfigGovernanceState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        final successMessage = state.successMessage;
        if (successMessage != null && successMessage.isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(successMessage)));
          return;
        }

        final errorMessage = state.errorMessage;
        if (errorMessage != null &&
            errorMessage.isNotEmpty &&
            state.rows.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: SafeArea(
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
                color: palette.sheet,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SheetHeader(
                    scope: widget.scope,
                    title: title,
                    subtitle: subtitle,
                    palette: palette,
                  ),
                  const SizedBox(height: 12),
                  _ScopeOverviewCard(
                    scope: widget.scope,
                    targetName: widget.targetName,
                    availableTargetCount: widget.childSpaceOptions.length,
                    palette: palette,
                  ),
                  const SizedBox(height: 14),
                  _QueryControls(
                    controller: _keyPrefixController,
                    palette: palette,
                  ),
                  const SizedBox(height: 10),
                  _DomainFilterBar(palette: palette),
                  const SizedBox(height: 10),
                  Expanded(
                    child: BlocBuilder<ConfigGovernanceCubit,
                        ConfigGovernanceState>(
                      builder: (context, state) {
                        if (state.isInitialLoading) {
                          return const CamsSkeletonList(
                            itemCount: 7,
                            showLeading: false,
                            showTrailing: true,
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          );
                        }

                        if (state.status == ConfigGovernanceStatus.error &&
                            state.rows.isEmpty) {
                          return _ErrorState(
                            palette: palette,
                            message: state.errorMessage,
                            onRetry: () =>
                                context.read<ConfigGovernanceCubit>().refresh(),
                          );
                        }

                        if (state.rows.isEmpty) {
                          return _EmptyState(
                            palette: palette,
                            onRefresh: () =>
                                context.read<ConfigGovernanceCubit>().refresh(),
                          );
                        }

                        return _ConfigRowsList(
                          palette: palette,
                          state: state,
                          childSpaceOptions: widget.childSpaceOptions,
                        );
                      },
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
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.scope,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final ConfigGovernanceScope scope;
  final String title;
  final String subtitle;
  final _ConfigPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _scopeHeaderIcon(scope),
              color: palette.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: palette.textMuted),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeOverviewCard extends StatelessWidget {
  const _ScopeOverviewCard({
    required this.scope,
    required this.targetName,
    required this.availableTargetCount,
    required this.palette,
  });

  final ConfigGovernanceScope scope;
  final String targetName;
  final int availableTargetCount;
  final _ConfigPalette palette;

  @override
  Widget build(BuildContext context) {
    final title = switch (scope) {
      ConfigGovernanceScope.brand => 'Brand defaults and rollout targets',
      ConfigGovernanceScope.store => 'Store configuration',
      ConfigGovernanceScope.space => 'Space-level effective override',
    };
    final description = switch (scope) {
      ConfigGovernanceScope.brand =>
        'Brand values define the parent defaults for every store. Override intents let you target selected stores instead of applying changes implicitly to all children.',
      ConfigGovernanceScope.store =>
        'Review and update config values that apply to this store.',
      ConfigGovernanceScope.space =>
        'Space values sit at the leaf scope. Use this layer for local exceptions, or inherit from the parent store to remove a space override.',
    };
    final targetLabel = switch (scope) {
      ConfigGovernanceScope.brand => 'stores',
      ConfigGovernanceScope.store => null,
      ConfigGovernanceScope.space => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textMuted,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ConfigBadge(
                  label: targetName,
                  color: palette.accent,
                  palette: palette,
                ),
                _ConfigBadge(
                  label: _scopeShortLabel(scope),
                  color: AppColors.secondaryTeal,
                  palette: palette,
                ),
                if (targetLabel != null)
                  _ConfigBadge(
                    label: '$availableTargetCount $targetLabel available',
                    color: AppColors.success,
                    palette: palette,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryControls extends StatelessWidget {
  const _QueryControls({
    required this.controller,
    required this.palette,
  });

  final TextEditingController controller;
  final _ConfigPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) =>
            context.read<ConfigGovernanceCubit>().setKeyPrefix(value),
        style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
        decoration: InputDecoration(
          hintText: 'Key prefix',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: palette.textMuted,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: palette.textMuted,
            size: 18,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => context
                        .read<ConfigGovernanceCubit>()
                        .setKeyPrefix(controller.text),
                    icon: Icon(
                      LucideIcons.check,
                      color: palette.accent,
                      size: 18,
                    ),
                    tooltip: 'Apply',
                  ),
                  if (value.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        controller.clear();
                        context
                            .read<ConfigGovernanceCubit>()
                            .setKeyPrefix(null);
                      },
                      icon: Icon(
                        LucideIcons.x,
                        color: palette.textMuted,
                        size: 18,
                      ),
                      tooltip: 'Clear',
                    ),
                ],
              );
            },
          ),
          filled: true,
          fillColor: palette.panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.accent),
          ),
        ),
      ),
    );
  }
}

class _DomainFilterBar extends StatelessWidget {
  const _DomainFilterBar({required this.palette});

  final _ConfigPalette palette;

  @override
  Widget build(BuildContext context) {
    final domains = ConfigDomain.values
        .where((domain) => domain != ConfigDomain.unknown)
        .toList(growable: false);

    return SizedBox(
      height: 38,
      child: BlocBuilder<ConfigGovernanceCubit, ConfigGovernanceState>(
        buildWhen: (previous, current) => previous.query != current.query,
        builder: (context, state) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FilterChip(
                  label: 'All',
                  selected: state.query.domain == null,
                  palette: palette,
                  onTap: () =>
                      context.read<ConfigGovernanceCubit>().setDomain(null),
                );
              }

              final domain = domains[index - 1];
              return _FilterChip(
                label: _domainLabel(domain),
                selected: state.query.domain == domain,
                palette: palette,
                onTap: () =>
                    context.read<ConfigGovernanceCubit>().setDomain(domain),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: domains.length + 1,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _ConfigPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: palette.accent.withValues(alpha: 0.16),
      backgroundColor: palette.panel,
      side: BorderSide(
        color: selected ? palette.accent : palette.border,
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected ? palette.accent : palette.textMuted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _ConfigRowsList extends StatelessWidget {
  const _ConfigRowsList({
    required this.palette,
    required this.state,
    required this.childSpaceOptions,
  });

  final _ConfigPalette palette;
  final ConfigGovernanceState state;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupRowsByDomain(state.rows);
    final domains = grouped.keys.toList()
      ..sort((left, right) => left.value.compareTo(right.value));

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: () =>
          context.read<ConfigGovernanceCubit>().refresh(keepRows: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          if (state.isRefreshing) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: palette.accent,
                backgroundColor: palette.accent.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _SummaryStrip(palette: palette, state: state),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 10),
            _InlineError(palette: palette, message: state.errorMessage!),
          ],
          const SizedBox(height: 10),
          for (final domain in domains) ...[
            _DomainSection(
              palette: palette,
              scope: state.scope,
              domain: domain,
              rows: grouped[domain]!,
              savingKey: state.savingKey,
              childSpaceOptions: childSpaceOptions,
            ),
            const SizedBox(height: 12),
          ],
          if (state.hasNext)
            FilledButton.icon(
              onPressed: state.isLoadingMore
                  ? null
                  : () => context.read<ConfigGovernanceCubit>().loadNextPage(),
              icon: state.isLoadingMore
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.textMuted,
                      ),
                    )
                  : const Icon(LucideIcons.chevronsDown, size: 18),
              label: Text(state.isLoadingMore ? 'Loading' : 'Load more'),
            ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.palette,
    required this.state,
  });

  final _ConfigPalette palette;
  final ConfigGovernanceState state;

  @override
  Widget build(BuildContext context) {
    final domain = state.query.domain;
    final keyPrefix = state.query.keyPrefix;
    final scope = state.scope;
    final blockedCount = scope == null
        ? 0
        : state.rows
            .where((row) =>
                _editBlockReason(row, scope)?.trim().isNotEmpty == true)
            .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (scope != null)
            _ConfigBadge(
              label: _scopeShortLabel(scope),
              color: AppColors.primaryCyan,
              palette: palette,
            ),
          _ConfigBadge(
            label: '${state.rows.length}/${state.totalItems} rows',
            color: palette.accent,
            palette: palette,
          ),
          if (blockedCount > 0)
            _ConfigBadge(
              label: '$blockedCount locked',
              color: AppColors.warning,
              palette: palette,
            ),
          if (domain != null)
            _ConfigBadge(
              label: _domainLabel(domain),
              color: _domainColor(domain),
              palette: palette,
            ),
          if (keyPrefix != null)
            _ConfigBadge(
              label: keyPrefix,
              color: AppColors.secondaryTeal,
              palette: palette,
            ),
        ],
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  const _DomainSection({
    required this.palette,
    required this.scope,
    required this.domain,
    required this.rows,
    required this.savingKey,
    required this.childSpaceOptions,
  });

  final _ConfigPalette palette;
  final ConfigGovernanceScope? scope;
  final ConfigDomain domain;
  final List<ConfigFlatRow> rows;
  final String? savingKey;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _domainColor(domain),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _domainLabel(domain),
                style: AppTypography.labelLarge.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${rows.length}',
              style: AppTypography.labelMedium.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in rows) ...[
          _ConfigRowTile(
            palette: palette,
            row: row,
            scope: scope,
            isSaving: savingKey == row.key,
            childSpaceOptions: childSpaceOptions,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ConfigRowTile extends StatelessWidget {
  const _ConfigRowTile({
    required this.palette,
    required this.row,
    required this.scope,
    required this.isSaving,
    required this.childSpaceOptions,
  });

  final _ConfigPalette palette;
  final ConfigFlatRow row;
  final ConfigGovernanceScope? scope;
  final bool isSaving;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  Widget build(BuildContext context) {
    final overrideLabel = _overrideLabel(row);
    final overrideColor = _overrideColor(row);
    final metadata = metadataForConfigKey(row.key);
    final editBlockReason = scope == null
        ? 'Config scope is unavailable.'
        : _editBlockReason(row, scope!);
    final canEdit = editBlockReason == null;
    final canInheritFromStore = scope == ConfigGovernanceScope.space &&
        canEdit &&
        (row.value?.trim().isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _domainColor(row.domain).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _configKeyIcon(row.key, row.domain),
                  color: _domainColor(row.domain),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ConfigBadge(
                    label: _scopeLabel(row.scopeType),
                    color: palette.accent,
                    palette: palette,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              if (isSaving)
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.accent,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canInheritFromStore) ...[
                      Tooltip(
                        message: 'Inherit from store',
                        child: IconButton(
                          onPressed: () => _inheritFromStore(context, row),
                          icon: const Icon(
                            LucideIcons.undo2,
                            size: 17,
                          ),
                          color: palette.accent,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Tooltip(
                      message: canEdit ? 'Edit value' : editBlockReason,
                      child: IconButton(
                        onPressed: canEdit
                            ? () => _openConfigValueEditor(
                                  context,
                                  row,
                                  scope!,
                                  childSpaceOptions,
                                )
                            : null,
                        icon: Icon(
                          canEdit ? LucideIcons.pencil : LucideIcons.lock,
                          size: 17,
                        ),
                        color: canEdit ? palette.accent : palette.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metadata.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _valueText(row.value),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: palette.textPrimary,
              height: 1.35,
            ),
          ),
          if (row.policyDefaultValue?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              'Default: ${_valueText(row.policyDefaultValue)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConfigBadge(
                label: _valueTypeLabel(row.valueType),
                color: AppColors.secondaryTeal,
                palette: palette,
              ),
              _ConfigBadge(
                label: _tierLabel(row.policyTier),
                color: AppColors.warning,
                palette: palette,
              ),
              if (overrideLabel != null)
                _ConfigBadge(
                  label: overrideLabel,
                  color: overrideColor,
                  palette: palette,
                ),
            ],
          ),
          if (row.brandLockReason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.lock,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    row.brandLockReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigBadge extends StatelessWidget {
  const _ConfigBadge({
    required this.label,
    required this.color,
    required this.palette,
  });

  final String label;
  final Color color;
  final _ConfigPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: palette.isDark ? AppColors.textDarkPrimary : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> _openConfigValueEditor(
  BuildContext context,
  ConfigFlatRow row,
  ConfigGovernanceScope scope,
  List<ConfigAffectedSpaceOption> childSpaceOptions,
) async {
  final result = await showDialog<_ConfigValueEditResult>(
    context: context,
    builder: (_) => _ConfigValueEditorDialog(
      row: row,
      scope: scope,
      childSpaceOptions: childSpaceOptions,
    ),
  );

  if (result == null || !context.mounted) return;

  await context.read<ConfigGovernanceCubit>().upsertValue(
        row: row,
        valueType: result.valueType,
        value: result.value,
        brandOverrideIntent: result.brandOverrideIntent,
        storeOverrideIntent: result.storeOverrideIntent,
        spaceOverrideIntent: result.spaceOverrideIntent,
        overrideReason: result.overrideReason,
        targetStoreIds: result.targetStoreIds,
        targetSpaceIds: result.targetSpaceIds,
      );
}

Future<void> _inheritFromStore(
  BuildContext context,
  ConfigFlatRow row,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Inherit from store'),
      content: const Text(
        'This removes the current space override and restores inheritance from the parent store value.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await context.read<ConfigGovernanceCubit>().inheritFromStore(row: row);
}

class _ConfigValueEditResult {
  const _ConfigValueEditResult({
    required this.valueType,
    required this.value,
    this.brandOverrideIntent,
    this.storeOverrideIntent,
    this.spaceOverrideIntent,
    this.overrideReason,
    this.targetStoreIds,
    this.targetSpaceIds,
  });

  final ConfigValueType valueType;
  final String value;
  final BrandOverrideIntent? brandOverrideIntent;
  final StoreOverrideIntent? storeOverrideIntent;
  final SpaceOverrideIntent? spaceOverrideIntent;
  final String? overrideReason;
  final List<String>? targetStoreIds;
  final List<String>? targetSpaceIds;
}

class _ConfigValueEditorDialog extends StatefulWidget {
  const _ConfigValueEditorDialog({
    required this.row,
    required this.scope,
    required this.childSpaceOptions,
  });

  final ConfigFlatRow row;
  final ConfigGovernanceScope scope;
  final List<ConfigAffectedSpaceOption> childSpaceOptions;

  @override
  State<_ConfigValueEditorDialog> createState() =>
      _ConfigValueEditorDialogState();
}

class _ConfigValueEditorDialogState extends State<_ConfigValueEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  late ConfigValueType _valueType;
  BrandOverrideIntent _brandOverrideIntent = BrandOverrideIntent.none;
  StoreOverrideIntent _storeOverrideIntent = StoreOverrideIntent.none;
  final Set<String> _selectedTargetIds = <String>{};
  String? _targetSelectionError;
  String? _boolValue;

  @override
  void initState() {
    super.initState();
    _valueType = _initialEditorValueType(widget.row);
    final initialValue = _initialEditorValue(widget.row);
    if (_valueType == ConfigValueType.boolean) {
      _boolValue = _normalizeBoolValue(initialValue);
    } else {
      _valueController.text = initialValue;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ConfigPalette.of(context);
    final scopeLabel = switch (widget.scope) {
      ConfigGovernanceScope.brand => 'brand',
      ConfigGovernanceScope.store => 'store',
      ConfigGovernanceScope.space => 'space',
    };
    final metadata = metadataForConfigKey(widget.row.key);
    final showStoreOverrideIntent =
        widget.scope == ConfigGovernanceScope.store &&
            widget.childSpaceOptions.isNotEmpty;
    final showAffectedTargets =
        widget.scope != ConfigGovernanceScope.space && _requiresTargetSelection;
    final affectedTargetLabel =
        widget.scope == ConfigGovernanceScope.brand ? 'stores' : 'spaces';

    return AlertDialog(
      title: Text('Edit $scopeLabel config'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.row.key,
                  style: AppTypography.labelSmall.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metadata.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ConfigBadge(
                      label: _domainLabel(widget.row.domain),
                      color: _domainColor(widget.row.domain),
                      palette: palette,
                    ),
                    _ConfigBadge(
                      label: _scopeLabel(widget.row.scopeType),
                      color: palette.accent,
                      palette: palette,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ConfigValueType>(
                  initialValue: _valueType,
                  decoration: const InputDecoration(
                    labelText: 'Value type',
                    border: OutlineInputBorder(),
                  ),
                  items: ConfigValueType.values
                      .where((type) => type != ConfigValueType.unknown)
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_valueTypeLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _valueType = value;
                      if (value == ConfigValueType.boolean) {
                        _boolValue ??= 'true';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildValueInput(),
                if (widget.row.policyDefaultValue?.trim().isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Policy default: ${widget.row.policyDefaultValue}',
                    style: AppTypography.labelSmall.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (showStoreOverrideIntent) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StoreOverrideIntent>(
                    initialValue: _storeOverrideIntent,
                    decoration: const InputDecoration(
                      labelText: 'Override intent',
                      border: OutlineInputBorder(),
                    ),
                    items: StoreOverrideIntent.values
                        .map(
                          (intent) => DropdownMenuItem(
                            value: intent,
                            child: Text(_storeOverrideIntentLabel(intent)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _storeOverrideIntent = value;
                        _targetSelectionError = null;
                        if (value == StoreOverrideIntent.none) {
                          _selectedTargetIds.clear();
                        }
                      });
                    },
                  ),
                  if (_storeOverrideIntent != StoreOverrideIntent.none) ...[
                    const SizedBox(height: 8),
                    Text(
                      _storeOverrideIntentDescription(_storeOverrideIntent),
                      style: AppTypography.labelSmall.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
                if (widget.scope == ConfigGovernanceScope.brand) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BrandOverrideIntent>(
                    initialValue: _brandOverrideIntent,
                    decoration: const InputDecoration(
                      labelText: 'Override intent',
                      border: OutlineInputBorder(),
                    ),
                    items: BrandOverrideIntent.values
                        .map(
                          (intent) => DropdownMenuItem(
                            value: intent,
                            child: Text(_brandOverrideIntentLabel(intent)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _brandOverrideIntent = value;
                        _targetSelectionError = null;
                        if (value == BrandOverrideIntent.none) {
                          _selectedTargetIds.clear();
                        }
                      });
                    },
                  ),
                  if (_brandOverrideIntent != BrandOverrideIntent.none) ...[
                    const SizedBox(height: 8),
                    Text(
                      _brandOverrideIntentDescription(_brandOverrideIntent),
                      style: AppTypography.labelSmall.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
                if (showAffectedTargets) ...[
                  const SizedBox(height: 12),
                  _AffectedTargetsSelector(
                    palette: palette,
                    options: widget.childSpaceOptions,
                    selectedIds: _selectedTargetIds,
                    title: 'Target $affectedTargetLabel',
                    searchHint: 'Search $affectedTargetLabel',
                    emptySelectionMessage:
                        'Select one or more child $affectedTargetLabel for this override.',
                    unavailableMessage:
                        '${affectedTargetLabel[0].toUpperCase()}${affectedTargetLabel.substring(1)} list is unavailable in this context, so this override intent cannot be saved yet.',
                    noResultsMessage: 'No matching $affectedTargetLabel found.',
                    errorText: _targetSelectionError,
                    onChanged: (spaceId, selected) {
                      setState(() {
                        _targetSelectionError = null;
                        if (selected) {
                          _selectedTargetIds.add(spaceId);
                        } else {
                          _selectedTargetIds.remove(spaceId);
                        }
                      });
                    },
                    onSelectAll: widget.childSpaceOptions.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _targetSelectionError = null;
                              _selectedTargetIds
                                ..clear()
                                ..addAll(widget.childSpaceOptions
                                    .map((space) => space.id));
                            });
                          },
                    onClear: _selectedTargetIds.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedTargetIds.clear();
                              _targetSelectionError = null;
                            }),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Override reason',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildValueInput() {
    if (_valueType == ConfigValueType.boolean) {
      return DropdownButtonFormField<String>(
        initialValue: _boolValue,
        decoration: const InputDecoration(
          labelText: 'Value',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('True')),
          DropdownMenuItem(value: 'false', child: Text('False')),
        ],
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select value.' : null,
        onChanged: (value) => setState(() => _boolValue = value),
      );
    }

    return TextFormField(
      controller: _valueController,
      keyboardType: _valueType == ConfigValueType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: _valueType == ConfigValueType.string ? 3 : 1,
      decoration: InputDecoration(
        labelText: 'Value',
        hintText: _valueHint(_valueType),
        border: const OutlineInputBorder(),
      ),
      validator: _validateValue,
    );
  }

  String? _validateValue(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Please input value.';

    if (_valueType == ConfigValueType.number &&
        num.tryParse(normalized) == null) {
      return 'Please input a valid number.';
    }

    if (_valueType == ConfigValueType.dateTime &&
        DateTime.tryParse(normalized) == null) {
      return 'Please input an ISO date time.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiresTargetSelection) {
      if (_selectedTargetIds.isEmpty) {
        setState(() {
          final targetLabel =
              widget.scope == ConfigGovernanceScope.brand ? 'store' : 'space';
          _targetSelectionError = widget.childSpaceOptions.isEmpty
              ? 'No child ${targetLabel}s are available to target.'
              : 'Select at least one child $targetLabel for this override intent.';
        });
        return;
      }

      final confirmed = await _confirmOverrideIntent(context);
      if (!confirmed || !mounted) return;
    }

    final reason = _reasonController.text.trim();
    Navigator.of(context).pop(
      _ConfigValueEditResult(
        valueType: _valueType,
        value: _serializedValue(),
        brandOverrideIntent: widget.scope == ConfigGovernanceScope.brand
            ? _brandOverrideIntent
            : null,
        storeOverrideIntent: widget.scope == ConfigGovernanceScope.store
            ? _storeOverrideIntent
            : null,
        spaceOverrideIntent: widget.scope == ConfigGovernanceScope.space
            ? SpaceOverrideIntent.overrideAtSpace
            : null,
        overrideReason: reason.isEmpty ? null : reason,
        targetStoreIds: widget.scope == ConfigGovernanceScope.brand &&
                _brandOverrideIntent != BrandOverrideIntent.none
            ? _selectedTargetIds.toList(growable: false)
            : null,
        targetSpaceIds: widget.scope == ConfigGovernanceScope.store &&
                _storeOverrideIntent != StoreOverrideIntent.none
            ? _selectedTargetIds.toList(growable: false)
            : null,
      ),
    );
  }

  bool get _requiresTargetSelection {
    return (widget.scope == ConfigGovernanceScope.brand &&
            _brandOverrideIntent != BrandOverrideIntent.none) ||
        (widget.scope == ConfigGovernanceScope.store &&
            _storeOverrideIntent != StoreOverrideIntent.none);
  }

  Future<bool> _confirmOverrideIntent(BuildContext context) async {
    final selectedCount = _selectedTargetIds.length;
    final isBrand = widget.scope == ConfigGovernanceScope.brand;
    final targetSummary = isBrand
        ? 'This intent will target $selectedCount selected child store(s).'
        : 'This intent will target $selectedCount selected child space(s).';
    final title = isBrand
        ? _brandOverrideIntentLabel(_brandOverrideIntent)
        : _storeOverrideIntentLabel(_storeOverrideIntent);
    final description = isBrand
        ? _brandOverrideIntentDescription(_brandOverrideIntent)
        : _storeOverrideIntentDescription(_storeOverrideIntent);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          '$description\n\n$targetSummary',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result == true;
  }

  String _serializedValue() {
    if (_valueType == ConfigValueType.boolean) {
      return _boolValue ?? 'false';
    }
    final value = _valueController.text;
    return _valueType == ConfigValueType.string ? value : value.trim();
  }
}

class _AffectedTargetsSelector extends StatefulWidget {
  const _AffectedTargetsSelector({
    required this.palette,
    required this.options,
    required this.selectedIds,
    required this.title,
    required this.searchHint,
    required this.emptySelectionMessage,
    required this.unavailableMessage,
    required this.noResultsMessage,
    required this.onChanged,
    this.errorText,
    this.onSelectAll,
    this.onClear,
  });

  final _ConfigPalette palette;
  final List<ConfigAffectedSpaceOption> options;
  final Set<String> selectedIds;
  final String title;
  final String searchHint;
  final String emptySelectionMessage;
  final String unavailableMessage;
  final String noResultsMessage;
  final void Function(String spaceId, bool selected) onChanged;
  final String? errorText;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;

  @override
  State<_AffectedTargetsSelector> createState() =>
      _AffectedTargetsSelectorState();
}

class _AffectedTargetsSelectorState extends State<_AffectedTargetsSelector> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedIds.length;
    final query = _searchController.text.trim().toLowerCase();
    final sortedOptions = [...widget.options]..sort((left, right) {
        final leftSelected = widget.selectedIds.contains(left.id);
        final rightSelected = widget.selectedIds.contains(right.id);
        if (leftSelected != rightSelected) {
          return leftSelected ? -1 : 1;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    final filteredOptions = query.isEmpty
        ? sortedOptions
        : sortedOptions
            .where(
              (option) =>
                  option.name.toLowerCase().contains(query) ||
                  option.id.toLowerCase().contains(query),
            )
            .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: widget.palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onSelectAll,
                child: const Text('All'),
              ),
              TextButton(
                onPressed: widget.onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            selectedCount == 0
                ? widget.emptySelectionMessage
                : '$selectedCount of ${widget.options.length} selected.',
            style: AppTypography.labelSmall.copyWith(
              color: widget.palette.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (widget.options.length > 6) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodySmall.copyWith(
                color: widget.palette.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.searchHint,
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 16,
                  color: widget.palette.textMuted,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: widget.palette.textMuted,
                        ),
                        tooltip: 'Clear search',
                      ),
                filled: true,
                fillColor: widget.palette.sheet,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.palette.accent),
                ),
              ),
            ),
          ],
          if (widget.errorText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          if (widget.options.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.unavailableMessage,
              style: AppTypography.labelSmall.copyWith(
                color: widget.palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (filteredOptions.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.noResultsMessage,
              style: AppTypography.labelSmall.copyWith(
                color: widget.palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: SingleChildScrollView(
                child: Column(
                  children: filteredOptions
                      .map(
                        (space) => CheckboxListTile(
                          value: widget.selectedIds.contains(space.id),
                          onChanged: (selected) =>
                              widget.onChanged(space.id, selected == true),
                          title: Text(
                            space.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: widget.palette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            space.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: widget.palette.textMuted,
                            ),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: widget.palette.accent,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.palette,
    required this.message,
  });

  final _ConfigPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final _ConfigPalette palette;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: 12),
            Text(
              message ?? 'Config is unavailable right now.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.palette,
    required this.onRefresh,
  });

  final _ConfigPalette palette;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: palette.accent,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        children: [
          const SizedBox(height: 70),
          Icon(
            LucideIcons.fileSearch,
            color: palette.textMuted,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'No config rows found',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Map<ConfigDomain, List<ConfigFlatRow>> _groupRowsByDomain(
  List<ConfigFlatRow> rows,
) {
  final groups = <ConfigDomain, List<ConfigFlatRow>>{};
  for (final row in rows) {
    groups.putIfAbsent(row.domain, () => <ConfigFlatRow>[]).add(row);
  }
  return groups;
}

String _domainLabel(ConfigDomain domain) {
  switch (domain) {
    case ConfigDomain.ops:
      return 'Ops';
    case ConfigDomain.playback:
      return 'Playback';
    case ConfigDomain.fuzzy:
      return 'Fuzzy';
    case ConfigDomain.content:
      return 'Content';
    case ConfigDomain.governance:
      return 'Governance';
    case ConfigDomain.scheduling:
      return 'Scheduling';
    case ConfigDomain.cams:
      return 'CAMS';
    case ConfigDomain.sys:
      return 'System';
    case ConfigDomain.unknown:
      return 'Unknown';
  }
}

Color _domainColor(ConfigDomain domain) {
  switch (domain) {
    case ConfigDomain.ops:
      return AppColors.info;
    case ConfigDomain.playback:
      return AppColors.success;
    case ConfigDomain.fuzzy:
      return AppColors.warning;
    case ConfigDomain.content:
      return AppColors.secondaryTeal;
    case ConfigDomain.governance:
      return AppColors.primaryOrangeDark;
    case ConfigDomain.scheduling:
      return AppColors.upliftingColor;
    case ConfigDomain.cams:
      return AppColors.primaryCyan;
    case ConfigDomain.sys:
      return AppColors.textTertiary;
    case ConfigDomain.unknown:
      return AppColors.borderDark;
  }
}

String _scopeLabel(ConfigScopeType scope) {
  switch (scope) {
    case ConfigScopeType.system:
      return 'System';
    case ConfigScopeType.brand:
      return 'Brand';
    case ConfigScopeType.store:
      return 'Store';
    case ConfigScopeType.space:
      return 'Space';
    case ConfigScopeType.unknown:
      return 'Unknown';
  }
}

String _scopeShortLabel(ConfigGovernanceScope scope) {
  switch (scope) {
    case ConfigGovernanceScope.brand:
      return 'Brand scope';
    case ConfigGovernanceScope.store:
      return 'Store scope';
    case ConfigGovernanceScope.space:
      return 'Space scope';
  }
}

IconData _scopeHeaderIcon(ConfigGovernanceScope scope) {
  switch (scope) {
    case ConfigGovernanceScope.brand:
      return LucideIcons.building2;
    case ConfigGovernanceScope.store:
      return LucideIcons.store;
    case ConfigGovernanceScope.space:
      return LucideIcons.layoutPanelTop;
  }
}

String _valueTypeLabel(ConfigValueType type) {
  switch (type) {
    case ConfigValueType.string:
      return 'String';
    case ConfigValueType.number:
      return 'Number';
    case ConfigValueType.boolean:
      return 'Boolean';
    case ConfigValueType.dateTime:
      return 'Date time';
    case ConfigValueType.unknown:
      return 'Unknown';
  }
}

String _brandOverrideIntentLabel(BrandOverrideIntent intent) {
  switch (intent) {
    case BrandOverrideIntent.none:
      return 'No override intent';
    case BrandOverrideIntent.allowStoreOverride:
      return 'Allow store override';
    case BrandOverrideIntent.forceInheritToAllChildren:
      return 'Force inherit to child stores';
  }
}

String _brandOverrideIntentDescription(BrandOverrideIntent intent) {
  switch (intent) {
    case BrandOverrideIntent.none:
      return 'Only this brand value will be updated.';
    case BrandOverrideIntent.allowStoreOverride:
      return 'Selected child stores can override this key after the brand value is saved.';
    case BrandOverrideIntent.forceInheritToAllChildren:
      return 'Selected child stores will inherit this brand value after this save.';
  }
}

String _storeOverrideIntentLabel(StoreOverrideIntent intent) {
  switch (intent) {
    case StoreOverrideIntent.none:
      return 'No override intent';
    case StoreOverrideIntent.allowSpaceOverride:
      return 'Allow space override';
    case StoreOverrideIntent.forceInheritToAllSpaces:
      return 'Force inherit to child spaces';
  }
}

String _storeOverrideIntentDescription(StoreOverrideIntent intent) {
  switch (intent) {
    case StoreOverrideIntent.none:
      return 'Only this store value will be updated.';
    case StoreOverrideIntent.allowSpaceOverride:
      return 'Child spaces can override this key after this store value is saved.';
    case StoreOverrideIntent.forceInheritToAllSpaces:
      return 'Child spaces will inherit this store value after this save.';
  }
}

String _tierLabel(ConfigTier tier) {
  switch (tier) {
    case ConfigTier.system:
      return 'System tier';
    case ConfigTier.tenant:
      return 'Tenant tier';
    case ConfigTier.unknown:
      return 'Unknown tier';
  }
}

String _valueText(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return 'Not set';
  return normalized;
}

String? _overrideLabel(ConfigFlatRow row) {
  if (!row.hasBrandOverrideGate) return null;
  if (row.isSpaceOverrideAllowed) return 'Space override';
  if (row.isStoreOverrideAllowed) return 'Store override';
  return 'Brand locked';
}

Color _overrideColor(ConfigFlatRow row) {
  if (row.isSpaceOverrideAllowed || row.isStoreOverrideAllowed) {
    return AppColors.success;
  }
  return AppColors.warning;
}

String? _editBlockReason(
  ConfigFlatRow row,
  ConfigGovernanceScope scope,
) {
  if (row.policyTier == ConfigTier.system) {
    return 'System-tier config cannot be edited here.';
  }

  if (scope == ConfigGovernanceScope.brand &&
      isConfigKeyBrandBlocked(row.key)) {
    return 'This key cannot be edited at brand scope.';
  }

  if (scope == ConfigGovernanceScope.store && !row.isStoreOverrideAllowed) {
    return row.brandLockReason?.trim().isNotEmpty == true
        ? row.brandLockReason
        : 'Parent policy has not allowed store override.';
  }

  if (scope == ConfigGovernanceScope.store &&
      isConfigKeyStoreBlocked(row.key)) {
    return 'Use the dedicated governance mode action for this key.';
  }

  if (scope == ConfigGovernanceScope.space) {
    if (_isSpaceWriteBlocked(row)) {
      return 'This key cannot be edited at space scope.';
    }
    if (!row.isSpaceOverrideAllowed) {
      return row.brandLockReason?.trim().isNotEmpty == true
          ? row.brandLockReason
          : 'Parent policy has not allowed space override.';
    }
  }

  return null;
}

bool _isSpaceWriteBlocked(ConfigFlatRow row) {
  return isConfigKeySpaceBlocked(row.key, row.domain);
}

IconData _configKeyIcon(String key, ConfigDomain domain) {
  if (key.contains('volume')) return Icons.volume_up_outlined;
  if (key.contains('playlist')) return Icons.queue_music_outlined;
  if (key.contains('schedule') || domain == ConfigDomain.scheduling) {
    return Icons.calendar_month_outlined;
  }
  if (key.contains('time') || domain == ConfigDomain.ops) {
    return Icons.access_time_outlined;
  }
  if (key.contains('copyright')) return Icons.copyright_outlined;
  if (key.contains('ai') || domain == ConfigDomain.cams) {
    return Icons.smart_toy_outlined;
  }
  if (domain == ConfigDomain.governance) return Icons.verified_user_outlined;
  if (domain == ConfigDomain.fuzzy) return Icons.tune_rounded;
  if (domain == ConfigDomain.content) return Icons.library_music_outlined;
  return Icons.settings_outlined;
}

ConfigValueType _initialEditorValueType(ConfigFlatRow row) {
  if (row.valueType != ConfigValueType.unknown) return row.valueType;
  final defaultType = row.policyDefaultValueType;
  if (defaultType != null && defaultType != ConfigValueType.unknown) {
    return defaultType;
  }
  return ConfigValueType.string;
}

String _initialEditorValue(ConfigFlatRow row) {
  final value = row.value?.trim();
  if (value != null && value.isNotEmpty) return value;

  final defaultValue = row.policyDefaultValue?.trim();
  if (defaultValue != null && defaultValue.isNotEmpty) return defaultValue;

  return '';
}

String? _normalizeBoolValue(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'true') return 'true';
  if (normalized == 'false') return 'false';
  return null;
}

String _valueHint(ConfigValueType valueType) {
  switch (valueType) {
    case ConfigValueType.number:
      return '65';
    case ConfigValueType.dateTime:
      return DateTime.now().toUtc().toIso8601String();
    case ConfigValueType.string:
      return 'Enter config value';
    case ConfigValueType.boolean:
    case ConfigValueType.unknown:
      return '';
  }
}

class _ConfigPalette {
  const _ConfigPalette({
    required this.isDark,
    required this.sheet,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  final bool isDark;
  final Color sheet;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  factory _ConfigPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ConfigPalette(
      isDark: isDark,
      sheet: isDark ? AppColors.surfaceDark : AppColors.surface,
      panel:
          isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundPrimary,
      border: isDark ? AppColors.borderDarkLight : AppColors.borderLight,
      textPrimary: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      textMuted: isDark ? AppColors.textDarkSecondary : AppColors.textTertiary,
      accent: isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
    );
  }
}
