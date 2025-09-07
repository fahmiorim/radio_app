import 'package:flutter/material.dart';

import 'package:radio_odan_app/config/app_theme.dart';

/// A reusable background widget that fills all available space with the
/// application's background color and decorative bubbles.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox.expand(
      child: Container(
        color: theme.colorScheme.background,
        child: Stack(
          children: [
            AppTheme.bubble(
              context: context,
              size: 200,
              top: -50,
              right: -50,
              opacity: isDarkMode ? 0.1 : 0.03,
              usePrimaryColor: true,
            ),
            AppTheme.bubble(
              context: context,
              size: 150,
              bottom: -30,
              left: -30,
              opacity: isDarkMode ? 0.08 : 0.03,
              usePrimaryColor: true,
            ),
          ],
        ),
      ),
    );
  }
}

