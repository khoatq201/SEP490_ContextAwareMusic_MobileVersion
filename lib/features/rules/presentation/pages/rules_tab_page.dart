import 'package:flutter/material.dart';

import '../../../../core/theme/cams_theme_tokens.dart';

class RulesTabPage extends StatelessWidget {
  const RulesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: tokens.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rules',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage music playback rules - Coming soon',
              style: TextStyle(color: tokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
