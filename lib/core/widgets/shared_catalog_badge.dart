import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/cams_theme_tokens.dart';

bool isSharedCatalogItem(String? brandId) {
  return brandId == null || brandId.trim().isEmpty;
}

class SharedCatalogBadge extends StatelessWidget {
  const SharedCatalogBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final color = tokens.techAccent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.share2,
            size: compact ? 10 : 11,
            color: color,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            'Shared',
            style: GoogleFonts.inter(
              color: color,
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
