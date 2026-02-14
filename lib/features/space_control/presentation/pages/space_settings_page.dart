import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

import '../../../../core/constants/app_colors.dart';

class SpaceSettingsPage extends StatefulWidget {
  final String storeId;
  final String spaceId;
  final String spaceName;

  const SpaceSettingsPage({
    Key? key,
    required this.storeId,
    required this.spaceId,
    required this.spaceName,
  }) : super(key: key);

  @override
  State<SpaceSettingsPage> createState() => _SpaceSettingsPageState();
}

class _SpaceSettingsPageState extends State<SpaceSettingsPage> {
  // Mock state
  bool _isHubLinked = true;
  String _hubDeviceName = 'ESP32-X821';
  String _hubIpAddress = '192.168.1.145';
  int _connectionStrength = 85; // 0-100

  AudioOutputMode _audioMode = AudioOutputMode.bluetooth;
  String? _pairedSpeaker = 'JBL Flip 5';

  late TextEditingController _spaceNameController;

  @override
  void initState() {
    super.initState();
    _spaceNameController = TextEditingController(text: widget.spaceName);
  }

  @override
  void dispose() {
    _spaceNameController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Space Settings',
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Connection Status
          _buildConnectionStatusCard(palette),
          const SizedBox(height: 24),

          // Section 2: Audio Output
          _buildSectionHeader('Audio Output', palette),
          const SizedBox(height: 12),
          _buildAudioOutputSection(palette),
          const SizedBox(height: 24),

          // Section 3: Space Info
          _buildSectionHeader('Space Information', palette),
          const SizedBox(height: 12),
          _buildSpaceInfoSection(palette),
          const SizedBox(height: 24),

          // Section 4: Danger Zone
          _buildSectionHeader('Danger Zone', palette),
          const SizedBox(height: 12),
          _buildDangerZoneSection(palette),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(_Palette palette) {
    if (!_isHubLinked) {
      return _buildNoHubCard(palette);
    }
    return _buildHubLinkedCard(palette);
  }

  Widget _buildNoHubCard(_Palette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.border,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withOpacity(0.1),
              border: Border.all(
                color: palette.accent.withOpacity(0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Icon(
              LucideIcons.wifiOff,
              size: 48,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Hub Linked',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect an IoT Hub to control this space',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _handleLinkHub,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accent,
              side: BorderSide(color: palette.accent, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(LucideIcons.qrCode, size: 20),
            label: Text(
              'Link IoT Hub',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubLinkedCard(_Palette palette) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.card.withOpacity(0.8),
                palette.overlay.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: palette.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.2),
                    ),
                    child: const Icon(
                      LucideIcons.wifi,
                      size: 24,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Connected',
                              style: GoogleFonts.inter(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildSignalStrength(_connectionStrength, palette),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hubDeviceName,
                          style: GoogleFonts.poppins(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.overlay.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.network,
                      size: 16,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'IP: $_hubIpAddress',
                      style: GoogleFonts.jetBrainsMono(
                        color: palette.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalStrength(int strength, _Palette palette) {
    final bars = (strength / 25).ceil().clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < bars;
        return Container(
          width: 3,
          height: 8 + (index * 2.0),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : palette.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, _Palette palette) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: palette.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ).copyWith(height: 1),
    );
  }

  Widget _buildAudioOutputSection(_Palette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Wired (AUX) Option
          RadioListTile<AudioOutputMode>(
            value: AudioOutputMode.aux,
            groupValue: _audioMode,
            onChanged: _isHubLinked
                ? (value) => setState(() => _audioMode = value!)
                : null,
            activeColor: palette.accent,
            title: Row(
              children: [
                Icon(LucideIcons.plug, size: 20, color: palette.textPrimary),
                const SizedBox(width: 12),
                Text(
                  'Wired (AUX)',
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Direct 3.5mm connection',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Divider(height: 1, color: palette.border.withOpacity(0.3)),

          // Bluetooth Speaker Option
          RadioListTile<AudioOutputMode>(
            value: AudioOutputMode.bluetooth,
            groupValue: _audioMode,
            onChanged: _isHubLinked
                ? (value) => setState(() => _audioMode = value!)
                : null,
            activeColor: palette.accent,
            title: Row(
              children: [
                Icon(LucideIcons.bluetooth,
                    size: 20, color: palette.textPrimary),
                const SizedBox(width: 12),
                Text(
                  'Bluetooth Speaker',
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            subtitle: _pairedSpeaker != null
                ? Text(
                    'Paired: $_pairedSpeaker',
                    style: GoogleFonts.inter(
                      color: palette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    'No speaker paired',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
          ),

          // Bluetooth Scan Button
          if (_audioMode == AudioOutputMode.bluetooth)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: _isHubLinked ? _handleBluetoothScan : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.accent,
                  side: BorderSide(color: palette.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(LucideIcons.search, size: 18),
                label: Text(
                  'Scan for Bluetooth Speakers',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpaceInfoSection(_Palette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Space Name',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _spaceNameController,
            style: GoogleFonts.inter(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Enter space name',
              hintStyle: GoogleFonts.inter(color: palette.textMuted),
              filled: true,
              fillColor: palette.overlay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.accent, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSaveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneSection(_Palette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.refreshCw, color: Colors.orange),
            title: Text(
              'Reboot Device',
              style: GoogleFonts.inter(
                color: Colors.orange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Restart the IoT Hub',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
              ),
            ),
            onTap: _isHubLinked ? _handleRebootDevice : null,
            enabled: _isHubLinked,
          ),
          Divider(height: 1, color: palette.border.withOpacity(0.3)),
          ListTile(
            leading: const Icon(LucideIcons.unlink, color: Colors.red),
            title: Text(
              'Unlink Device',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Remove Hub from this space',
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
              ),
            ),
            onTap: _isHubLinked ? _handleUnlinkDevice : null,
            enabled: _isHubLinked,
          ),
        ],
      ),
    );
  }

  // Action Handlers
  void _handleLinkHub() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link IoT Hub'),
        content:
            const Text('QR Code scanner would open here.\n\nMock: Hub linked!'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isHubLinked = true);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleBluetoothScan() async {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    // Show scanning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: palette.card,
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(palette.accent),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Scanning...',
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Looking for Bluetooth speakers nearby',
          style: GoogleFonts.inter(color: palette.textMuted),
        ),
      ),
    );

    // Simulate scan delay
    await Future.delayed(const Duration(seconds: 2));

    // Close scanning dialog
    if (!mounted) return;
    Navigator.pop(context);

    // Show results
    final mockSpeakers = [
      'JBL Flip 5',
      'Sony SRS-XB43',
      'Bose SoundLink',
      'Harman Kardon Onyx',
      'Marshall Emberton',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Speakers',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...mockSpeakers.map((speaker) => ListTile(
                    leading: Icon(LucideIcons.speaker, color: palette.accent),
                    title: Text(
                      speaker,
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      color: palette.textMuted,
                    ),
                    onTap: () {
                      setState(() => _pairedSpeaker = speaker);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Paired with $speaker'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleSaveName() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Space name updated to "${_spaceNameController.text}"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleRebootDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reboot Device?'),
        content: const Text(
          'This will restart the IoT Hub. Music playback will be interrupted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reboot command sent to Hub'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reboot', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _handleUnlinkDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Device?'),
        content: const Text(
          'This will remove the IoT Hub from this space. You can link a new device later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isHubLinked = false;
                _pairedSpeaker = null;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device unlinked'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Unlink', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

enum AudioOutputMode { aux, bluetooth }

// Palette helper class (same as in main screen)
class _Palette {
  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color shadow;
  final bool isDark;

  _Palette({
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.shadow,
    required this.isDark,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return _Palette(
      bg: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      card: isDark ? AppColors.surfaceDark : AppColors.surface,
      overlay: isDark
          ? AppColors.surfaceDark.withOpacity(0.8)
          : AppColors.surface.withOpacity(0.9),
      border: isDark ? AppColors.borderDarkLight : AppColors.borderLight,
      textPrimary: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
      textMuted: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
      accent: isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
      shadow: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.08),
      isDark: isDark,
    );
  }
}
