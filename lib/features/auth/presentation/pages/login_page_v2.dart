import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/cams_button.dart';
import '../../../../core/widgets/cams_logo.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Enhanced Login Page with CAMS Signature Components
class LoginPageV2 extends StatefulWidget {
  const LoginPageV2({Key? key}) : super(key: key);

  @override
  State<LoginPageV2> createState() => _LoginPageV2State();
}

class _LoginPageV2State extends State<LoginPageV2>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
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
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
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
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // Let router handle the redirect based on store count
            final user = state.user;
            if (user != null && user.storeIds.isNotEmpty) {
              if (user.storeIds.length > 1) {
                context.go('/store-selection');
              } else {
                context.go('/store/${user.storeIds.first}');
              }
            }
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Login failed'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            color: isDark
                ? AppColors.backgroundDarkPrimary
                : AppColors.backgroundPrimary,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBrandHeader(),
                          const SizedBox(height: AppDimensions.spacingXl),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(
                                AppDimensions.cardPaddingXl),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXxl),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDarkMedium
                                    : AppColors.borderLight,
                                width: AppDimensions.borderWidthNormal,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textDarkPrimary
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacing4),
                                Text(
                                  'Sign in to manage your stores',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacingLg),
                                TextFormField(
                                  controller: _usernameController,
                                  validator: _validateUsername,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    hintText: 'Enter your username',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: AppDimensions.spacingMd),
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                ),
                                const SizedBox(height: AppDimensions.spacingMd),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.go('/forgot-password'),
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isDark
                                            ? AppColors.primaryCyan
                                            : AppColors.primaryOrange,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingMd),
                                 SizedBox(
                                  height: AppDimensions.buttonHeightLg,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _handleLogin,
                                    icon: isLoading
                                        ? const SizedBox.shrink()
                                        : const Icon(Icons.login),
                                    label: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text('Sign In'),
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingMd),
                                // ── Divider OR ──
                                Row(children: [
                                  Expanded(child: Divider(color: isDark ? AppColors.borderDarkMedium : AppColors.borderLight)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('or', style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.textDarkTertiary : AppColors.textTertiary,
                                    )),
                                  ),
                                  Expanded(child: Divider(color: isDark ? AppColors.borderDarkMedium : AppColors.borderLight)),
                                ]),
                                const SizedBox(height: AppDimensions.spacingMd),
                                // ── Google Sign In ──
                                SizedBox(
                                  height: AppDimensions.buttonHeightLg,
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                      side: BorderSide(
                                        color: isDark ? AppColors.borderDarkMedium : AppColors.borderMedium,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Google sign-in coming soon!'),
                                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: _GoogleIcon(),
                                    label: const Text('Continue with Google'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingLg),
                          Text(
                            '© 2026 CAMS Store Manager',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textDarkTertiary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const CAMSLogo(size: 70),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          'CAMS',
          style: AppTypography.brand.copyWith(
            fontSize: 28,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Context-Aware Music System',
          style: AppTypography.labelMedium.copyWith(
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Google "G" logo built with Flutter widgets (no asset needed).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Simple letter-G approach using a Container with styled text
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4), // Google blue
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
