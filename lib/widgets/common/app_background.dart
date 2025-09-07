import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.showTopRightBubble = true,
    this.showBottomLeftBubble = true,
    this.showCenterLeftBubble = true,
  });

  final bool showTopRightBubble;
  final bool showBottomLeftBubble;
  final bool showCenterLeftBubble;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: theme.colorScheme.background),
        if (showTopRightBubble)
          AppTheme.bubble(
            context: context,
            size: 200,
            top: -50,
            right: -50,
            opacity: isDarkMode ? 0.1 : 0.03,
            usePrimaryColor: true,
          ),
        if (showBottomLeftBubble)
          AppTheme.bubble(
            context: context,
            size: 150,
            bottom: -30,
            left: -30,
            opacity: isDarkMode ? 0.08 : 0.03,
            usePrimaryColor: true,
          ),
        if (showCenterLeftBubble)
          AppTheme.bubble(
            context: context,
            size: 50,
            top: 100,
            left: 100,
            opacity: isDarkMode ? 0.06 : 0.02,
            usePrimaryColor: true,
          ),
      ],
    );
  }
}
