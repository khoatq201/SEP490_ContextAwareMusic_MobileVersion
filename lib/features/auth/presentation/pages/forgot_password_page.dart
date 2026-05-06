import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/app_feedback_presenter.dart';
import '../../../../core/widgets/app_inline_error_card.dart';
import '../../../../core/widgets/cams_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

enum _ForgotPasswordStep { email, otp, reset }

enum _ForgotPasswordAction { requestOtp, verifyOtp, resetPassword }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  _ForgotPasswordAction? _submittedAction;
  String? _flowEmail;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _step != _ForgotPasswordStep.email) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    _flowEmail = email;
    _submittedAction = _ForgotPasswordAction.requestOtp;
    context.read<AuthBloc>().add(ForgotPasswordOtpRequested(email: email));
  }

  void _resendOtp() {
    final email = _flowEmail ?? _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _step = _ForgotPasswordStep.email);
      return;
    }
    _submittedAction = _ForgotPasswordAction.requestOtp;
    context.read<AuthBloc>().add(ForgotPasswordOtpRequested(email: email));
  }

  void _verifyOtp() {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    final email = _flowEmail ?? _emailController.text.trim();
    _submittedAction = _ForgotPasswordAction.verifyOtp;
    context.read<AuthBloc>().add(
          ForgotPasswordOtpVerifyRequested(
            email: email,
            otp: _otpController.text.trim(),
          ),
        );
  }

  void _resetPassword() {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    final email = _flowEmail ?? _emailController.text.trim();
    _submittedAction = _ForgotPasswordAction.resetPassword;
    context.read<AuthBloc>().add(
          ForgotPasswordResetRequested(
            email: email,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  void _goBack() {
    switch (_step) {
      case _ForgotPasswordStep.email:
        context.go('/login');
      case _ForgotPasswordStep.otp:
        setState(() => _step = _ForgotPasswordStep.email);
      case _ForgotPasswordStep.reset:
        setState(() => _step = _ForgotPasswordStep.otp);
    }
  }

  bool _isCurrentActionLoading(AuthState state) {
    return state.status == AuthStatus.loading && _submittedAction != null;
  }

  bool _shouldShowFailure(AuthState state) {
    return _submittedAction != null &&
        state.status == AuthStatus.error &&
        state.failure != null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'Please enter the 6-digit code';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.feedback != null) {
          AppFeedbackPresenter.show(context, state.feedback!);
        }

        if (state.status == AuthStatus.forgotPasswordOtpSent) {
          setState(() {
            _step = _ForgotPasswordStep.otp;
            _otpController.clear();
          });
        }

        if (state.status == AuthStatus.forgotPasswordOtpVerified) {
          setState(() {
            _step = _ForgotPasswordStep.reset;
            _otpController.clear();
          });
        }

        if (state.status == AuthStatus.forgotPasswordResetSuccess) {
          _emailController.clear();
          _otpController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _flowEmail = null;
          _submittedAction = null;
          context.go('/login');
        }
      },
      builder: (context, state) {
        final tokens = context.camsTokens;
        final isLoading = _isCurrentActionLoading(state);

        return Scaffold(
          backgroundColor: tokens.bgBase,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingXl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildHeader(),
                      const SizedBox(height: AppDimensions.spacingXl),
                      _buildCard(state: state, isLoading: isLoading),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildFooterLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final tokens = context.camsTokens;
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: _step == _ForgotPasswordStep.email ? 'Back to login' : 'Back',
        onPressed: _goBack,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: tokens.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tokens = context.camsTokens;
    return Column(
      children: [
        const CAMSLogo(size: 78),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          _titleForStep,
          textAlign: TextAlign.center,
          style: AppTypography.displaySmall.copyWith(
            color: tokens.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          _subtitleForStep,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            color: tokens.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required AuthState state,
    required bool isLoading,
  }) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingLg),
      decoration: BoxDecoration(
        color: tokens.bgContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: tokens.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(),
          if (_shouldShowFailure(state)) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            AppInlineErrorCard(
              failure: state.failure,
              title: _failureTitle,
            ),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              _ForgotPasswordStep.email => _buildEmailForm(isLoading),
              _ForgotPasswordStep.otp => _buildOtpForm(
                  state: state,
                  isLoading: isLoading,
                ),
              _ForgotPasswordStep.reset => _buildResetForm(
                  state: state,
                  isLoading: isLoading,
                ),
            },
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            _supportTextForStep,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: tokens.textTertiary,
              height: 1.45,
            ),
          ),
          if (_step == _ForgotPasswordStep.otp) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            _buildForgotPasswordMeta(state),
            const SizedBox(height: AppDimensions.spacingSm),
            TextButton.icon(
              onPressed: isLoading || _resendSecondsRemaining(state) > 0
                  ? null
                  : _resendOtp,
              icon: Icon(
                Icons.refresh_rounded,
                color: _resendSecondsRemaining(state) > 0
                    ? tokens.textTertiary
                    : colorScheme.primary,
              ),
              label: Text(
                _resendSecondsRemaining(state) > 0
                    ? 'Resend in ${_formatDuration(_resendSecondsRemaining(state))}'
                    : 'Resend code',
                style: AppTypography.button.copyWith(
                  color: _resendSecondsRemaining(state) > 0
                      ? tokens.textTertiary
                      : colorScheme.primary,
                ),
              ),
            ),
          ] else if (_step == _ForgotPasswordStep.reset) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            _buildForgotPasswordMeta(state),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepPill(
          label: 'Email',
          isActive: _step.index >= _ForgotPasswordStep.email.index,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        _StepPill(
          label: 'OTP',
          isActive: _step.index >= _ForgotPasswordStep.otp.index,
        ),
        const SizedBox(width: AppDimensions.spacing8),
        _StepPill(
          label: 'Reset',
          isActive: _step.index >= _ForgotPasswordStep.reset.index,
        ),
      ],
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('forgot-password-email-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('forgot_password_email_field'),
            controller: _emailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestOtp(),
            decoration: _inputDecoration(
              label: 'Email',
              hint: 'manager@example.com',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _PrimaryActionButton(
            label: 'Send OTP',
            icon: Icons.mark_email_unread_outlined,
            isLoading: isLoading,
            onPressed: _requestOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm({
    required AuthState state,
    required bool isLoading,
  }) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('forgot-password-otp-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('forgot_password_otp_field'),
            controller: _otpController,
            validator: _validateOtp,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onFieldSubmitted: (_) => _verifyOtp(),
            style: AppTypography.headlineMedium.copyWith(
              color: context.camsTokens.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
            decoration: _inputDecoration(
              label: 'Verification code',
              hint: '123456',
              icon: Icons.pin_outlined,
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _PrimaryActionButton(
            label: 'Verify OTP',
            icon: Icons.verified_user_outlined,
            isLoading: isLoading,
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm({
    required AuthState state,
    required bool isLoading,
  }) {
    final sessionExpired = _resetSessionSecondsRemaining(state) == 0;
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('forgot-password-reset-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('forgot_password_new_password_field'),
            controller: _newPasswordController,
            validator: _validatePassword,
            obscureText: !_showNewPassword,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'New password',
              hint: 'At least 6 characters',
              icon: Icons.lock_reset_rounded,
              suffixIcon: _passwordToggle(
                isVisible: _showNewPassword,
                onPressed: () {
                  setState(() => _showNewPassword = !_showNewPassword);
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextFormField(
            key: const ValueKey('forgot_password_confirm_password_field'),
            controller: _confirmPasswordController,
            validator: _validateConfirmPassword,
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: _inputDecoration(
              label: 'Confirm password',
              hint: 'Repeat new password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: _passwordToggle(
                isVisible: _showConfirmPassword,
                onPressed: () {
                  setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _PrimaryActionButton(
            label: sessionExpired ? 'Session expired' : 'Reset password',
            icon: Icons.check_circle_outline_rounded,
            isLoading: isLoading,
            onPressed: sessionExpired ? null : _resetPassword,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTypography.labelLarge.copyWith(
        color: tokens.textSecondary,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: tokens.textTertiary,
      ),
      filled: true,
      fillColor: tokens.bgElevated,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: suffixIcon,
      border: _inputBorder(tokens.borderSecondary),
      enabledBorder: _inputBorder(tokens.borderSecondary),
      focusedBorder: _inputBorder(colorScheme.primary, width: 2),
      errorBorder: _inputBorder(tokens.error),
      focusedErrorBorder: _inputBorder(tokens.error, width: 2),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _passwordToggle({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: context.camsTokens.textSecondary,
      ),
    );
  }

  Widget _buildFooterLink() {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: () => context.go('/login'),
      icon: Icon(Icons.login_rounded, color: colorScheme.primary),
      label: Text(
        'Back to sign in',
        style: AppTypography.button.copyWith(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildForgotPasswordMeta(AuthState state) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final otpInfo = state.forgotPasswordOtpInfo;
    final verifyInfo = state.forgotPasswordVerifyInfo;
    final otpSeconds = _otpSecondsRemaining(state);
    final resetSeconds = _resetSessionSecondsRemaining(state);
    final attempts = _step == _ForgotPasswordStep.reset
        ? _attemptsText(
            verifyInfo?.remainingAttempts,
            verifyInfo?.maxAttempts,
          )
        : _attemptsText(
            otpInfo?.remainingAttempts,
            otpInfo?.maxAttempts,
          );

    final rows = <_MetaRow>[
      if (_step == _ForgotPasswordStep.otp && otpSeconds != null)
        _MetaRow(
          icon: Icons.timer_outlined,
          text: otpSeconds > 0
              ? 'OTP expires in ${_formatDuration(otpSeconds)}'
              : 'OTP has expired. Resend a new code.',
        ),
      if (_step == _ForgotPasswordStep.reset && resetSeconds != null)
        _MetaRow(
          icon: Icons.lock_clock_outlined,
          text: resetSeconds > 0
              ? 'Reset session expires in ${_formatDuration(resetSeconds)}'
              : 'Reset session expired. Verify OTP again.',
        ),
      if (attempts != null)
        _MetaRow(
          icon: Icons.pin_outlined,
          text: attempts,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: EdgeInsets.only(
                  bottom: row == rows.last ? 0 : AppDimensions.spacing8,
                ),
                child: Row(
                  children: [
                    Icon(row.icon, color: colorScheme.primary, size: 18),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        row.text,
                        style: AppTypography.bodyMedium.copyWith(
                          color: tokens.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String get _titleForStep {
    return switch (_step) {
      _ForgotPasswordStep.email => 'Forgot Password?',
      _ForgotPasswordStep.otp => 'Check Your Email',
      _ForgotPasswordStep.reset => 'Create New Password',
    };
  }

  String get _subtitleForStep {
    return switch (_step) {
      _ForgotPasswordStep.email =>
        'Enter your account email and CAMS will send a 6-digit OTP.',
      _ForgotPasswordStep.otp =>
        'Enter the verification code sent to ${_flowEmail ?? 'your email'}.',
      _ForgotPasswordStep.reset =>
        'Your email is verified. Set a new password to finish.',
    };
  }

  String get _supportTextForStep {
    return switch (_step) {
      _ForgotPasswordStep.email =>
        'The reset flow is public and only keeps your email temporarily for this session.',
      _ForgotPasswordStep.otp => 'The OTP is not stored after verification.',
      _ForgotPasswordStep.reset =>
        'The reset request sends only your email and new password.',
    };
  }

  String get _failureTitle {
    return switch (_submittedAction) {
      _ForgotPasswordAction.requestOtp => 'Could not send OTP',
      _ForgotPasswordAction.verifyOtp => 'OTP verification failed',
      _ForgotPasswordAction.resetPassword => 'Password reset failed',
      null => 'Forgot password failed',
    };
  }

  int? _otpSecondsRemaining(AuthState state) {
    final info = state.forgotPasswordOtpInfo;
    if (info == null) return null;
    return _secondsUntil(
      info.expiresAtUtc,
      fallbackSeconds: info.expiresInSeconds,
    );
  }

  int _resendSecondsRemaining(AuthState state) {
    final info = state.forgotPasswordOtpInfo;
    if (info == null) return 0;
    return _secondsUntil(
          info.resendAvailableAtUtc,
          fallbackSeconds: info.resendAfterSeconds,
        ) ??
        0;
  }

  int? _resetSessionSecondsRemaining(AuthState state) {
    final info = state.forgotPasswordVerifyInfo;
    if (info == null) return null;
    return _secondsUntil(
      info.resetSessionExpiresAtUtc,
      fallbackSeconds: info.resetSessionExpiresInSeconds,
    );
  }

  int? _secondsUntil(DateTime? utcDateTime, {int? fallbackSeconds}) {
    if (utcDateTime == null) return fallbackSeconds;
    final seconds =
        utcDateTime.toUtc().difference(DateTime.now().toUtc()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  String? _attemptsText(int? remainingAttempts, int? maxAttempts) {
    if (remainingAttempts == null && maxAttempts == null) return null;
    if (remainingAttempts != null && maxAttempts != null) {
      return '$remainingAttempts of $maxAttempts OTP attempts remaining';
    }
    if (remainingAttempts != null) {
      return '$remainingAttempts OTP attempts remaining';
    }
    return 'Maximum $maxAttempts OTP attempts';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    if (minutes <= 0) return '${remainder}s';
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class _MetaRow {
  const _MetaRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.label,
    required this.isActive,
  });

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? tokens.brandPrimarySoft : tokens.bgElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isActive ? colorScheme.primary : tokens.borderSecondary,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: isActive ? colorScheme.primary : tokens.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: tokens.brandPrimarySoft,
          disabledForegroundColor: tokens.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          elevation: 0,
        ),
        icon: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tokens.textOnAccent,
                  ),
                ),
              )
            : Icon(icon, color: tokens.textOnAccent),
        label: Text(
          isLoading ? 'Please wait...' : label,
          style: AppTypography.button.copyWith(
            color: isLoading ? tokens.textSecondary : tokens.textOnAccent,
          ),
        ),
      ),
    );
  }
}
