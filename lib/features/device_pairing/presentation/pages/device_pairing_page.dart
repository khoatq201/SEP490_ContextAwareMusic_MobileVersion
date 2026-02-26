import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../features/store_dashboard/domain/entities/store.dart';
import '../../../../features/space_control/domain/entities/space.dart';
import '../../../../core/theme/theme_provider.dart';
import '../bloc/device_pairing_bloc.dart';
import '../bloc/device_pairing_event.dart';
import '../bloc/device_pairing_state.dart';

class DevicePairingPage extends StatefulWidget {
  const DevicePairingPage({super.key});

  @override
  State<DevicePairingPage> createState() => _DevicePairingPageState();
}

class _DevicePairingPageState extends State<DevicePairingPage> {
  final _pairCodeController = TextEditingController();
  bool _isPairing = false;

  void _onPairPressed() {
    final code = _pairCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a pairing code',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<DevicePairingBloc>().add(PairDeviceRequested(code));
  }

  @override
  void dispose() {
    _pairCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDarkPrimary : AppColors.backgroundPrimary;
    final textColorPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final textColorSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primaryColor = isDark ? AppColors.primaryCyan : AppColors.primaryOrange;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColorPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<DevicePairingBloc, DevicePairingState>(
        listener: (context, state) {
          if (state.status == DevicePairingStatus.loading) {
            setState(() => _isPairing = true);
          } else if (state.status == DevicePairingStatus.failure) {
            setState(() => _isPairing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Pairing failed',
                  style: GoogleFonts.outfit(),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == DevicePairingStatus.success && state.pairingResult != null) {
            setState(() => _isPairing = false);
            
            // Success! Set up session for playback device
            final result = state.pairingResult!;
            final sessionCubit = context.read<SessionCubit>();
            
            sessionCubit.setPlaybackMode(
              store: Store(
                id: result.storeId,
                name: result.storeName,
                brandId: 'brand-1',
                address: 'Paired Location Route',
                totalSpaces: 1,
                activeSpaces: 1,
                isActive: true,
              ),
              space: Space(
                id: result.spaceId,
                name: result.spaceName,
                status: 'Online',
                assignedHubId: 'hub-123',
                storeId: result.storeId,
              ),
              deviceId: result.deviceId,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Paired with ${result.storeName} - ${result.spaceName}',
                  style: GoogleFonts.outfit(),
                ),
                backgroundColor: AppColors.success,
              ),
            );
            
            context.go('/home');
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Playback Device\nSetup',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit pairing code shown on your management dashboard to link this device to a space.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: textColorSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _pairCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: textColorPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: GoogleFonts.outfit(
                       color: textColorSecondary.withAlpha(76),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isPairing ? null : _onPairPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withAlpha(128),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isPairing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Pair Device',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
