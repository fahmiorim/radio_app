import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_theme.dart';

/// A reusable background widget with decorative bubbles.
///
/// Shows two large bubbles by default and an optional small bubble
/// to match the design of various screens.
class AppBackground extends StatelessWidget {
  final bool showSmallBubble;

  const AppBackground({super.key, this.showSmallBubble = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        color: theme.colorScheme.background,
        child: Stack(
          children: [
            // Top-right large bubble
            AppTheme.bubble(
              context: context,
              size: 200,
              top: -50,
              right: -50,
              opacity: isDark ? 0.1 : 0.03,
              usePrimaryColor: true,
            ),
            // Bottom-left medium bubble
            AppTheme.bubble(
              context: context,
              size: 150,
              bottom: -30,
              left: -30,
              opacity: isDark ? 0.08 : 0.03,
              usePrimaryColor: true,
            ),
            if (showSmallBubble)
              AppTheme.bubble(
                context: context,
                size: 50,
                top: 100,
                left: 100,
                opacity: isDark ? 0.06 : 0.02,
                usePrimaryColor: true,
              ),
          ],
        ),
      ),
    );
  }
}

