import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Container with animated neon glow effect
class CAMSGlowContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double glowSpread;
  final bool animate;
  final Duration animationDuration;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const CAMSGlowContainer({
    Key? key,
    required this.child,
    this.glowColor = AppColors.primaryCyan,
    this.glowRadius = 20,
    this.glowSpread = 2,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  State<CAMSGlowContainer> createState() => _CAMSGlowContainerState();
}

class _CAMSGlowContainerState extends State<CAMSGlowContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.5),
              blurRadius: widget.glowRadius,
              spreadRadius: widget.glowSpread,
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_glowAnimation.value),
                blurRadius: widget.glowRadius,
                spreadRadius: widget.glowSpread,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulsing neon effect widget
class CAMSPulseWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final Curve curve;

  const CAMSPulseWidget({
    Key? key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  State<CAMSPulseWidget> createState() => _CAMSPulseWidgetState();
}

class _CAMSPulseWidgetState extends State<CAMSPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer loading effect with neon colors
class CAMSShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const CAMSShimmer({
    Key? key,
    required this.child,
    this.baseColor = AppColors.surfaceDark,
    this.highlightColor = AppColors.primaryCyan,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<CAMSShimmer> createState() => _CAMSShimmerState();
}

class _CAMSShimmerState extends State<CAMSShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor.withOpacity(0.3),
                widget.baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Neon border effect widget
class CAMSNeonBorder extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final bool glow;

  const CAMSNeonBorder({
    Key? key,
    required this.child,
    this.borderColor = AppColors.primaryCyan,
    this.borderWidth = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.glow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: borderColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
