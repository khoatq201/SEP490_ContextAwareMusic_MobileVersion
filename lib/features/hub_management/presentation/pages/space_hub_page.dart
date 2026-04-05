import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/ble_candidate.dart';
import '../../domain/entities/space_hub_binding.dart';
import '../../domain/entities/wifi_candidate.dart';
import '../bloc/hub_provisioning_bloc.dart';
import '../bloc/hub_provisioning_event.dart';
import '../bloc/hub_provisioning_state.dart';

String buildSpaceHubLocation({
  required String spaceId,
  required String storeId,
  required String spaceName,
}) {
  return Uri(
    path: '/space-hub',
    queryParameters: {
      'spaceId': spaceId,
      'storeId': storeId,
      'spaceName': spaceName,
    },
  ).toString();
}

class SpaceHubPage extends StatefulWidget {
  const SpaceHubPage({
    super.key,
    required this.spaceId,
    required this.storeId,
    required this.spaceName,
  });

  final String spaceId;
  final String storeId;
  final String spaceName;

  @override
  State<SpaceHubPage> createState() => _SpaceHubPageState();
}

class _SpaceHubPageState extends State<SpaceHubPage> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HubPalette.of(context);

    return BlocBuilder<HubProvisioningBloc, HubProvisioningState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: palette.bg,
          appBar: AppBar(
            backgroundColor: palette.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
              onPressed: () =>
                  Navigator.of(context).pop(state.didMutateBinding),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IoT Hub & Wi-Fi',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.spaceName,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              if (state.message != null &&
                  state.message!.trim().isNotEmpty) ...[
                _MessageBanner(
                  message: state.message!,
                  palette: palette,
                  isError: state.phase == HubProvisioningPhase.failure,
                  isWarning: state.binding?.isSyncPending ?? false,
                ),
                const SizedBox(height: 16),
              ],
              _SpaceContextCard(
                palette: palette,
                storeId: widget.storeId,
                spaceId: widget.spaceId,
                prefixHint: 'CAM',
              ),
              const SizedBox(height: 16),
              if (state.binding != null) ...[
                _BindingCard(binding: state.binding!, palette: palette),
                const SizedBox(height: 16),
              ],
              ..._buildPhaseContent(context, state, palette),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPhaseContent(
    BuildContext context,
    HubProvisioningState state,
    _HubPalette palette,
  ) {
    switch (state.phase) {
      case HubProvisioningPhase.loading:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Loading hub state',
            subtitle: 'Checking the saved binding for this space.',
          ),
        ];
      case HubProvisioningPhase.permissionRequired:
        return [
          _PermissionCard(
            palette: palette,
            isPermanentlyDenied: state.isPermissionPermanentlyDenied,
            onGrant: () {
              if (state.isPermissionPermanentlyDenied) {
                openAppSettings();
                return;
              }
              context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningPermissionRequested());
            },
          ),
          const SizedBox(height: 16),
          _StartProvisioningCard(
            palette: palette,
            title: state.binding == null
                ? 'No hub configured yet'
                : 'Permissions are needed to reconfigure the hub',
            description:
                'BLE scan, Wi-Fi discovery, and provisioning all require Android Bluetooth permissions.',
            ctaLabel: state.isPermissionPermanentlyDenied
                ? 'Open app settings'
                : 'Grant permissions',
            onTap: () {
              if (state.isPermissionPermanentlyDenied) {
                openAppSettings();
                return;
              }
              context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningPermissionRequested());
            },
          ),
        ];
      case HubProvisioningPhase.scanningBle:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Scanning for CAM devices',
            subtitle:
                'Make sure the ESP32 is powered on and advertising provisioning over BLE.',
          ),
        ];
      case HubProvisioningPhase.selectDevice:
        return [
          _BleCandidatesCard(
            palette: palette,
            candidates: state.bleCandidates,
            onRescan: () => context
                .read<HubProvisioningBloc>()
                .add(const HubProvisioningBleScanRequested()),
            onSelected: (candidate) => context
                .read<HubProvisioningBloc>()
                .add(HubProvisioningBleCandidateSelected(candidate)),
          ),
          const SizedBox(height: 16),
          if (state.binding != null)
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested()),
              onRetrySync: state.binding!.isSyncPending
                  ? () => context
                      .read<HubProvisioningBloc>()
                      .add(const HubProvisioningRetrySyncRequested())
                  : null,
              onRestart: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningRestartRequested()),
              onDelete: () => _confirmDeleteBinding(context),
            ),
        ];
      case HubProvisioningPhase.scanningWifi:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Reading Wi-Fi networks from ESP32',
            subtitle: state.selectedBleCandidate == null
                ? 'Connecting to the selected CAM device.'
                : 'Selected device: ${state.selectedBleCandidate!.displayName}',
          ),
        ];
      case HubProvisioningPhase.enterWifi:
        return [
          _WifiFormCard(
            palette: palette,
            device: state.selectedBleCandidate,
            wifiCandidates: state.wifiCandidates,
            ssidController: _ssidController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            onWifiSelected: (candidate) =>
                _ssidController.text = candidate.ssid,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onBackToScan: () {
              context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested());
            },
            onSubmit: () => _submitCredentials(context),
          ),
        ];
      case HubProvisioningPhase.provisioning:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Sending Wi-Fi credentials',
            subtitle:
                'The ESP32 is attempting to join ${_ssidController.text.trim().isEmpty ? 'the selected Wi-Fi network' : _ssidController.text.trim()}.',
          ),
        ];
      case HubProvisioningPhase.syncing:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Syncing hub binding',
            subtitle:
                'Saving the space-to-ESP relationship to the backend-style stub.',
          ),
        ];
      case HubProvisioningPhase.success:
        return [
          if (state.binding == null)
            _StartProvisioningCard(
              palette: palette,
              title: 'No hub configured yet',
              description:
                  'Start BLE provisioning to connect an ESP32 to this space and send it Wi-Fi credentials.',
              ctaLabel: 'Scan CAM devices',
              onTap: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested()),
            )
          else
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested()),
              onRetrySync: state.binding!.isSyncPending
                  ? () => context
                      .read<HubProvisioningBloc>()
                      .add(const HubProvisioningRetrySyncRequested())
                  : null,
              onRestart: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningRestartRequested()),
              onDelete: () => _confirmDeleteBinding(context),
            ),
        ];
      case HubProvisioningPhase.failure:
        return [
          if (state.binding == null)
            _StartProvisioningCard(
              palette: palette,
              title: 'Provisioning needs another try',
              description:
                  'Retry the CAM scan, or re-open Android settings if Bluetooth permissions were denied.',
              ctaLabel: 'Try again',
              onTap: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested()),
            )
          else
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningBleScanRequested()),
              onRetrySync: state.binding!.isSyncPending
                  ? () => context
                      .read<HubProvisioningBloc>()
                      .add(const HubProvisioningRetrySyncRequested())
                  : null,
              onRestart: () => context
                  .read<HubProvisioningBloc>()
                  .add(const HubProvisioningRestartRequested()),
              onDelete: () => _confirmDeleteBinding(context),
            ),
        ];
    }
  }

  Future<void> _confirmDeleteBinding(BuildContext context) async {
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove hub binding?'),
        content: const Text(
          'This removes the current ESP32 assignment from the space. It does not resend Wi-Fi credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (didConfirm != true || !context.mounted) return;
    context
        .read<HubProvisioningBloc>()
        .add(const HubProvisioningDeleteBindingRequested());
  }

  void _submitCredentials(BuildContext context) {
    final ssid = _ssidController.text.trim();
    final passphrase = _passwordController.text;
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Choose or enter an SSID before sending Wi-Fi credentials.'),
        ),
      );
      return;
    }

    if (passphrase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the Wi-Fi password before continuing.'),
        ),
      );
      return;
    }

    context.read<HubProvisioningBloc>().add(
          HubProvisioningCredentialsSubmitted(
            ssid: ssid,
            passphrase: passphrase,
          ),
        );
  }
}

