import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/cams_theme_tokens.dart';

/// CAMS Signature Button - Brand-consistent button styles
class CAMSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CAMSButtonVariant variant;
  final CAMSButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;

  const CAMSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CAMSButtonVariant.primary,
    this.size = CAMSButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final buttonChild = _buildButtonChild(colorScheme, tokens);
    final buttonStyle = _buildButtonStyle(colorScheme, tokens);

    final button = ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            },
      style: buttonStyle,
      child: buttonChild,
    );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }

  Widget _buildButtonChild(ColorScheme colorScheme, CamsThemeTokens tokens) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == CAMSButtonVariant.primary ||
                    variant == CAMSButtonVariant.teal ||
                    variant == CAMSButtonVariant.gradient
                ? tokens.textOnAccent
                : (customColor ?? colorScheme.primary),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppDimensions.spacing8),
          Text(text, style: _getTextStyle()),
        ],
      );
    }

    return Text(text, style: _getTextStyle());
  }

  ButtonStyle _buildButtonStyle(
    ColorScheme colorScheme,
    CamsThemeTokens tokens,
  ) {
    switch (variant) {
      case CAMSButtonVariant.primary:
        return _primaryStyle(colorScheme, tokens);
      case CAMSButtonVariant.secondary:
        return _secondaryStyle(colorScheme, tokens);
      case CAMSButtonVariant.teal:
        return _tealStyle(tokens);
      case CAMSButtonVariant.outlined:
        return _outlinedStyle(colorScheme);
      case CAMSButtonVariant.text:
        return _textStyle(colorScheme);
      case CAMSButtonVariant.gradient:
        return _gradientStyle(colorScheme, tokens);
      case CAMSButtonVariant.ghost:
        return _ghostStyle(tokens);
    }
  }

  ButtonStyle _primaryStyle(ColorScheme colorScheme, CamsThemeTokens tokens) {
    final background = customColor ?? colorScheme.primary;
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: colorScheme.onPrimary,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 0,
      shadowColor: background.withValues(alpha: 0.18),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        tokens.textOnAccent.withValues(alpha: 0.1),
      ),
    );
  }

  ButtonStyle _secondaryStyle(
    ColorScheme colorScheme,
    CamsThemeTokens tokens,
  ) {
    return ElevatedButton.styleFrom(
      backgroundColor: tokens.brandPrimarySoft,
      foregroundColor: tokens.brandPrimaryActive,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  ButtonStyle _tealStyle(CamsThemeTokens tokens) {
    final background = customColor ?? tokens.techAccent;
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: tokens.textOnAccent,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 0,
      shadowColor: background.withValues(alpha: 0.18),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        tokens.textOnAccent.withValues(alpha: 0.1),
      ),
    );
  }

  ButtonStyle _outlinedStyle(ColorScheme colorScheme) {
    final accent = customColor ?? colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: accent,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      side: BorderSide(
        color: accent,
        width: AppDimensions.borderWidthThick,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        accent.withValues(alpha: 0.1),
      ),
    );
  }

  ButtonStyle _textStyle(ColorScheme colorScheme) {
    final accent = customColor ?? colorScheme.primary;
    return TextButton.styleFrom(
      foregroundColor: accent,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        accent.withValues(alpha: 0.1),
      ),
    );
  }

  ButtonStyle _gradientStyle(ColorScheme colorScheme, CamsThemeTokens tokens) {
    return _primaryStyle(colorScheme, tokens);
  }

  ButtonStyle _ghostStyle(CamsThemeTokens tokens) {
    return ElevatedButton.styleFrom(
      backgroundColor: tokens.textOnAccent.withValues(alpha: 0.1),
      foregroundColor: tokens.textOnAccent,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        side: BorderSide(
          color: tokens.textOnAccent.withValues(alpha: 0.3),
          width: AppDimensions.borderWidthNormal,
        ),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        tokens.textOnAccent.withValues(alpha: 0.1),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case CAMSButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalSm,
          vertical: AppDimensions.buttonPaddingVerticalSm,
        );
      case CAMSButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalMd,
          vertical: AppDimensions.buttonPaddingVerticalMd,
        );
      case CAMSButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalLg,
          vertical: AppDimensions.buttonPaddingVerticalLg,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case CAMSButtonSize.small:
        return AppDimensions.buttonHeightSm;
      case CAMSButtonSize.medium:
        return AppDimensions.buttonHeightMd;
      case CAMSButtonSize.large:
        return AppDimensions.buttonHeightLg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case CAMSButtonSize.small:
        return AppDimensions.iconSm;
      case CAMSButtonSize.medium:
        return AppDimensions.iconMd;
      case CAMSButtonSize.large:
        return AppDimensions.iconLg;
    }
  }

  TextStyle _getTextStyle() {
    const baseStyle = AppTypography.button;

    switch (size) {
      case CAMSButtonSize.small:
        return baseStyle.copyWith(fontSize: 14);
      case CAMSButtonSize.medium:
        return baseStyle.copyWith(fontSize: 16);
      case CAMSButtonSize.large:
        return baseStyle.copyWith(fontSize: 18);
    }
  }
}

enum CAMSButtonVariant {
  primary, // Orange - Primary brand color
  secondary, // Light orange variant
  teal, // Teal - Technology/secondary brand color
  outlined,
  text,
  gradient,
  ghost,
}

enum CAMSButtonSize {
  small,
  medium,
  large,
}

/// CAMS Icon Button - Circular button with icon only
class CAMSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final bool hasShadow;

  const CAMSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? AppDimensions.iconXl;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final resolvedBackground = backgroundColor ?? colorScheme.primary;
    final resolvedIconColor = iconColor ?? colorScheme.onPrimary;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: resolvedBackground,
        shape: BoxShape.circle,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: resolvedBackground.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed?.call();
          },
          borderRadius: BorderRadius.circular(buttonSize / 2),
          splashColor: tokens.textOnAccent.withValues(alpha: 0.2),
          highlightColor: tokens.textOnAccent.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              icon,
              color: resolvedIconColor,
              size: buttonSize * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
