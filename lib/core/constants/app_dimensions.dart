/// CAMS Dimensions System - Consistent spacing and sizing
class AppDimensions {
  // ========================================
  // Spacing Scale (Multiples of 4)
  // ========================================

  static const double spacing0 = 0;
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing28 = 28;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing56 = 56;
  static const double spacing64 = 64;
  static const double spacing80 = 80;
  static const double spacing96 = 96;

  // Semantic spacing names
  static const double spacingXs = spacing4;
  static const double spacingSm = spacing8;
  static const double spacingMd = spacing16;
  static const double spacingLg = spacing24;
  static const double spacingXl = spacing32;
  static const double spacingXxl = spacing48;
  static const double spacingXxxl = spacing64;

  // ========================================
  // Border Radius (Signature rounded corners)
  // ========================================

  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusXxxl = 32;
  static const double radiusFull = 9999; // Fully rounded

  // Component-specific radius
  static const double radiusButton = radiusLg;
  static const double radiusCard = radiusXxl;
  static const double radiusDialog = radiusXl;
  static const double radiusTextField = radiusMd;
  static const double radiusChip = radiusFull;

  // ========================================
  // Icon Sizes
  // ========================================

  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;
  static const double iconXxl = 48;
  static const double iconXxxl = 64;

  // ========================================
  // Button Sizes
  // ========================================

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;
  static const double buttonHeightXl = 64;

  static const double buttonPaddingHorizontalSm = spacing16;
  static const double buttonPaddingHorizontalMd = spacing24;
  static const double buttonPaddingHorizontalLg = spacing32;

  static const double buttonPaddingVerticalSm = spacing8;
  static const double buttonPaddingVerticalMd = spacing12;
  static const double buttonPaddingVerticalLg = spacing16;

  // ========================================
  // Card Sizes
  // ========================================

  static const double cardPaddingSm = spacing12;
  static const double cardPaddingMd = spacing16;
  static const double cardPaddingLg = spacing24;
  static const double cardPaddingXl = spacing32;

  static const double cardElevation = 4;
  static const double cardElevationHover = 8;

  // ========================================
  // Border Widths
  // ========================================

  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1;
  static const double borderWidthThick = 2;
  static const double borderWidthXthick = 3;

  // ========================================
  // Avatar Sizes
  // ========================================

  static const double avatarXs = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 80;
  static const double avatarXxl = 120;

  // ========================================
  // Elevation/Shadow
  // ========================================

  static const double elevationNone = 0;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 16;
  static const double elevationXxl = 24;

  // ========================================
  // Opacity Levels
  // ========================================

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // Glassmorphism opacity
  static const double glassOpacityLight = 0.1;
  static const double glassOpacityMedium = 0.2;
  static const double glassOpacityStrong = 0.3;

  // ========================================
  // Container Constraints
  // ========================================

  static const double maxWidthMobile = 480;
  static const double maxWidthTablet = 768;
  static const double maxWidthDesktop = 1200;
  static const double maxWidthWide = 1600;

  // ========================================
  // Animation Durations (milliseconds)
  // ========================================

  static const int durationInstant = 100;
  static const int durationFast = 200;
  static const int durationNormal = 300;
  static const int durationSlow = 500;
  static const int durationVerySlow = 700;

  // ========================================
  // Sensor Widget Specific
  // ========================================

  static const double sensorCardHeight = 160;
  static const double sensorCardWidth = 140;
  static const double sensorIconSize = iconXxl;
  static const double sensorValueSize = 48;

  // ========================================
  // Music Player Specific
  // ========================================

  static const double musicBarWidth = 4;
  static const double musicBarSpacing = spacing4;
  static const double musicBarMinHeight = 8;
  static const double musicBarMaxHeight = 32;

  // ========================================
  // AppBar
  // ========================================

  static const double appBarHeight = 56;
  static const double appBarElevation = 0;

  // ========================================
  // Bottom Navigation
  // ========================================

  static const double bottomNavHeight = 64;
  static const double bottomNavIconSize = iconMd;

  // ========================================
  // Divider
  // ========================================

  static const double dividerThickness = borderWidthNormal;
  static const double dividerIndent = spacing16;

  // ========================================
  // TextField
  // ========================================

  static const double textFieldHeight = 56;
  static const double textFieldPaddingHorizontal = spacing16;
  static const double textFieldPaddingVertical = spacing16;
  static const double textFieldBorderWidth = borderWidthNormal;

  // ========================================
  // Glassmorphism Blur
  // ========================================

  static const double blurLight = 5;
  static const double blurMedium = 10;
  static const double blurStrong = 20;
  static const double blurXstrong = 30;
}