class _SpaceContextCard extends StatelessWidget {
  const _SpaceContextCard({
    required this.palette,
    required this.storeId,
    required this.spaceId,
    required this.prefixHint,
  });

  final _HubPalette palette;
  final String storeId;
  final String spaceId;
  final String prefixHint;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provisioning context',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.bluetooth,
            label: 'BLE prefix',
            value: prefixHint,
          ),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.store,
            label: 'Store',
            value: storeId,
          ),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.squareStack,
            label: 'Space',
            value: spaceId,
          ),
        ],
      ),
    );
  }
}

class _BindingCard extends StatelessWidget {
  const _BindingCard({
    required this.binding,
    required this.palette,
  });

  final SpaceHubBinding binding;
  final _HubPalette palette;

  @override
  Widget build(BuildContext context) {
    final statusColor = binding.isBound
        ? AppColors.success
        : binding.isSyncPending
            ? AppColors.warning
            : AppColors.error;

    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  binding.isBound
                      ? LucideIcons.router
                      : binding.isSyncPending
                          ? Icons.cloud_sync_outlined
                          : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current hub binding',
                      style: GoogleFonts.poppins(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      binding.status.displayLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.badgeInfo,
            label: 'ESP32 device',
            value: binding.bleDeviceName,
          ),
          _InfoRow(
            palette: palette,
            icon: Icons.wifi_outlined,
            label: 'Wi-Fi',
            value: binding.wifiSsid,
          ),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.clock3,
            label: 'Provisioned at',
            value: _formatDateTime(binding.provisionedAtUtc),
          ),
          _InfoRow(
            palette: palette,
            icon: LucideIcons.shieldCheck,
            label: 'Method',
            value: binding.provisioningMethod.apiValue,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.palette,
    required this.isPermanentlyDenied,
    required this.onGrant,
  });

  final _HubPalette palette;
  final bool isPermanentlyDenied;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android BLE permissions required',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermanentlyDenied
                ? 'Bluetooth access was denied permanently. Open Android settings and allow Bluetooth scan/connect before trying again.'
                : 'Bluetooth scan and connect permissions are needed to find CAM devices and send Wi-Fi credentials to ESP32 over BLE.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGrant,
            icon: Icon(
              isPermanentlyDenied
                  ? LucideIcons.externalLink
                  : LucideIcons.shield,
              size: 18,
            ),
            label: Text(
              isPermanentlyDenied ? 'Open app settings' : 'Grant permissions',
            ),
          ),
        ],
      ),
    );
  }
}

