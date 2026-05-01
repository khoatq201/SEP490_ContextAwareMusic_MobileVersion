import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../domain/entities/space_summary.dart';

class SpaceGridCard extends StatelessWidget {
  final SpaceSummary space;
  final VoidCallback onTap;

  const SpaceGridCard({
    super.key,
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.camsTokens;
    final isDark = theme.brightness == Brightness.dark;
    final mood = _SpaceMoodTheme.resolve(context, space.currentMood);
    final accent = space.isManualOverride ? tokens.warning : mood.color;
    final hasPlaybackLabel =
        space.currentTrack != null && space.currentTrack!.trim().isNotEmpty;
    final trackLabel =
        hasPlaybackLabel ? space.currentTrack!.trim() : 'No track';
    final playbackTitle = space.isMusicPlaying ? 'Now Playing' : 'Music';
    final energyLabel =
        mood.label == 'ENERGETIC' ? 'High Energy' : mood.caption;
    final noiseValue = space.noiseLevel ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.bgElevated.withValues(alpha: isDark ? 0.92 : 0.99),
            tokens.bgContainer.withValues(alpha: isDark ? 0.72 : 0.96),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.58 : 0.34),
          width: isDark ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.34 : 0.13),
            blurRadius: isDark ? 28 : 18,
            offset: const Offset(0, 12),
          ),
          if (space.isManualOverride)
            BoxShadow(
              color: tokens.warning.withValues(alpha: isDark ? 0.22 : 0.08),
              blurRadius: 18,
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      space.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: tokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: space.isOnline ? mood.color : tokens.textTertiary,
                      shape: BoxShape.circle,
                      boxShadow: space.isOnline
                          ? [
                              BoxShadow(
                                color: mood.color.withValues(
                                  alpha: isDark ? 0.48 : 0.18,
                                ),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MoodPill(mood: mood),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    color: mood.color,
                    secondaryColor: space.isManualOverride
                        ? tokens.warning
                        : tokens.moodDefault,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _PeopleLine(
                count: space.customerCount,
                color: mood.color,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _IconStack(
                    primaryColor: mood.color,
                    secondaryColor: space.isManualOverride
                        ? tokens.warning
                        : tokens.textTertiary,
                    isManualOverride: space.isManualOverride,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NoiseGauge(
                      value: noiseValue,
                      color: mood.color,
                      label: energyLabel,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      playbackTitle,
                      style: AppTypography.titleSmall.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: tokens.textTertiary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Track: $trackLabel',
                style: AppTypography.labelSmall.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              _VolumeLine(
                color: mood.color,
                muted: !space.isMusicPlaying && !hasPlaybackLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceMoodTheme {
  const _SpaceMoodTheme({
    required this.label,
    required this.caption,
    required this.color,
  });

  final String label;
  final String caption;
  final Color color;

  static _SpaceMoodTheme resolve(BuildContext context, String mood) {
    final tokens = context.camsTokens;
    switch (mood.trim().toLowerCase()) {
      case 'focus':
      case 'focused':
        return _SpaceMoodTheme(
          label: 'FOCUS',
          caption: 'Focused',
          color: tokens.moodFocus,
        );
      case 'chill':
      case 'calm':
      case 'relaxed':
      case 'welcoming':
      case 'social':
        return _SpaceMoodTheme(
          label: 'CHILL',
          caption: 'Conversational',
          color: tokens.moodChill,
        );
      case 'energetic':
      case 'energy':
        return _SpaceMoodTheme(
          label: 'ENERGETIC',
          caption: 'High Energy',
          color: tokens.moodEnergetic,
        );
      default:
        return _SpaceMoodTheme(
          label: 'FOCUS',
          caption: 'Focused',
          color: tokens.moodFocus,
        );
    }
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({required this.mood});

  final _SpaceMoodTheme mood;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 28,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mood.color.withValues(alpha: 0.8)),
      ),
      child: Text(
        mood.label,
        style: AppTypography.labelMedium.copyWith(
          color: mood.color,
          fontWeight: FontWeight.w900,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PeopleLine extends StatelessWidget {
  const _PeopleLine({
    required this.count,
    required this.color,
  });

  final int? count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final text = count == null ? '-- People' : '$count People';

    return Row(
      children: [
        Icon(Icons.groups_2_outlined, size: 16, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IconStack extends StatelessWidget {
  const _IconStack({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isManualOverride,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final bool isManualOverride;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoundIcon(icon: Icons.volume_up_rounded, color: primaryColor),
        const SizedBox(height: 8),
        _RoundIcon(
          icon: isManualOverride
              ? Icons.pan_tool_alt_rounded
              : Icons.sentiment_satisfied_alt_rounded,
          color: secondaryColor,
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _NoiseGauge extends StatelessWidget {
  const _NoiseGauge({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final displayValue = value <= 0 ? '--' : value.toStringAsFixed(0);

    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GaugePainter(
                color: color,
                trackColor: tokens.borderSecondary,
                value: (value / 100).clamp(0.12, 0.95),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  '$displayValue dB',
                  style: AppTypography.titleSmall.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeLine extends StatelessWidget {
  const _VolumeLine({
    required this.color,
    required this.muted,
  });

  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Row(
      children: [
        Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: muted ? tokens.textTertiary : color,
          size: 18,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: muted ? 0.18 : 0.48,
              minHeight: 5,
              color: muted ? tokens.textTertiary : color,
              backgroundColor: tokens.borderSecondary,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: muted ? tokens.textTertiary : color,
          size: 18,
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.color,
    required this.secondaryColor,
    required this.isDark,
  });

  final Color color;
  final Color secondaryColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 36;
    final gap = size.width / (bars * 1.7);
    final width = gap * 0.72;
    final centerY = size.height / 2;

    for (var i = 0; i < bars; i++) {
      final t = i / (bars - 1);
      final wave = (0.45 + 0.55 * (1 - (2 * t - 1).abs()));
      final ripple = i.isEven ? 0.72 : 1.0;
      final barHeight = size.height * wave * ripple;
      final paint = Paint()
        ..color = Color.lerp(color, secondaryColor, t)!
            .withValues(alpha: isDark ? 0.88 : 0.62)
        ..style = PaintingStyle.fill;
      final x = i * (width + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + width / 2, centerY),
          width: width,
          height: barHeight.clamp(5, size.height),
        ),
        Radius.circular(width),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.color,
    required this.trackColor,
    required this.value,
  });

  final Color color;
  final Color trackColor;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 12, size.width - 16, size.height * 1.28);
    final strokeWidth = size.width < 120 ? 9.0 : 11.0;
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14, 3.14, false, trackPaint);
    canvas.drawArc(rect, 3.14, 3.14 * value, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.value != value;
  }
}
