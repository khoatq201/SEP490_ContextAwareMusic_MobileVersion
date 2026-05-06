import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/cams_theme_tokens.dart';

/// Welcome / Landing screen — the first thing a new user sees.
/// Inspired by Spotify-style onboarding: dark gradient bg, collage of
/// rotated cards in the center, action buttons pinned at the bottom.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tokens.bgLayout,
              tokens.bgBase,
              tokens.sidebar,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── CAMS logo (top-left) ──────────────────────────────────
              Positioned(
                top: 20,
                left: 24,
                child: _CAMSSymbol(),
              ),

              // ── Collage of floating cards ─────────────────────────────
              Positioned.fill(
                child: _CardCollage(),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.sizeOf(context).height * 0.46,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.bgBase.withValues(alpha: 0.0),
                          tokens.bgBase.withValues(alpha: 0.92),
                          tokens.bgBase,
                        ],
                        stops: const [0.0, 0.28, 0.62],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom action area ────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _BottomActions(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CAMS Symbol (top-left logo mark) ────────────────────────────────────────
class _CAMSSymbol extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    const double s = 40;
    const double g = 4;
    const r = Radius.circular(10);
    return SizedBox(
      width: s * 2 + g,
      height: s * 2 + g,
      child: Stack(
        children: [
          // Top-left: solid primary
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: tokens.brandPrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: r,
                  topRight: r,
                  bottomLeft: r,
                ),
              ),
            ),
          ),
          // Top-right: slightly transparent
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: tokens.brandPrimaryHover.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom-left: circle accent
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: tokens.brandPrimary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom-right: small dot
          Positioned(
            right: s * 0.1,
            bottom: s * 0.1,
            child: Container(
              width: s * 0.65,
              height: s * 0.65,
              decoration: BoxDecoration(
                color: tokens.brandPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Collage of rotated music-themed cards ────────────────────────────────────
class _CardCollage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final compact = screenH < 740;

    // Card definitions: [angle, left%, top%, colorHex, label, sublabel]
    final cards = [
      _CardDef(
          angle: -0.18,
          leftF: 0.50,
          topF: compact ? 0.10 : 0.12,
          color: tokens.techAccent.withValues(alpha: 0.48),
          label: 'Jazz Lounge',
          sub: 'HOTEL'),
      _CardDef(
          angle: 0.08,
          leftF: 0.1,
          topF: compact ? 0.20 : 0.22,
          color: tokens.moodDefault.withValues(alpha: 0.40),
          label: 'Night Vibes',
          sub: 'BAR'),
      _CardDef(
          angle: 0.25,
          leftF: 0.35,
          topF: compact ? 0.28 : 0.30,
          color: tokens.moodChill.withValues(alpha: 0.38),
          label: 'Chill Afternoon',
          sub: 'CAFÉ'),
      _CardDef(
          angle: -0.08,
          leftF: 0.55,
          topF: compact ? 0.32 : 0.35,
          color: tokens.brandPrimary.withValues(alpha: 0.48),
          label: 'Hip Bar Grooves',
          sub: 'BAR'),
      _CardDef(
          angle: -0.12,
          leftF: -0.08,
          topF: compact ? 0.34 : 0.37,
          color: tokens.brandPrimarySoft.withValues(alpha: 0.92),
          label: 'Retail Rush',
          sub: 'STORE'),
    ];

    return Stack(
      children: [
        // Cards
        ...cards.map((c) {
          final cardW = screenW * (compact ? 0.46 : 0.50);
          final cardH = cardW * 1.25;
          return Positioned(
            left: screenW * c.leftF,
            top: screenH * c.topF,
            child: Transform.rotate(
              angle: c.angle,
              child: _SpaceCard(
                width: cardW,
                height: cardH,
                color: c.color,
                label: c.label,
                sub: c.sub,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CardDef {
  final double angle, leftF, topF;
  final Color color;
  final String label, sub;
  const _CardDef(
      {required this.angle,
      required this.leftF,
      required this.topF,
      required this.color,
      required this.label,
      required this.sub});
}

class _SpaceCard extends StatelessWidget {
  final double width, height;
  final Color color;
  final String label, sub;
  const _SpaceCard(
      {required this.width,
      required this.height,
      required this.color,
      required this.label,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Faint texture overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tokens.textPrimary.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Music note icon (subtle watermark)
          Center(
            child: Icon(
              Icons.music_note_rounded,
              color: tokens.textPrimary.withValues(alpha: 0.08),
              size: width * 0.55,
            ),
          ),
          // Label at bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sub,
                    style: GoogleFonts.inter(
                      color: tokens.textPrimary.withValues(alpha: 0.54),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.poppins(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action buttons ────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tagline
          Text(
            'Smart music,\nsmarter spaces.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: tokens.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Control the right soundtrack for every space.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: tokens.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),

          // Sign up — filled primary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              onPressed: () => _openRegistrationPortal(context),
              child: Text('Sign up',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(height: 12),

          // Log in — outlined button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              key: const ValueKey('welcome_login_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: tokens.bgContainer.withValues(alpha: 0.82),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.42),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: () => context.go('/login'),
              child: Text('Log in',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 20),

          // Set up playback device — text link
          GestureDetector(
            onTap: () => context.push('/pair-device'),
            child: Text(
              'Set up playback device',
              style: GoogleFonts.inter(
                color: tokens.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: tokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegistrationPortal(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppConstants.registrationPortalUrl),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppConstants.registrationPortalOpenError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
