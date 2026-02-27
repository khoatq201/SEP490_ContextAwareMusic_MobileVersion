import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A), // Deep blue-navy at top
              Color(0xFF0A1929), // backgroundDarkPrimary
              Color(0xFF050E18), // Darker at bottom
            ],
            stops: [0.0, 0.55, 1.0],
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
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.only(
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
                color: AppColors.primaryOrange.withOpacity(0.7),
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
                color: AppColors.primaryOrange.withOpacity(0.5),
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
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
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
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    // Card definitions: [angle, left%, top%, colorHex, label, sublabel]
    final cards = [
      const _CardDef(
          angle: -0.18,
          leftF: 0.52,
          topF: 0.12,
          color: Color(0xFF1A3A5C),
          label: 'Jazz Lounge',
          sub: 'HOTEL'),
      const _CardDef(
          angle: 0.08,
          leftF: 0.1,
          topF: 0.22,
          color: Color(0xFF2C1654),
          label: 'Night Vibes',
          sub: 'BAR'),
      const _CardDef(
          angle: 0.25,
          leftF: 0.35,
          topF: 0.30,
          color: Color(0xFF1B3A2D),
          label: 'Chill Afternoon',
          sub: 'CAFÉ'),
      const _CardDef(
          angle: -0.08,
          leftF: 0.55,
          topF: 0.35,
          color: Color(0xFF3A1A1A),
          label: 'Hip Bar Grooves',
          sub: 'BAR'),
      const _CardDef(
          angle: 0.12,
          leftF: 0.0,
          topF: 0.38,
          color: Color(0xFF1A2C3A),
          label: 'Retail Rush',
          sub: 'STORE'),
    ];

    return Stack(
      children: [
        // Gradient overlay at bottom so cards fade into the action area
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: screenH * 0.45,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF050E18)],
                stops: [0.0, 0.85],
              ),
            ),
          ),
        ),
        // Cards
        ...cards.map((c) {
          final cardW = screenW * 0.52;
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
                  Colors.white.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Music note icon (subtle watermark)
          Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withOpacity(0.06),
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
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tagline
          Text(
            'Smart music,\nsmarter spaces.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),

          // Sign up — filled primary button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: launch https://your-website.com/signup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration portal coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38, width: 1.5),
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
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