class _StartProvisioningCard extends StatelessWidget {
  const _StartProvisioningCard({
    required this.palette,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onTap,
  });

  final _HubPalette palette;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
            label: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _BleCandidatesCard extends StatelessWidget {
  const _BleCandidatesCard({
    required this.palette,
    required this.candidates,
    required this.onRescan,
    required this.onSelected,
  });

  final _HubPalette palette;
  final List<BleCandidate> candidates;
  final VoidCallback onRescan;
  final ValueChanged<BleCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select a CAM device',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRescan,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Rescan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (candidates.isEmpty)
            Text(
              'No BLE devices matched the CAM prefix during the last scan.',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 13,
              ),
            )
          else
            ...candidates.map(
              (candidate) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(candidate),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.panel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bluetooth_outlined,
                            color: palette.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.displayName,
                                style: GoogleFonts.inter(
                                  color: palette.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                candidate.bleDeviceName,
                                style: GoogleFonts.inter(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: palette.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WifiFormCard extends StatelessWidget {
  const _WifiFormCard({
    required this.palette,
    required this.device,
    required this.wifiCandidates,
    required this.ssidController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onWifiSelected,
    required this.onTogglePassword,
    required this.onBackToScan,
    required this.onSubmit,
  });

  final _HubPalette palette;
  final BleCandidate? device;
  final List<WifiCandidate> wifiCandidates;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final ValueChanged<WifiCandidate> onWifiSelected;
  final VoidCallback onTogglePassword;
  final VoidCallback onBackToScan;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Configure Wi-Fi',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onBackToScan,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Change ESP'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (device != null)
            Text(
              'Selected device: ${device!.displayName}',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (wifiCandidates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Networks seen by ESP32',
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wifiCandidates
                  .map(
                    (candidate) => ActionChip(
                      label: Text(candidate.ssid),
                      onPressed: () => onWifiSelected(candidate),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: ssidController,
            decoration: const InputDecoration(
              labelText: 'Wi-Fi SSID',
              hintText: 'Choose from scan or type manually',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Wi-Fi password',
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: const Text('Send credentials to ESP32'),
          ),
        ],
      ),
    );
  }
}

class _BindingActions extends StatelessWidget {
  const _BindingActions({
    required this.palette,
    required this.binding,
    required this.onRescan,
    required this.onRetrySync,
    required this.onRestart,
    required this.onDelete,
  });

  final _HubPalette palette;
  final SpaceHubBinding? binding;
  final VoidCallback onRescan;
  final VoidCallback? onRetrySync;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onRescan,
                icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                label:
                    Text(binding == null ? 'Start scan' : 'Reconfigure Wi-Fi'),
              ),
              if (onRetrySync != null)
                OutlinedButton.icon(
                  onPressed: onRetrySync,
                  icon: const Icon(LucideIcons.cloudCog, size: 18),
                  label: const Text('Retry sync'),
                ),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Restart hub'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.unlink, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                label: const Text('Unbind'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.palette,
    required this.title,
    required this.subtitle,
  });

  final _HubPalette palette;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.palette,
    this.isError = false,
    this.isWarning = false,
  });

  final String message;
  final _HubPalette palette;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? AppColors.error
        : isWarning
            ? AppColors.warning
            : palette.accent;
    final icon = isError
        ? Icons.warning_amber_rounded
        : isWarning
            ? Icons.cloud_sync_outlined
            : LucideIcons.badgeInfo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.child,
  });

  final _HubPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  final _HubPalette palette;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubPalette {
  const _HubPalette({
    required this.bg,
    required this.card,
    required this.panel,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  final Color bg;
  final Color card;
  final Color panel;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  factory _HubPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HubPalette(
      bg: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      card: isDark ? AppColors.surfaceDark : Colors.white,
      panel: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.78)
          : AppColors.backgroundPrimary,
      border: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.divider,
      textPrimary: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      textMuted: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
      accent: isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
    );
  }
}
