import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/app_error_presentation.dart';
import '../../../../core/widgets/app_status_banner.dart';
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
  final _pageScrollController = ScrollController();
  final _secretCodeController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nvrUsernameController = TextEditingController(text: 'admin');
  final _nvrPasswordController = TextEditingController();
  final _nvrHostController = TextEditingController();
  final _nvrPortController = TextEditingController(text: '80');
  final _nvrChannelController = TextEditingController(text: '1');
  final _secretCodeFocusNode = FocusNode();
  final _ssidFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nvrUsernameFocusNode = FocusNode();
  final _nvrPasswordFocusNode = FocusNode();
  final _nvrHostFocusNode = FocusNode();
  final _nvrPortFocusNode = FocusNode();
  final _nvrChannelFocusNode = FocusNode();
  final _secretCodeFieldKey = GlobalKey();
  final _ssidFieldKey = GlobalKey();
  final _passwordFieldKey = GlobalKey();
  final _nvrUsernameFieldKey = GlobalKey();
  final _nvrPasswordFieldKey = GlobalKey();
  final _nvrHostFieldKey = GlobalKey();
  final _nvrPortFieldKey = GlobalKey();
  final _nvrChannelFieldKey = GlobalKey();
  bool _obscureSecretCode = true;
  bool _obscurePassword = true;
  bool _obscureNvrPassword = true;
  bool _useDirectNvr = false;

  @override
  void initState() {
    super.initState();
    _attachFocusListener(_secretCodeFocusNode, _secretCodeFieldKey);
    _attachFocusListener(_ssidFocusNode, _ssidFieldKey);
    _attachFocusListener(_passwordFocusNode, _passwordFieldKey);
    _attachFocusListener(_nvrUsernameFocusNode, _nvrUsernameFieldKey);
    _attachFocusListener(_nvrPasswordFocusNode, _nvrPasswordFieldKey);
    _attachFocusListener(_nvrHostFocusNode, _nvrHostFieldKey);
    _attachFocusListener(_nvrPortFocusNode, _nvrPortFieldKey);
    _attachFocusListener(_nvrChannelFocusNode, _nvrChannelFieldKey);
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _secretCodeController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _nvrUsernameController.dispose();
    _nvrPasswordController.dispose();
    _nvrHostController.dispose();
    _nvrPortController.dispose();
    _nvrChannelController.dispose();
    _secretCodeFocusNode.dispose();
    _ssidFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nvrUsernameFocusNode.dispose();
    _nvrPasswordFocusNode.dispose();
    _nvrHostFocusNode.dispose();
    _nvrPortFocusNode.dispose();
    _nvrChannelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HubPalette.of(context);

    return BlocBuilder<HubProvisioningBloc, HubProvisioningState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: palette.bg,
          resizeToAvoidBottomInset: false,
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
          body: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ListView(
              controller: _pageScrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              children: [
                if (state.message != null &&
                    state.message!.trim().isNotEmpty) ...[
                  AppStatusBanner(
                    title: state.phase == HubProvisioningPhase.failure
                        ? 'Setup needs attention'
                        : (state.binding?.isSyncPending ?? false)
                            ? 'Sync pending'
                            : 'Hub status',
                    message: state.message!,
                    tone: state.phase == HubProvisioningPhase.failure
                        ? AppStatusTone.error
                        : (state.binding?.isSyncPending ?? false)
                            ? AppStatusTone.warning
                            : AppStatusTone.info,
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
            onRescan: () => _startBleScan(context, state),
            onSelected: (candidate) => _selectBleCandidate(context, candidate),
          ),
          const SizedBox(height: 16),
          if (state.binding != null)
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => _startBleScan(
                context,
                state,
                flowMode: HubProvisioningFlowMode.fullProvisioning,
              ),
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
      case HubProvisioningPhase.enterSecretCode:
        return [
          _SecretCodeCard(
            palette: palette,
            device: state.selectedBleCandidate,
            secretCodeFieldKey: _secretCodeFieldKey,
            secretCodeController: _secretCodeController,
            secretCodeFocusNode: _secretCodeFocusNode,
            obscureSecretCode: _obscureSecretCode,
            onToggleSecretCode: () {
              setState(() => _obscureSecretCode = !_obscureSecretCode);
            },
            onChooseDifferentDevice: () => _startBleScan(context, state),
            onSubmit: () => _submitSecretCode(context),
          ),
        ];
      case HubProvisioningPhase.scanningWifi:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Checking secret code and reading Wi-Fi',
            subtitle: state.selectedBleCandidate == null
                ? 'Authenticating with the selected CAM device.'
                : 'Selected device: ${state.selectedBleCandidate!.displayName}',
          ),
        ];
      case HubProvisioningPhase.enterWifi:
        return [
          _WifiFormCard(
            palette: palette,
            device: state.selectedBleCandidate,
            wifiCandidates: state.wifiCandidates,
            ssidFieldKey: _ssidFieldKey,
            ssidController: _ssidController,
            ssidFocusNode: _ssidFocusNode,
            passwordFieldKey: _passwordFieldKey,
            passwordController: _passwordController,
            passwordFocusNode: _passwordFocusNode,
            obscurePassword: _obscurePassword,
            onWifiSelected: (candidate) =>
                _ssidController.text = candidate.ssid,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onBackToScan: () => _startBleScan(
              context,
              state,
              flowMode: HubProvisioningFlowMode.fullProvisioning,
            ),
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
      case HubProvisioningPhase.enterNvrConfig:
        return [
          _NvrConfigCard(
            palette: palette,
            deviceId: state.resolvedIdentity?.deviceId,
            useDirectNvr: _useDirectNvr,
            usernameFieldKey: _nvrUsernameFieldKey,
            usernameController: _nvrUsernameController,
            usernameFocusNode: _nvrUsernameFocusNode,
            passwordFieldKey: _nvrPasswordFieldKey,
            passwordController: _nvrPasswordController,
            passwordFocusNode: _nvrPasswordFocusNode,
            hostFieldKey: _nvrHostFieldKey,
            hostController: _nvrHostController,
            hostFocusNode: _nvrHostFocusNode,
            portFieldKey: _nvrPortFieldKey,
            portController: _nvrPortController,
            portFocusNode: _nvrPortFocusNode,
            obscurePassword: _obscureNvrPassword,
            onToggleDirectMode: (value) {
              setState(() => _useDirectNvr = value);
            },
            onTogglePassword: () {
              setState(() => _obscureNvrPassword = !_obscureNvrPassword);
            },
            onSubmit: () => _submitNvrConfig(context),
          ),
        ];
      case HubProvisioningPhase.sendingNvrConfig:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Sending NVR and Wi-Fi configuration',
            subtitle:
                'The ESP32 is storing the NVR source and Wi-Fi credentials, then joining the selected network.',
          ),
        ];
      case HubProvisioningPhase.discoveringNvrChannels:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Discovering camera views',
            subtitle:
                'The ESP32 is connecting to Wi-Fi, finding the NVR, and preparing preview snapshots for each channel.',
          ),
        ];
      case HubProvisioningPhase.selectNvrChannel:
        return [
          _NvrChannelPickerCard(
            palette: palette,
            channels: state.nvrChannels,
            onRefresh: () => context
                .read<HubProvisioningBloc>()
                .add(const HubProvisioningNvrChannelsRefreshRequested()),
            onSelected: (channel) => context
                .read<HubProvisioningBloc>()
                .add(HubProvisioningNvrChannelSelected(
                  selectedChannel: channel,
                )),
          ),
        ];
      case HubProvisioningPhase.sendingNvrChannelSelection:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Saving selected camera view',
            subtitle:
                'The ESP32 will use this channel for snapshots and people counting.',
          ),
        ];
      case HubProvisioningPhase.resolvingLocation:
      case HubProvisioningPhase.reviewLocation:
      case HubProvisioningPhase.sendingLocation:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Finalizing Wi-Fi setup',
            subtitle: 'Preparing the hub binding for this space.',
          ),
        ];
      case HubProvisioningPhase.syncing:
        return [
          _ProgressCard(
            palette: palette,
            title: 'Syncing hub binding',
            subtitle: 'Saving the hub relationship to the backend-style stub.',
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
              onTap: () => _startBleScan(
                context,
                state,
                flowMode: HubProvisioningFlowMode.fullProvisioning,
              ),
            )
          else
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => _startBleScan(
                context,
                state,
                flowMode: HubProvisioningFlowMode.fullProvisioning,
              ),
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
              onTap: () => _startBleScan(
                context,
                state,
                flowMode: HubProvisioningFlowMode.fullProvisioning,
              ),
            )
          else
            _BindingActions(
              palette: palette,
              binding: state.binding,
              onRescan: () => _startBleScan(
                context,
                state,
                flowMode: HubProvisioningFlowMode.fullProvisioning,
              ),
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

  void _attachFocusListener(FocusNode focusNode, GlobalKey fieldKey) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final fieldContext = fieldKey.currentContext;
        if (fieldContext == null) return;
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.22,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  void _startBleScan(
    BuildContext context,
    HubProvisioningState state, {
    HubProvisioningFlowMode? flowMode,
  }) {
    _secretCodeController.clear();
    _ssidController.clear();
    _passwordController.clear();
    _nvrUsernameController.text = 'admin';
    _nvrPasswordController.clear();
    _nvrHostController.clear();
    _nvrPortController.text = '80';
    _nvrChannelController.text = '1';
    setState(() {
      _obscureSecretCode = true;
      _obscurePassword = true;
      _obscureNvrPassword = true;
      _useDirectNvr = false;
    });
    context.read<HubProvisioningBloc>().add(
          HubProvisioningBleScanRequested(
            flowMode: flowMode ?? state.flowMode,
          ),
        );
  }

  void _selectBleCandidate(BuildContext context, BleCandidate candidate) {
    _secretCodeController.clear();
    _ssidController.clear();
    _passwordController.clear();
    _nvrUsernameController.text = 'admin';
    _nvrPasswordController.clear();
    _nvrHostController.clear();
    _nvrPortController.text = '80';
    _nvrChannelController.text = '1';
    setState(() {
      _obscureSecretCode = true;
      _obscurePassword = true;
      _obscureNvrPassword = true;
      _useDirectNvr = false;
    });
    context
        .read<HubProvisioningBloc>()
        .add(HubProvisioningBleCandidateSelected(candidate));
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

  void _submitSecretCode(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<HubProvisioningBloc>().add(
          HubProvisioningSecretCodeSubmitted(
            secretCode: _secretCodeController.text.trim(),
          ),
        );
  }

  void _submitCredentials(BuildContext context) {
    FocusScope.of(context).unfocus();
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

  void _submitNvrConfig(BuildContext context) {
    FocusScope.of(context).unfocus();
    final username = _nvrUsernameController.text.trim();
    final password = _nvrPasswordController.text;
    final host = _nvrHostController.text.trim();
    final port = int.tryParse(_nvrPortController.text.trim()) ?? 80;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the NVR username and password.'),
        ),
      );
      return;
    }

    if (_useDirectNvr && host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the direct NVR host or forwarded router IP.'),
        ),
      );
      return;
    }

    context.read<HubProvisioningBloc>().add(
          HubProvisioningNvrConfigSubmitted(
            mode: _useDirectNvr ? 'direct' : 'auto',
            username: username,
            password: password,
            host: host,
            port: port,
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

class _SecretCodeCard extends StatelessWidget {
  const _SecretCodeCard({
    required this.palette,
    required this.device,
    required this.secretCodeFieldKey,
    required this.secretCodeController,
    required this.secretCodeFocusNode,
    required this.obscureSecretCode,
    required this.onToggleSecretCode,
    required this.onChooseDifferentDevice,
    required this.onSubmit,
  });

  final _HubPalette palette;
  final BleCandidate? device;
  final GlobalKey secretCodeFieldKey;
  final TextEditingController secretCodeController;
  final FocusNode secretCodeFocusNode;
  final bool obscureSecretCode;
  final VoidCallback onToggleSecretCode;
  final VoidCallback onChooseDifferentDevice;
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
                  'Enter secret code',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onChooseDifferentDevice,
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
          const SizedBox(height: 12),
          Text(
            'Enter the provisioning secret code for this ESP32. It is used as the proof of possession and is never saved after provisioning.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            key: secretCodeFieldKey,
            child: TextField(
              controller: secretCodeController,
              focusNode: secretCodeFocusNode,
              obscureText: obscureSecretCode,
              textInputAction: TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Secret code',
                hintText: 'Enter PoP / provisioning code',
                suffixIcon: IconButton(
                  onPressed: onToggleSecretCode,
                  icon: Icon(
                    obscureSecretCode ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(LucideIcons.keyRound, size: 18),
            label: const Text('Read Wi-Fi from ESP32'),
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
    required this.ssidFieldKey,
    required this.ssidController,
    required this.ssidFocusNode,
    required this.passwordFieldKey,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onWifiSelected,
    required this.onTogglePassword,
    required this.onBackToScan,
    required this.onSubmit,
  });

  final _HubPalette palette;
  final BleCandidate? device;
  final List<WifiCandidate> wifiCandidates;
  final GlobalKey ssidFieldKey;
  final TextEditingController ssidController;
  final FocusNode ssidFocusNode;
  final GlobalKey passwordFieldKey;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
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
          Container(
            key: ssidFieldKey,
            child: TextField(
              controller: ssidController,
              focusNode: ssidFocusNode,
              textInputAction: TextInputAction.next,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              decoration: const InputDecoration(
                labelText: 'Wi-Fi SSID',
                hintText: 'Choose from scan or type manually',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: passwordFieldKey,
            child: TextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              onSubmitted: (_) => onSubmit(),
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

class _NvrConfigCard extends StatelessWidget {
  const _NvrConfigCard({
    required this.palette,
    required this.deviceId,
    required this.useDirectNvr,
    required this.usernameFieldKey,
    required this.usernameController,
    required this.usernameFocusNode,
    required this.passwordFieldKey,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.hostFieldKey,
    required this.hostController,
    required this.hostFocusNode,
    required this.portFieldKey,
    required this.portController,
    required this.portFocusNode,
    required this.obscurePassword,
    required this.onToggleDirectMode,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final _HubPalette palette;
  final String? deviceId;
  final bool useDirectNvr;
  final GlobalKey usernameFieldKey;
  final TextEditingController usernameController;
  final FocusNode usernameFocusNode;
  final GlobalKey passwordFieldKey;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final GlobalKey hostFieldKey;
  final TextEditingController hostController;
  final FocusNode hostFocusNode;
  final GlobalKey portFieldKey;
  final TextEditingController portController;
  final FocusNode portFocusNode;
  final bool obscurePassword;
  final ValueChanged<bool> onToggleDirectMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure NVR source',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Device ID: ${deviceId ?? 'unknown'}',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            useDirectNvr
                ? 'Direct mode uses the host and port you enter, then shows channel previews from that NVR.'
                : 'Auto mode tries to discover an IMOU/Dahua NVR on the LAN, then shows channel previews when discovery succeeds.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: useDirectNvr,
            title: Text(
              'Direct NVR mode',
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Recommended for demo. Enter the NVR host directly, then choose the camera view from previews.',
              style: GoogleFonts.inter(color: palette.textMuted, fontSize: 12),
            ),
            onChanged: onToggleDirectMode,
          ),
          if (!useDirectNvr) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.wrench,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Auto discovery is in maintenance mode. It can still scan the LAN, but direct mode is more stable for capstone demo setup.',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            key: usernameFieldKey,
            child: TextField(
              controller: usernameController,
              focusNode: usernameFocusNode,
              textInputAction: TextInputAction.next,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              decoration: const InputDecoration(
                labelText: 'NVR username',
                hintText: 'admin or least-privilege user',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: passwordFieldKey,
            child: TextField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: obscurePassword,
              textInputAction:
                  useDirectNvr ? TextInputAction.next : TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              onSubmitted: (_) {
                if (!useDirectNvr) onSubmit();
              },
              decoration: InputDecoration(
                labelText: 'NVR password',
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'After the ESP32 joins Wi-Fi, it will show live channel previews so you can choose the right view instead of guessing a channel number.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (useDirectNvr) ...[
            const SizedBox(height: 12),
            Container(
              key: hostFieldKey,
              child: TextField(
                controller: hostController,
                focusNode: hostFocusNode,
                textInputAction: TextInputAction.next,
                scrollPadding: const EdgeInsets.only(bottom: 180),
                decoration: const InputDecoration(
                  labelText: 'Direct NVR host',
                  hintText: '192.168.2.23 or 192.168.1.237',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              key: portFieldKey,
              child: TextField(
                controller: portController,
                focusNode: portFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                scrollPadding: const EdgeInsets.only(bottom: 180),
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  labelText: 'Direct NVR port',
                  hintText: '80 or forwarded port such as 18080',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(LucideIcons.serverCog, size: 18),
            label: const Text('Save NVR config to ESP32'),
          ),
        ],
      ),
    );
  }
}

class _NvrChannelPickerCard extends StatelessWidget {
  const _NvrChannelPickerCard({
    required this.palette,
    required this.channels,
    required this.onRefresh,
    required this.onSelected,
  });

  final _HubPalette palette;
  final List<NvrChannelPreview> channels;
  final VoidCallback onRefresh;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final onlineChannels =
        channels.where((channel) => channel.online).toList(growable: false);

    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose camera view',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            onlineChannels.isEmpty
                ? 'No live previews were returned. Offline channels are shown below for troubleshooting.'
                : 'Select the clearest view for occupancy counting. The ESP32 will save that channel and use it for detection.',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: channels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final channel = channels[index];
              return _NvrChannelTile(
                palette: palette,
                channel: channel,
                onTap:
                    channel.online ? () => onSelected(channel.channel) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NvrChannelTile extends StatelessWidget {
  const _NvrChannelTile({
    required this.palette,
    required this.channel,
    required this.onTap,
  });

  final _HubPalette palette;
  final NvrChannelPreview channel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: channel.online ? palette.accent : palette.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: channel.snapshotUrl == null
                  ? _NvrPreviewPlaceholder(
                      palette: palette,
                      label: 'No preview',
                    )
                  : Image.network(
                      channel.snapshotUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _NvrPreviewPlaceholder(
                        palette: palette,
                        label: 'Preview failed',
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _NvrPreviewPlaceholder(
                          palette: palette,
                          label: 'Loading',
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.online ? 'Ready to use' : 'Offline',
                    style: GoogleFonts.inter(
                      color: channel.online
                          ? AppColors.success
                          : palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NvrPreviewPlaceholder extends StatelessWidget {
  const _NvrPreviewPlaceholder({
    required this.palette,
    required this.label,
  });

  final _HubPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: palette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
