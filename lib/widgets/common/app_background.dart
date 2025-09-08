import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.showTopRightBubble = true,
    this.showBottomLeftBubble = true,
    this.showCenterBubble = true,
    this.child,
  });

  final bool showTopRightBubble;
  final bool showBottomLeftBubble;
  final bool showCenterBubble;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Container(color: theme.colorScheme.background),
        if (child != null) child!,
        if (showTopRightBubble)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(
                  isDarkMode ? 0.15 : 0.05,
                ),
              ),
            ),
          ),
        if (showBottomLeftBubble)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(
                  isDarkMode ? 0.15 : 0.05,
                ),
              ),
            ),
          ),
        if (showCenterBubble)
          Positioned(
            top: 150,
            left: 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(
                  isDarkMode ? 0.1 : 0.03,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
