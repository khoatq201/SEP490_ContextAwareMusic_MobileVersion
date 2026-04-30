import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_inline_error_card.dart';
import '../../../../core/widgets/cams_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const _googleLogoUrl =
    'https://developers.google.com/identity/images/g-logo.png';

/// Enhanced login page aligned with the CAMS reference design.
class LoginPageV2 extends StatefulWidget {
  const LoginPageV2({super.key});

  @override
  State<LoginPageV2> createState() => _LoginPageV2State();
}

class _LoginPageV2State extends State<LoginPageV2>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            ),
          );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (_, __) {},
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = context.camsTokens.bgBase;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: backgroundColor),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LoginBackdropPainter(isDark: isDark),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingLg,
                      vertical: AppDimensions.spacingXl,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            children: [
                              _buildBrandHeader(),
                              const SizedBox(height: AppDimensions.spacingXl),
                              _buildAuthCard(
                                state: state,
                                isDark: isDark,
                                isLoading: isLoading,
                              ),
                              if (ApiConstants.useMockData) ...[
                                const SizedBox(height: AppDimensions.spacingLg),
                                _buildDemoPanel(isDark),
                              ],
                              const SizedBox(height: AppDimensions.spacingXl),
                              Text(
                                'Copyright 2026 CAMS Store Manager',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.textDarkTertiary
                                      : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: AppDimensions.spacingMd,
                right: AppDimensions.spacingMd,
                child: SafeArea(
                  child: _LoginThemeToggleButton(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthCard({
    required AuthState state,
    required bool isDark,
    required bool isLoading,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final titleSize = compact ? 32.0 : 36.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingXl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDarkMedium : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? context.camsTokens.shadow : AppColors.shadow,
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: AppTypography.displaySmall.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Sign in to manage your stores',
            style: AppTypography.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          if (state.failure != null) ...[
            AppInlineErrorCard(
              failure: state.failure,
              title: 'Sign-in failed',
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
            ),
          ],
          TextFormField(
            key: const ValueKey('login_email_field'),
            controller: _emailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: _buildInputDecoration(
              label: 'Email',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              isDark: isDark,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextFormField(
            key: const ValueKey('login_password_field'),
            controller: _passwordController,
            validator: _validatePassword,
            obscureText: !_isPasswordVisible,
            decoration: _buildInputDecoration(
              label: 'Password',
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildSupportRow(isDark),
          const SizedBox(height: 18),
          _buildSignInButton(
            isDark: isDark,
            isLoading: isLoading,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AppColors.borderDarkMedium
                      : AppColors.borderMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AppColors.borderDarkMedium
                      : AppColors.borderMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGoogleSignInButton(isDark),
          const SizedBox(height: 18),
          _buildAuthNavigationLinks(isDark),
        ],
      ),
    );
  }

  Widget _buildSupportRow(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          flex: 6,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDarkStrong
                          : AppColors.textPrimary,
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    activeColor: isDark
                        ? AppColors.primaryCyan
                        : AppColors.primaryOrange,
                    checkColor: context.camsTokens.textOnAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Remember me',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          flex: 5,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? AppColors.primaryCyan : AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -3,
                ),
              ),
              onPressed: () => context.go('/forgot-password'),
              child: Text(
                'Forgot Password?',
                textAlign: TextAlign.right,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.primaryCyan : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton({
    required bool isDark,
    required bool isLoading,
  }) {
    final baseColor = isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final highlightColor =
        isDark ? AppColors.primaryCyanBright : AppColors.primaryOrangeLight;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              highlightColor.withValues(alpha: 0.96),
              baseColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('login_submit_button'),
            borderRadius: BorderRadius.circular(18),
            onTap: isLoading ? null : _handleLogin,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.camsTokens.textOnAccent,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 22,
                          color: context.camsTokens.textOnAccent
                              .withValues(alpha: 0.96),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sign In',
                          style: AppTypography.button.copyWith(
                            fontSize: 17,
                            color: context.camsTokens.textOnAccent,
                            fontWeight: FontWeight.w700,
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

  Widget _buildGoogleSignInButton(bool isDark) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.surfaceDarkElevated
              : context.camsTokens.bgContainer,
          foregroundColor:
              isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          side: BorderSide(
            color: isDark ? AppColors.borderDarkStrong : AppColors.textPrimary,
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: AppTypography.titleMedium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google sign-in coming soon!'),
              backgroundColor: isDark
                  ? AppColors.surfaceDarkElevated
                  : AppColors.textPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          );
        },
        icon: const _GoogleIcon(),
        label: const Text('Continue with Google'),
      ),
    );
  }

  Widget _buildAuthNavigationLinks(bool isDark) {
    final accentColor =
        isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final mutedColor =
        isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final textColor =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              key: const ValueKey('login_back_welcome_button'),
              style: TextButton.styleFrom(
                foregroundColor: mutedColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => context.go('/welcome'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Welcome',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('login_pair_device_button'),
              style: TextButton.styleFrom(
                foregroundColor: mutedColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => context.push('/pair-device'),
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: Text(
                'Pair device',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            Text(
              "Don't have an account?",
              style: AppTypography.titleSmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            TextButton(
              key: const ValueKey('login_signup_button'),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _showRegistrationComingSoon,
              child: Text(
                'Sign up',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRegistrationComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Registration portal coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }

  Widget _buildDemoPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryCyan.withValues(alpha: 0.08)
            : AppColors.primaryOrangePale,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.primaryCyan.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: isDark ? AppColors.primaryCyan : AppColors.secondaryTeal,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                'Demo Mode',
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.primaryCyan : AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildDemoAccount(
            context,
            'Admin',
            'admin@example.com',
            'Admin@123',
            isDark,
          ),
          _buildDemoAccount(
            context,
            'Store Manager',
            'store@example.com',
            'Store@123',
            isDark,
          ),
          _buildDemoAccount(
            context,
            'Brand Director',
            'brand@example.com',
            'Brand@123',
            isDark,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    final labelColor =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final hintColor =
        isDark ? AppColors.textDarkTertiary : AppColors.textTertiary;
    final outlineColor =
        isDark ? AppColors.borderDarkStrong : AppColors.textPrimary;

    return InputDecoration(
      label: Text(label),
      labelStyle: AppTypography.labelLarge.copyWith(
        fontSize: 16,
        color: labelColor,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: AppTypography.labelLarge.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
      hintText: hint,
      hintStyle: AppTypography.titleMedium.copyWith(
        fontSize: 16,
        color: hintColor,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceDarkElevated
          : context.camsTokens.bgContainer,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 18, right: 12),
        child: Icon(
          icon,
          size: 28,
          color: labelColor,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 60,
        minHeight: 56,
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffixIcon,
            ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 60,
        minHeight: 56,
      ),
      border: _authInputBorder(outlineColor),
      enabledBorder: _authInputBorder(outlineColor),
      focusedBorder: _authInputBorder(
        isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
        width: 2.2,
      ),
      errorBorder: _authInputBorder(AppColors.error, width: 1.8),
      focusedErrorBorder: _authInputBorder(AppColors.errorDark, width: 2.2),
    );
  }

  OutlineInputBorder _authInputBorder(
    Color color, {
    double width = 1.8,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  Widget _buildDemoAccount(
    BuildContext context,
    String role,
    String email,
    String password,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: () {
          _emailController.text = email;
          _passwordController.text = password;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 15,
                color: isDark
                    ? AppColors.textDarkTertiary
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                '$role: ',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  '$email / $password',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textDarkTertiary
                        : AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.touch_app_outlined,
                size: 15,
                color: isDark
                    ? AppColors.primaryCyan.withValues(alpha: 0.55)
                    : AppColors.secondaryTeal.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const CAMSLogo(size: 94),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'CAMS',
          style: AppTypography.brand.copyWith(
            fontSize: 42,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w800,
            shadows: const [],
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          'Context-Aware Music System',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LoginThemeToggleButton extends StatelessWidget {
  const _LoginThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = context.camsTokens;
    final isDark = themeProvider.isDarkMode;

    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: tokens.bgElevated.withValues(alpha: 0.88),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: themeProvider.toggleTheme,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: SizedBox(
              key: ValueKey(isDark),
              width: 44,
              height: 44,
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? tokens.warning : tokens.brandPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  const _LoginBackdropPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rightPaint = Paint()
      ..color =
          (isDark ? AppColors.primaryCyanMuted : AppColors.secondaryTealLight)
              .withValues(alpha: isDark ? 0.22 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftPaint = Paint()
      ..color = (isDark ? AppColors.primaryCyan : AppColors.primaryOrangeLight)
          .withValues(alpha: isDark ? 0.12 : 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var index = 0; index < 9; index++) {
      final shift = index * 14.0;
      final rightWave = Path()
        ..moveTo(size.width * 0.72, size.height * 0.28 + shift)
        ..cubicTo(
          size.width * 0.95,
          size.height * 0.34 + shift,
          size.width * 0.76,
          size.height * 0.62 + shift,
          size.width + 30,
          size.height * 0.52 + shift,
        );
      canvas.drawPath(rightWave, rightPaint);
    }

    for (var index = 0; index < 8; index++) {
      final shift = index * 14.0;
      final leftWave = Path()
        ..moveTo(-35, size.height * 0.68 + shift)
        ..cubicTo(
          size.width * 0.12,
          size.height * 0.56 + shift,
          size.width * 0.23,
          size.height * 0.84 + shift,
          size.width * 0.45,
          size.height * 0.76 + shift,
        );
      canvas.drawPath(leftWave, leftPaint);
    }

    final orbitPaint = Paint()
      ..color = (isDark ? AppColors.primaryCyanMuted : AppColors.borderLight)
          .withValues(alpha: isDark ? 0.16 : 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.24),
      size.width * 0.23,
      orbitPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.9),
      size.width * 0.31,
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

/// Google "G" logo served from Google Identity documentation assets.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Image.network(
        _googleLogoUrl,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Google logo',
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
