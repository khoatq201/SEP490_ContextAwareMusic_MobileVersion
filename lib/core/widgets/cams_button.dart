import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

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
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = CAMSButtonVariant.primary,
    this.size = CAMSButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonChild = _buildButtonChild();
    final buttonStyle = _buildButtonStyle();

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

  Widget _buildButtonChild() {
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
                ? Colors.white
                : AppColors.primaryOrange,
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

  ButtonStyle _buildButtonStyle() {
    switch (variant) {
      case CAMSButtonVariant.primary:
        return _primaryStyle();
      case CAMSButtonVariant.secondary:
        return _secondaryStyle();
      case CAMSButtonVariant.teal:
        return _tealStyle();
      case CAMSButtonVariant.outlined:
        return _outlinedStyle();
      case CAMSButtonVariant.text:
        return _textStyle();
      case CAMSButtonVariant.gradient:
        return _gradientStyle();
      case CAMSButtonVariant.ghost:
        return _ghostStyle();
    }
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: customColor ?? AppColors.primaryOrange,
      foregroundColor: Colors.white,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 2,
      shadowColor: (customColor ?? AppColors.primaryOrange).withOpacity(0.15),
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        Colors.white.withOpacity(0.1),
      ),
    );
  }

  ButtonStyle _secondaryStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryOrangeLight,
      foregroundColor: AppColors.primaryOrangeDark,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        AppColors.primaryOrange.withOpacity(0.1),
      ),
    );
  }

  ButtonStyle _tealStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: customColor ?? AppColors.secondaryTeal,
      foregroundColor: Colors.white,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      elevation: 2,
      shadowColor: (customColor ?? AppColors.secondaryTeal).withOpacity(0.15),
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        Colors.white.withOpacity(0.1),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: customColor ?? AppColors.primaryOrange,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      side: BorderSide(
        color: customColor ?? AppColors.primaryOrange,
        width: AppDimensions.borderWidthThick,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        (customColor ?? AppColors.primaryOrange).withOpacity(0.1),
      ),
    );
  }

  ButtonStyle _textStyle() {
    return TextButton.styleFrom(
      foregroundColor: customColor ?? AppColors.primaryOrange,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        (customColor ?? AppColors.primaryOrange).withOpacity(0.1),
      ),
    );
  }

  ButtonStyle _gradientStyle() {
    return _primaryStyle();
  }

  ButtonStyle _ghostStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.1),
      foregroundColor: Colors.white,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: AppDimensions.borderWidthNormal,
        ),
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        Colors.white.withOpacity(0.1),
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
    final baseStyle = AppTypography.button;

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
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.hasShadow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? AppDimensions.iconXl;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryOrange,
        shape: BoxShape.circle,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primaryOrange)
                      .withOpacity(0.15),
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
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: buttonSize * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
