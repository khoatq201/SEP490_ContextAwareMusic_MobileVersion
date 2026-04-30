import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import 'cams_theme_tokens.dart';

/// CAMS Complete Theme System
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Light theme for CAMS app
  static ThemeData get lightTheme {
    const tokens = CamsThemeTokens.light;
    return ThemeData(
      // ========================================
      // Color Scheme - CAMS Adaptive Retail Hub
      // ========================================
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.brandPrimary,
        primary: tokens.brandPrimary,
        onPrimary: tokens.textOnAccent,
        primaryContainer: tokens.brandPrimarySoft,
        onPrimaryContainer: tokens.brandPrimaryActive,
        secondary: tokens.techAccent,
        onSecondary: tokens.textOnAccent,
        secondaryContainer: tokens.techAccentSoft,
        onSecondaryContainer: tokens.techAccent,
        tertiary: tokens.brandPrimaryHover,
        onTertiary: tokens.textOnAccent,
        error: tokens.error,
        onError: tokens.textOnAccent,
        errorContainer: tokens.alertErrorBg,
        onErrorContainer: tokens.brandPrimaryActive,
        surface: tokens.bgContainer,
        onSurface: tokens.textPrimary,
        surfaceContainerHighest: tokens.bgLayout,
        onSurfaceVariant: tokens.textSecondary,
        outline: tokens.border,
        outlineVariant: tokens.borderSecondary,
        shadow: tokens.shadow,
        brightness: Brightness.light,
      ),

      // ========================================
      // Primary Colors
      // ========================================
      extensions: const [tokens],
      primaryColor: tokens.brandPrimary,
      primaryColorLight: tokens.brandPrimaryHover,
      primaryColorDark: tokens.brandPrimaryActive,
      scaffoldBackgroundColor: tokens.bgBase,

      // ========================================
      // AppBar Theme
      // ========================================
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgContainer,
        foregroundColor: tokens.textPrimary,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: tokens.brandPrimary,
          size: AppDimensions.iconMd,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: tokens.textPrimary,
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
        color: tokens.bgContainer,
        shadowColor: tokens.shadow,
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // ========================================
      // Elevated Button Theme
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.brandPrimary,
          foregroundColor: tokens.textOnAccent,
          elevation: 0,
          shadowColor: tokens.brandPrimary.withValues(alpha: 0.18),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 16),
        ),
      ),

      // ========================================
      // Outlined Button Theme
      // ========================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.brandPrimaryActive,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          side: BorderSide(
            color: tokens.border,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 16),
        ),
      ),

      // ========================================
      // Text Button Theme
      // ========================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brandPrimaryActive,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 16),
        ),
      ),

      // ========================================
      // Input Decoration Theme
      // ========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bgContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.textFieldPaddingHorizontal,
          vertical: AppDimensions.textFieldPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.border,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.border,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.brandPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.error,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: tokens.error,
        ),
        prefixIconColor: tokens.brandPrimary,
        suffixIconColor: tokens.textSecondary,
      ),

      // ========================================
      // Icon Theme
      // ========================================
      iconTheme: IconThemeData(
        color: tokens.brandPrimary,
        size: AppDimensions.iconMd,
      ),

      // ========================================
      // Floating Action Button Theme
      // ========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.brandPrimary,
        foregroundColor: tokens.textOnAccent,
        elevation: AppDimensions.elevationMd,
      ),

      // ========================================
      // Chip Theme
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: tokens.brandPrimarySoft,
        deleteIconColor: tokens.brandPrimaryActive,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: tokens.brandPrimaryActive,
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
        backgroundColor: tokens.bgElevated,
        elevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: tokens.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textSecondary,
        ),
      ),

      // ========================================
      // Snack Bar Theme
      // ========================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.bgElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: tokens.brandPrimary,
        disabledActionTextColor: tokens.textTertiary,
        elevation: AppDimensions.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),

      // ========================================
      // Bottom Navigation Bar Theme
      // ========================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.bgContainer,
        selectedItemColor: tokens.brandPrimary,
        unselectedItemColor: tokens.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationMd,
        selectedIconTheme: const IconThemeData(
          size: AppDimensions.bottomNavIconSize,
        ),
        unselectedIconTheme: const IconThemeData(
          size: AppDimensions.bottomNavIconSize,
        ),
      ),

      // ========================================
      // Divider Theme
      // ========================================
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: AppDimensions.dividerThickness,
        indent: AppDimensions.dividerIndent,
        endIndent: AppDimensions.dividerIndent,
      ),

      // ========================================
      // Progress Indicator Theme
      // ========================================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brandPrimary,
        linearTrackColor: tokens.trackBg,
        circularTrackColor: tokens.trackBg,
      ),

      // ========================================
      // Switch Theme
      // ========================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.brandPrimary;
          }
          return tokens.border;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.brandPrimarySoft;
          }
          return tokens.borderSecondary;
        }),
      ),

      // ========================================
      // Slider Theme
      // ========================================
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.brandPrimary,
        inactiveTrackColor: tokens.trackBg,
        thumbColor: tokens.brandPrimary,
        overlayColor: tokens.brandPrimary.withValues(alpha: 0.16),
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
    const tokens = CamsThemeTokens.dark;
    return ThemeData(
      // ========================================
      // Color Scheme - Dark Mode Digital Pulse
      // ========================================
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.brandPrimary,
        brightness: Brightness.dark,
        primary: tokens.brandPrimary,
        onPrimary: tokens.textOnAccent,
        primaryContainer: tokens.brandPrimarySoft,
        onPrimaryContainer: tokens.brandPrimaryHover,
        secondary: tokens.techAccent,
        onSecondary: tokens.textOnAccent,
        secondaryContainer: tokens.techAccentSoft,
        onSecondaryContainer: tokens.techAccentHover,
        tertiary: tokens.brandPrimaryHover,
        onTertiary: tokens.textOnAccent,
        error: tokens.error,
        onError: tokens.textOnAccent,
        errorContainer: tokens.alertErrorBg,
        onErrorContainer: tokens.brandPrimaryHover,
        surface: tokens.bgContainer,
        onSurface: tokens.textPrimary,
        surfaceContainerHighest: tokens.bgElevated,
        onSurfaceVariant: tokens.textSecondary,
        outline: tokens.border,
        outlineVariant: tokens.borderSecondary,
        shadow: tokens.shadow,
      ),

      // ========================================
      // Primary Colors
      // ========================================
      extensions: const [tokens],
      primaryColor: tokens.brandPrimary,
      primaryColorLight: tokens.brandPrimaryHover,
      primaryColorDark: tokens.brandPrimaryActive,
      scaffoldBackgroundColor: tokens.bgBase,

      // ========================================
      // AppBar Theme - Dark with Gradient
      // ========================================
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgContainer,
        foregroundColor: tokens.textPrimary,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: tokens.brandPrimary,
          size: AppDimensions.iconMd,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: tokens.textPrimary,
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
        color: tokens.bgContainer,
        shadowColor: tokens.brandPrimary.withValues(alpha: 0.12),
        margin: const EdgeInsets.all(AppDimensions.spacingMd),
      ),

      // ========================================
      // Elevated Button Theme - Neon Glow
      // ========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.brandPrimary,
          foregroundColor: tokens.textOnAccent,
          elevation: AppDimensions.elevationSm,
          shadowColor: tokens.brandPrimary.withValues(alpha: 0.35),
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
          foregroundColor: tokens.brandPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontalMd,
            vertical: AppDimensions.buttonPaddingVerticalMd,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          side: BorderSide(
            color: tokens.brandPrimary,
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
          foregroundColor: tokens.brandPrimary,
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
        fillColor: tokens.bgElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.borderSecondary,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.borderSecondary,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.brandPrimary,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.error,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusTextField),
          borderSide: BorderSide(
            color: tokens.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textTertiary,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: tokens.error,
        ),
        prefixIconColor: tokens.textSecondary,
        suffixIconColor: tokens.textSecondary,
      ),

      // ========================================
      // Dialog Theme - Dark
      // ========================================
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.bgElevated,
        elevation: AppDimensions.elevationXl,
        shadowColor: tokens.brandPrimary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusDialog),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: tokens.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textSecondary,
        ),
      ),

      // ========================================
      // Snack Bar Theme
      // ========================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.bgElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: tokens.brandPrimary,
        disabledActionTextColor: tokens.textTertiary,
        elevation: AppDimensions.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(
            color: tokens.borderSecondary,
            width: AppDimensions.borderWidthNormal,
          ),
        ),
      ),

      // ========================================
      // Bottom Navigation Bar Theme
      // ========================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.sidebar,
        selectedItemColor: tokens.brandPrimary,
        unselectedItemColor: tokens.textTertiary,
        selectedIconTheme: IconThemeData(
          size: AppDimensions.iconMd,
          color: tokens.brandPrimary,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppDimensions.iconMd,
          color: tokens.textTertiary,
        ),
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: tokens.brandPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: tokens.textTertiary,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationMd,
      ),

      // ========================================
      // Floating Action Button Theme
      // ========================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.brandPrimary,
        foregroundColor: tokens.textOnAccent,
        elevation: AppDimensions.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
      ),

      // ========================================
      // Chip Theme
      // ========================================
      chipTheme: ChipThemeData(
        backgroundColor: tokens.bgElevated,
        selectedColor: tokens.brandPrimary.withValues(alpha: 0.20),
        disabledColor: tokens.borderSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacing8,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: tokens.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.bodySmall.copyWith(
          color: tokens.textSecondary,
        ),
        side: BorderSide(
          color: tokens.borderSecondary,
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
            return tokens.brandPrimary;
          }
          return tokens.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.trackHover;
          }
          return tokens.trackBg;
        }),
      ),

      // ========================================
      // Slider Theme
      // ========================================
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.brandPrimary,
        inactiveTrackColor: tokens.trackBg,
        thumbColor: tokens.brandPrimary,
        overlayColor: tokens.brandPrimary.withValues(alpha: 0.18),
      ),

      // ========================================
      // Text Theme
      // ========================================
      textTheme: TextTheme(
        displayLarge:
            AppTypography.displayLarge.copyWith(color: tokens.textPrimary),
        displayMedium:
            AppTypography.displayMedium.copyWith(color: tokens.textPrimary),
        displaySmall:
            AppTypography.displaySmall.copyWith(color: tokens.textPrimary),
        headlineLarge:
            AppTypography.headlineLarge.copyWith(color: tokens.textPrimary),
        headlineMedium:
            AppTypography.headlineMedium.copyWith(color: tokens.textPrimary),
        headlineSmall:
            AppTypography.headlineSmall.copyWith(color: tokens.textPrimary),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: tokens.textPrimary),
        titleMedium:
            AppTypography.titleMedium.copyWith(color: tokens.textPrimary),
        titleSmall:
            AppTypography.titleSmall.copyWith(color: tokens.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: tokens.textPrimary),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: tokens.textSecondary),
        bodySmall:
            AppTypography.bodySmall.copyWith(color: tokens.textSecondary),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: tokens.textPrimary),
        labelMedium:
            AppTypography.labelMedium.copyWith(color: tokens.textSecondary),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: tokens.textTertiary),
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
