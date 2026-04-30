import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/cams_theme_tokens.dart';

class CamsSkeleton extends StatefulWidget {
  const CamsSkeleton({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<CamsSkeleton> createState() => _CamsSkeletonState();
}

class _CamsSkeletonState extends State<CamsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBase = widget.baseColor ??
        (isDark ? AppColors.darkBgElevated : AppColors.lightBorderSecondary);
    final resolvedHighlight = widget.highlightColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBgContainer);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                resolvedBase,
                resolvedHighlight,
                resolvedBase,
              ],
              stops: const [0.18, 0.5, 0.82],
              transform: _SlidingGradientTransform(
                Curves.easeInOut.transform(_controller.value) * 3 - 1,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value, 0, 0);
  }
}

class CamsSkeletonBox extends StatelessWidget {
  const CamsSkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppDimensions.radiusSm,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return CamsSkeleton(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: tokens.bgContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class CamsSkeletonLine extends StatelessWidget {
  const CamsSkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.margin,
  });

  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return CamsSkeletonBox(
      width: width,
      height: height,
      radius: AppDimensions.radiusFull,
      margin: margin,
    );
  }
}

class CamsSkeletonCircle extends StatelessWidget {
  const CamsSkeletonCircle({
    super.key,
    required this.size,
    this.margin,
  });

  final double size;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return CamsSkeleton(
      child: Container(
        width: size,
        height: size,
        margin: margin,
        decoration: BoxDecoration(
          color: tokens.bgContainer,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class CamsSkeletonHeader extends StatelessWidget {
  const CamsSkeletonHeader({
    super.key,
    this.showAvatar = false,
    this.titleWidth = 180,
    this.subtitleWidth = 120,
  });

  final bool showAvatar;
  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showAvatar) ...[
          const CamsSkeletonCircle(size: 48),
          const SizedBox(width: AppDimensions.spacing12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CamsSkeletonLine(width: titleWidth, height: 18),
              const SizedBox(height: AppDimensions.spacing8),
              CamsSkeletonLine(width: subtitleWidth),
            ],
          ),
        ),
      ],
    );
  }
}

class CamsSkeletonList extends StatelessWidget {
  const CamsSkeletonList({
    super.key,
    this.itemCount = 6,
    this.showLeading = true,
    this.showTrailing = false,
    this.itemHeight = 68,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
  });

  final int itemCount;
  final bool showLeading;
  final bool showTrailing;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spacing12),
      itemBuilder: (context, index) {
        return CamsSkeletonListTile(
          showLeading: showLeading,
          showTrailing: showTrailing,
          height: itemHeight,
          titleWidthFactor: index.isEven ? 0.72 : 0.56,
          subtitleWidthFactor: index.isEven ? 0.48 : 0.62,
        );
      },
    );
  }
}

class CamsSkeletonListTile extends StatelessWidget {
  const CamsSkeletonListTile({
    super.key,
    this.showLeading = true,
    this.showTrailing = false,
    this.height = 68,
    this.titleWidthFactor = 0.65,
    this.subtitleWidthFactor = 0.45,
  });

  final bool showLeading;
  final bool showTrailing;
  final double height;
  final double titleWidthFactor;
  final double subtitleWidthFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (showLeading) ...[
            CamsSkeletonBox(
              width: height,
              height: height,
              radius: AppDimensions.radiusMd,
            ),
            const SizedBox(width: AppDimensions.spacing12),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CamsSkeletonLine(
                      width: constraints.maxWidth * titleWidthFactor,
                      height: 14,
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    CamsSkeletonLine(
                      width: constraints.maxWidth * subtitleWidthFactor,
                    ),
                  ],
                );
              },
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: AppDimensions.spacing12),
            const CamsSkeletonCircle(size: 32),
          ],
        ],
      ),
    );
  }
}

class CamsSkeletonCardGrid extends StatelessWidget {
  const CamsSkeletonCardGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppDimensions.spacing12,
        mainAxisSpacing: AppDimensions.spacing12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        return const CamsSkeletonBox(radius: AppDimensions.radiusMd);
      },
    );
  }
}

class CamsSkeletonDetailPage extends StatelessWidget {
  const CamsSkeletonDetailPage({
    super.key,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
    this.showLargeArt = true,
  });

  final EdgeInsetsGeometry padding;
  final bool showLargeArt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLargeArt) ...[
            const Center(
              child: CamsSkeletonBox(
                width: 220,
                height: 220,
                radius: AppDimensions.radiusXl,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
          ],
          const CamsSkeletonLine(width: 220, height: 20),
          const SizedBox(height: AppDimensions.spacing8),
          const CamsSkeletonLine(width: 140),
          const SizedBox(height: AppDimensions.spacing24),
          const CamsSkeletonList(
            itemCount: 6,
            padding: EdgeInsets.zero,
            showTrailing: true,
          ),
        ],
      ),
    );
  }
}

class CamsSkeletonDashboard extends StatelessWidget {
  const CamsSkeletonDashboard({
    super.key,
    this.padding = const EdgeInsets.all(AppDimensions.spacing16),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CamsSkeletonHeader(showAvatar: true),
          SizedBox(height: AppDimensions.spacing24),
          CamsSkeletonCardGrid(
            itemCount: 4,
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: AppDimensions.spacing24),
          CamsSkeletonLine(width: 160, height: 18),
          SizedBox(height: AppDimensions.spacing12),
          CamsSkeletonList(
            itemCount: 5,
            padding: EdgeInsets.zero,
            showTrailing: true,
          ),
        ],
      ),
    );
  }
}
