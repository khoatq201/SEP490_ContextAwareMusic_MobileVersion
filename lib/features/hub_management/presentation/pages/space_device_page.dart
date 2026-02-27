import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../data/repositories/mock_hub_repository.dart';
import '../../domain/entities/hub_entity.dart';
import '../../domain/entities/hub_sensor_entity.dart';
import '../../../space_control/domain/entities/space.dart';

/// Tab 5 — Device & Hardware management for the current Space.
///
/// Reads [Space] from [MockHubRepository.getCurrentSpaceDevice] and
/// renders two completely separate UI states depending on whether a
/// [HubEntity] is installed.
class SpaceDevicePage extends StatefulWidget {
  const SpaceDevicePage({super.key});

  @override
  State<SpaceDevicePage> createState() => _SpaceDevicePageState();
}

class _SpaceDevicePageState extends State<SpaceDevicePage> {
  late Space _space;

  /// Local copy of the volume; driven by the Slider in [_AudioCard].
  double _volume = 0.65;

  @override
  void initState() {
    super.initState();
    _space = MockHubRepository.getCurrentSpaceDevice();
    _volume = (_space.currentHub?.currentVolume ?? 65) / 100;
  }

  // ── Action handlers ─────────────────────────────────────────────────────

  void _showUnpairDialog(BuildContext context, _Palette palette) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa Hub khỏi không gian?',
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa Hub này khỏi ${_space.name} không?\nCác tự động hóa sẽ ngừng hoạt động.',
          style: GoogleFonts.inter(
            color: palette.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Xóa',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        mockHasHub = false;
        setState(() {
          _space = MockHubRepository.getCurrentSpaceDevice();
        });
      }
    });
  }

  void _showWifiSheet(BuildContext context, _Palette palette) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WifiConfigBottomSheet(palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final hub = _space.currentHub;

    return BlocListener<PlayerBloc, ps.PlayerState>(
      // When the active space changes from the Now Playing swap sheet,
      // reload hub data so this page reflects the newly selected space.
      listenWhen: (prev, curr) => prev.activeSpaceId != curr.activeSpaceId,
      listener: (context, playerState) {
        if (!mounted) return;
        setState(() {
          _space = MockHubRepository.getCurrentSpaceDevice();
          _volume = (_space.currentHub?.currentVolume ?? 65) / 100;
        });
      },
      child: BlocBuilder<PlayerBloc, ps.PlayerState>(
        buildWhen: (prev, curr) =>
            prev.activeSpaceName != curr.activeSpaceName ||
            prev.activeSpaceId != curr.activeSpaceId,
        builder: (context, playerState) {
          final displayName = playerState.activeSpaceName ?? _space.name;
          return Scaffold(
            backgroundColor: palette.bg,
            appBar: AppBar(
              backgroundColor: palette.bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thiết bị & Phần cứng',
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Đang quản lý: $displayName',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            body: hub == null
                ? _NoHubState(palette: palette)
                : _HubPresentState(
                    hub: hub,
                    volume: _volume,
                    palette: palette,
                    onVolumeChanged: (v) => setState(() => _volume = v),
                    onChangeWifi: () => _showWifiSheet(context, palette),
                    onUnpair: () => _showUnpairDialog(context, palette),
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State A — No hub installed
// ─────────────────────────────────────────────────────────────────────────────

class _NoHubState extends StatelessWidget {
  const _NoHubState({required this.palette});
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.developer_board_outlined,
              size: 88,
              color: palette.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có thiết bị điều khiển',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Không gian này chưa được lắp đặt thiết bị điều khiển.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => debugPrint('Bắt đầu luồng kết nối Bluetooth'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.textOnAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.bluetooth, size: 20),
              label: const Text('Bắt đầu ghép nối Hub'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State B — Hub is present
// ─────────────────────────────────────────────────────────────────────────────

class _HubPresentState extends StatelessWidget {
  const _HubPresentState({
    required this.hub,
    required this.volume,
    required this.palette,
    required this.onVolumeChanged,
    required this.onChangeWifi,
    required this.onUnpair,
  });

  final HubEntity hub;
  final double volume;
  final _Palette palette;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onChangeWifi;
  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    // extendBody: true in MainShellPage → MediaQuery.padding.bottom already
    // includes the full height of BottomNav + MiniPlayer + safe-area inset.
    final bottomPad = MediaQuery.of(context).padding.bottom + 16;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      children: [
        _HubOverviewCard(hub: hub, palette: palette),
        const SizedBox(height: 14),
        if (hub.sensors.isNotEmpty) ...[
          _SensorsCard(sensors: hub.sensors, palette: palette),
          const SizedBox(height: 14),
        ],
        _AudioCard(
          hub: hub,
          volume: volume,
          palette: palette,
          onVolumeChanged: onVolumeChanged,
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          palette: palette,
          onChangeWifi: onChangeWifi,
          onUnpair: onUnpair,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 1 — Hub overview (MAC, Wi-Fi, Online/Offline)
// ─────────────────────────────────────────────────────────────────────────────

class _HubOverviewCard extends StatelessWidget {
  const _HubOverviewCard({required this.hub, required this.palette});

  final HubEntity hub;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    final statusColor = hub.isOnline ? Colors.green : Colors.red.shade400;
    final statusLabel = hub.isOnline ? 'Online' : 'Offline';

    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.cpu, size: 20, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tổng quan Hub',
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Online / Offline badge ──────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: hub.isOnline
                            ? [
                                BoxShadow(
                                    color: Colors.green.withOpacity(0.6),
                                    blurRadius: 5)
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: palette.border, height: 1, thickness: 0.8),
          const SizedBox(height: 14),
          // ── MAC Address ──────────────────────────────────────────────
          _InfoRow(
            icon: LucideIcons.fingerprint,
            label: 'MAC Address',
            value: hub.macAddress,
            palette: palette,
            valueStyle: GoogleFonts.sourceCodePro(
              color: palette.textPrimary,
              fontSize: 12,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // ── Wi-Fi signal ─────────────────────────────────────────────
          _InfoRow(
            icon: LucideIcons.wifi,
            label: 'Cường độ Wi-Fi',
            value: hub.wifiSignalStrength,
            palette: palette,
            valueColor: _wifiColor(hub.wifiSignalStrength),
          ),
        ],
      ),
    );
  }

  Color _wifiColor(String strength) {
    switch (strength) {
      case 'Mạnh':
        return Colors.green;
      case 'Yếu':
        return Colors.orange;
      default:
        return Colors.orange.shade300;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 2 — Sensors
// ─────────────────────────────────────────────────────────────────────────────

class _SensorsCard extends StatelessWidget {
  const _SensorsCard({required this.sensors, required this.palette});

  final List<HubSensorEntity> sensors;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                'Trạng thái Cảm biến',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sensors
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _SensorChip(sensor: s, palette: palette),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 3 — Audio out (speaker + volume slider)
// ─────────────────────────────────────────────────────────────────────────────

class _AudioCard extends StatelessWidget {
  const _AudioCard({
    required this.hub,
    required this.volume,
    required this.palette,
    required this.onVolumeChanged,
  });

  final HubEntity hub;
  final double volume;
  final _Palette palette;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.volume, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                'Âm thanh',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: palette.border, height: 1, thickness: 0.8),
          const SizedBox(height: 14),
          // ── Speaker name (tappable → Bluetooth sheet) ────────────────
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => BluetoothSpeakerSelectionSheet(palette: palette),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.speaker_outlined,
                      size: 16, color: palette.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loa đang kết nối',
                          style: GoogleFonts.inter(
                            color: palette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hub.connectedSpeakerName,
                          style: GoogleFonts.inter(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Volume slider ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.volume_mute_outlined,
                  size: 18, color: palette.textMuted),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: palette.accent,
                    inactiveTrackColor: palette.border,
                    thumbColor: palette.accent,
                    overlayColor: palette.accent.withOpacity(0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: onVolumeChanged,
                    min: 0,
                    max: 1,
                  ),
                ),
              ),
              Icon(Icons.volume_up_outlined,
                  size: 18, color: palette.textMuted),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                child: Text(
                  '${(volume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: palette.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings section (three full-width outlined buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.palette,
    required this.onChangeWifi,
    required this.onUnpair,
  });

  final _Palette palette;
  final VoidCallback onChangeWifi;
  final VoidCallback onUnpair;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cài đặt thiết bị',
          style: GoogleFonts.poppins(
            color: palette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _SettingsButton(
          icon: Icons.wifi_outlined,
          label: 'Đổi mạng Wi-Fi',
          palette: palette,
          onTap: onChangeWifi,
        ),
        const SizedBox(height: 8),
        _SettingsButton(
          icon: Icons.restart_alt,
          label: 'Khởi động lại Hub',
          palette: palette,
          onTap: () => debugPrint('Khởi động lại Hub'),
        ),
        const SizedBox(height: 8),
        _SettingsButton(
          icon: Icons.delete_outline,
          label: 'Hủy ghép nối thiết bị',
          palette: palette,
          isDestructive: true,
          onTap: onUnpair,
        ),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final _Palette palette;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade400 : palette.textPrimary;
    final borderColor =
        isDestructive ? Colors.red.shade300.withOpacity(0.5) : palette.border;

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: generic card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.palette, required this.child});

  final _Palette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.22 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: info row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    this.valueColor,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final _Palette palette;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: palette.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(color: palette.textMuted, fontSize: 13),
        ),
        const Spacer(),
        if (valueStyle != null)
          Text(value, style: valueStyle)
        else
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor ?? palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: sensor chip
// ─────────────────────────────────────────────────────────────────────────────

class _SensorChip extends StatelessWidget {
  const _SensorChip({required this.sensor, required this.palette});

  final HubSensorEntity sensor;
  final _Palette palette;

  IconData get _icon {
    switch (sensor.type) {
      case 'temperature':
        return LucideIcons.thermometer;
      case 'crowd':
        return LucideIcons.users;
      case 'humidity':
        return LucideIcons.droplets;
      case 'noise':
        return LucideIcons.volume;
      default:
        return LucideIcons.activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = sensor.currentValue == null;
    final chipColor =
        isOffline ? palette.textMuted.withOpacity(0.4) : palette.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: chipColor.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 14, color: chipColor),
              const SizedBox(width: 6),
              Text(
                sensor.name,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sensor.formattedValue,
            style: GoogleFonts.inter(
              color: isOffline ? palette.textMuted : palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wi-Fi Config Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class WifiConfigBottomSheet extends StatefulWidget {
  const WifiConfigBottomSheet({super.key, required this.palette});
  final _Palette palette;

  @override
  State<WifiConfigBottomSheet> createState() => _WifiConfigBottomSheetState();
}

class _WifiConfigBottomSheetState extends State<WifiConfigBottomSheet> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  _Palette get _p => widget.palette;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ssidController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đổi Wi-Fi thành công'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _p.border,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Title ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.wifi_outlined, color: _p.accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Đổi mạng Wi-Fi cho Hub',
                style: GoogleFonts.poppins(
                  color: _p.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cấu hình sẽ được gửi đến Hub qua kết nối Bluetooth.',
            style: GoogleFonts.inter(color: _p.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          // ── SSID field ───────────────────────────────────────────────
          Text(
            'Tên Wi-Fi (SSID)',
            style: GoogleFonts.inter(
              color: _p.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ssidController,
            style: GoogleFonts.inter(color: _p.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'VD: MyHomeNetwork',
              hintStyle: GoogleFonts.inter(color: _p.textMuted, fontSize: 14),
              prefixIcon:
                  Icon(Icons.wifi_outlined, color: _p.textMuted, size: 20),
              filled: true,
              fillColor: _p.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.accent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          // ── Password field ───────────────────────────────────────────
          Text(
            'Mật khẩu',
            style: GoogleFonts.inter(
              color: _p.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: _p.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu Wi-Fi',
              hintStyle: GoogleFonts.inter(color: _p.textMuted, fontSize: 14),
              prefixIcon:
                  Icon(Icons.lock_outline, color: _p.textMuted, size: 20),
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _p.textMuted,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: _p.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _p.accent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          // ── Submit button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _p.accent,
                foregroundColor: _p.textOnAccent,
                disabledBackgroundColor: _p.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _p.textOnAccent,
                      ),
                    )
                  : const Icon(Icons.bluetooth, size: 18),
              label: Text(
                _isLoading
                    ? 'Đang gửi cấu hình...'
                    : 'Gửi cấu hình qua Bluetooth',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bluetooth Speaker Selection Sheet
// ─────────────────────────────────────────────────────────────────────────────

class BluetoothSpeakerSelectionSheet extends StatelessWidget {
  const BluetoothSpeakerSelectionSheet({super.key, required this.palette});

  final _Palette palette;

  static const _mockSpeakers = [
    'Marshall Stanmore III',
    'Sony SRS-XB43',
    'JBL Charge 5',
    'Bose SoundLink Flex',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Title ─────────────────────────────────────────────────────
          Text(
            'Chọn loa Bluetooth',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // ── Scanning indicator ────────────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Đang quét loa Bluetooth gần Hub...',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: palette.border, height: 1),
          // ── Speaker list ──────────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockSpeakers.length,
            separatorBuilder: (_, __) =>
                Divider(color: palette.border, height: 1),
            itemBuilder: (context, index) {
              final speaker = _mockSpeakers[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.speaker_rounded,
                      color: palette.accent, size: 20),
                ),
                title: Text(
                  speaker,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Bluetooth 5.0',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: palette.textMuted, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã gửi lệnh kết nối loa đến Hub'),
                      backgroundColor: palette.accent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              );
            },
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
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.textOnAccent,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return const _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
        textOnAccent: AppColors.textDarkPrimary,
      );
    }
    return const _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      textOnAccent: AppColors.textInverse,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color textOnAccent;
}
