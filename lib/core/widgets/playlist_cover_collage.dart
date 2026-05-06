import 'package:flutter/material.dart';

class PlaylistCoverCollage extends StatelessWidget {
  const PlaylistCoverCollage({
    super.key,
    required this.coverUrls,
    this.fallbackCoverUrl,
    this.borderRadius = BorderRadius.zero,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 28,
  });

  final List<String?> coverUrls;
  final String? fallbackCoverUrl;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final urls = _dedupeUrls([
      ...coverUrls,
      fallbackCoverUrl,
    ]);

    final fallback = _PlaylistCoverFallback(
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      iconSize: iconSize,
    );
    final cover = urls.isEmpty
        ? fallback
        : _CoverGrid(
            urls: urls.take(4).toList(growable: false),
            fallback: fallback,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.hasBoundedWidth;
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final child = ClipRRect(
          borderRadius: borderRadius,
          child: cover,
        );

        if (hasBoundedWidth && hasBoundedHeight) {
          return SizedBox.expand(child: child);
        }

        if (hasBoundedWidth) {
          return AspectRatio(aspectRatio: 1, child: child);
        }

        return SizedBox.square(dimension: 96, child: child);
      },
    );
  }

  static List<String> _dedupeUrls(List<String?> values) {
    final seen = <String>{};
    final urls = <String>[];
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) continue;
      final signature = _stableUrlSignature(trimmed);
      if (!seen.add(signature)) continue;
      urls.add(trimmed);
    }
    return urls;
  }

  static String _stableUrlSignature(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return value;
    return uri.replace(query: '', fragment: '').toString();
  }
}

class _CoverGrid extends StatelessWidget {
  const _CoverGrid({
    required this.urls,
    required this.fallback,
  });

  final List<String> urls;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return _StableNetworkCover(url: urls.first, fallback: fallback);
    }

    Widget coverAt(int index) {
      final url = urls[index % urls.length];
      return Expanded(
        child: _StableNetworkCover(url: url, fallback: fallback),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              coverAt(0),
              const SizedBox(width: 1),
              coverAt(1),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              coverAt(2),
              const SizedBox(width: 1),
              coverAt(3),
            ],
          ),
        ),
      ],
    );
  }
}

class _StableNetworkCover extends StatefulWidget {
  const _StableNetworkCover({
    required this.url,
    required this.fallback,
  });

  final String url;
  final Widget fallback;

  @override
  State<_StableNetworkCover> createState() => _StableNetworkCoverState();
}

class _StableNetworkCoverState extends State<_StableNetworkCover> {
  late String _displayedUrl;
  late String _displayedSignature;

  @override
  void initState() {
    super.initState();
    _displayedUrl = widget.url;
    _displayedSignature = PlaylistCoverCollage._stableUrlSignature(widget.url);
  }

  @override
  void didUpdateWidget(covariant _StableNetworkCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = PlaylistCoverCollage._stableUrlSignature(widget.url);
    if (nextSignature == _displayedSignature) return;
    _displayedSignature = nextSignature;
    _displayedUrl = widget.url;
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _displayedUrl,
      key: ValueKey(_displayedSignature),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => widget.fallback,
    );
  }
}

class _PlaylistCoverFallback extends StatelessWidget {
  const _PlaylistCoverFallback({
    required this.backgroundColor,
    required this.iconColor,
    required this.iconSize,
  });

  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: backgroundColor ?? colorScheme.primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: iconColor ?? colorScheme.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
