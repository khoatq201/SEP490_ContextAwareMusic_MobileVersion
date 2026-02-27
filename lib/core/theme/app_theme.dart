import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// CAMS Complete Theme System
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Light theme for CAMS app
  static ThemeData get lightTheme {
    return ThemeData(
      // ========================================
      // Color Scheme - CAMS Adaptive Retail Hub
      // ========================================
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        primary: AppColors.primaryOrange,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryOrangePale,
        onPrimaryContainer: AppColors.primaryOrangeDark,
        secondary: AppColors.secondaryTeal,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryTealPale,
        onSecondaryContainer: AppColors.secondaryTealDark,
        tertiary: AppColors.secondaryTealLight,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorPale,
        onErrorContainer: AppColors.errorDark,
        background: AppColors.backgroundPrimary,
        onBackground: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceVariant: AppColors.backgroundSecondary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderLight,
        shadow: AppColors.shadow,
        brightness: Brightness.light,
      ),

      // ========================================
      // Primary Colors
      // ========================================
      primaryColor: AppColors.primaryOrange,
      primaryColorLight: AppColors.primaryOrangeLight,
      primaryColorDark: AppColors.primaryOrangeDark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // ========================================
      // AppBar Theme
      // ========================================
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.primaryOrange,
          size: AppDimensions.iconMd,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ========================================
      // Card Theme
      // ========================================
      cardTheme: CardThemeData(
        elevation: AppDimensions.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // ========================================
      // Elevated Button Theme
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          elevation: AppDimensions.elevationSm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Outlined Button Theme
      // ========================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          side: const BorderSide(
            color: AppColors.primaryOrange,
            width: AppDimensions.borderWidthThick,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Text Button Theme
      // ========================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Input Decoration Theme
      // ========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.textFieldPaddingHorizontal,
          vertical: AppDimensions.textFieldPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.primaryOrange,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ========================================
      // Icon Theme
      // ========================================
      iconTheme: const IconThemeData(
        color: AppColors.primaryOrange,
        size: AppDimensions.iconMd,
      ),

      // ========================================
      // Floating Action Button Theme
      // ========================================
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: AppDimensions.elevationMd,
      ),

      // ========================================
      // Chip Theme
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightOrange.withOpacity(0.3),
        deleteIconColor: AppColors.darkOrange,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkOrange,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        ),
      ),

      // ========================================
      // Dialog Theme
      // ========================================
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ========================================
      // Bottom Navigation Bar Theme
      // ========================================
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationMd,
        selectedIconTheme: IconThemeData(
          size: AppDimensions.bottomNavIconSize,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppDimensions.bottomNavIconSize,
        ),
      ),

      // ========================================
      // Divider Theme
      // ========================================
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: AppDimensions.dividerThickness,
        indent: AppDimensions.dividerIndent,
        endIndent: AppDimensions.dividerIndent,
      ),

      // ========================================
      // Progress Indicator Theme
      // ========================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        linearTrackColor: AppColors.paleOrange,
        circularTrackColor: AppColors.paleOrange,
      ),

      // ========================================
      // Switch Theme
      // ========================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightOrange;
          }
          return Colors.grey.shade300;
        }),
      ),

      // ========================================
      // Text Theme
      // ========================================
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ========================================
      // Other Properties
      // ========================================
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
    );
  }

  /// Dark theme (optional for future)
  static ThemeData get darkTheme {
    return ThemeData(
      // ========================================
      // Color Scheme - Dark Mode Digital Pulse
      // ========================================
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryCyan,
        brightness: Brightness.dark,
        primary: AppColors.primaryCyan,
        onPrimary: AppColors.backgroundDarkPrimary,
        primaryContainer: AppColors.primaryCyanMuted,
        onPrimaryContainer: AppColors.primaryCyanBright,
        secondary: AppColors.secondaryLime,
        onSecondary: AppColors.backgroundDarkPrimary,
        secondaryContainer: AppColors.secondaryLimeMuted,
        onSecondaryContainer: AppColors.secondaryLimeBright,
        tertiary: AppColors.primaryCyanBright,
        onTertiary: AppColors.backgroundDarkPrimary,
        error: AppColors.errorNeon,
        onError: AppColors.textDarkPrimary,
        errorContainer: AppColors.errorPale,
        onErrorContainer: AppColors.errorNeon,
        background: AppColors.backgroundDarkPrimary,
        onBackground: AppColors.textDarkPrimary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDarkPrimary,
        surfaceVariant: AppColors.surfaceDarkElevated,
        onSurfaceVariant: AppColors.textDarkSecondary,
        outline: AppColors.borderDarkLight,
        shadow: AppColors.shadowDark,
      ),

      // ========================================
      // Primary Colors
      // ========================================
      primaryColor: AppColors.primaryCyan,
      primaryColorLight: AppColors.primaryCyanBright,
      primaryColorDark: AppColors.primaryCyanDark,
      scaffoldBackgroundColor: AppColors.backgroundDarkPrimary,

      // ========================================
      // AppBar Theme - Dark with Gradient
      // ========================================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.primaryCyan,
          size: AppDimensions.iconMd,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ========================================
      // Card Theme - Dark Elevated
      // ========================================
      cardTheme: CardThemeData(
        elevation: AppDimensions.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        color: AppColors.surfaceDark,
        shadowColor: AppColors.primaryCyan.withOpacity(0.1),
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // ========================================
      // Elevated Button Theme - Neon Glow
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCyan,
          foregroundColor: AppColors.backgroundDarkPrimary,
          elevation: AppDimensions.elevationSm,
          shadowColor: AppColors.primaryCyan.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Outlined Button Theme - Neon Border
      // ========================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          side: const BorderSide(
            color: AppColors.primaryCyan,
            width: AppDimensions.borderWidthThick,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Text Button Theme
      // ========================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // ========================================
      // Input Decoration Theme - Dark Mode
      // ========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.borderDarkLight,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.borderDarkLight,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.errorNeon,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: const BorderSide(
            color: AppColors.errorNeon,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textDarkTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.errorNeon,
        ),
        prefixIconColor: AppColors.textDarkSecondary,
        suffixIconColor: AppColors.textDarkSecondary,
      ),

      // ========================================
      // Dialog Theme - Dark
      // ========================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppDimensions.elevationXl,
        shadowColor: AppColors.primaryCyan.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
      ),

      // ========================================
      // Bottom Navigation Bar Theme
      // ========================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryCyan,
        unselectedItemColor: AppColors.textDarkTertiary,
        selectedIconTheme: const IconThemeData(
          size: AppDimensions.iconMd,
          color: AppColors.primaryCyan,
        ),
        unselectedIconTheme: const IconThemeData(
          size: AppDimensions.iconMd,
          color: AppColors.textDarkTertiary,
        ),
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.primaryCyan,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textDarkTertiary,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationMd,
      ),

      // ========================================
      // Floating Action Button Theme
      // ========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryCyan,
        foregroundColor: AppColors.backgroundDarkPrimary,
        elevation: AppDimensions.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
      ),

      // ========================================
      // Chip Theme
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkElevated,
        selectedColor: AppColors.primaryCyan.withOpacity(0.2),
        disabledColor: AppColors.borderDarkLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacing8,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        secondaryLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        side: const BorderSide(
          color: AppColors.borderDarkLight,
          width: AppDimensions.borderWidthNormal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        ),
        elevation: 0,
      ),

      // ========================================
      // Switch Theme - Neon
      // ========================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryCyan;
          }
          return Colors.grey.shade700;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryCyanMuted;
          }
          return Colors.grey.shade800;
        }),
      ),

      // ========================================
      // Text Theme
      // ========================================
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge
            .copyWith(color: AppColors.textDarkPrimary),
        displayMedium: AppTypography.displayMedium
            .copyWith(color: AppColors.textDarkPrimary),
        displaySmall: AppTypography.displaySmall
            .copyWith(color: AppColors.textDarkPrimary),
        headlineLarge: AppTypography.headlineLarge
            .copyWith(color: AppColors.textDarkPrimary),
        headlineMedium: AppTypography.headlineMedium
            .copyWith(color: AppColors.textDarkPrimary),
        headlineSmall: AppTypography.headlineSmall
            .copyWith(color: AppColors.textDarkPrimary),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: AppColors.textDarkPrimary),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppColors.textDarkPrimary),
        titleSmall:
            AppTypography.titleSmall.copyWith(color: AppColors.textDarkPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.textDarkPrimary),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppColors.textDarkSecondary),
        bodySmall: AppTypography.bodySmall
            .copyWith(color: AppColors.textDarkSecondary),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: AppColors.textDarkPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppColors.textDarkSecondary),
        labelSmall: AppTypography.labelSmall
            .copyWith(color: AppColors.textDarkTertiary),
      ),

      // ========================================
      // Other Properties
      // ========================================
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
