import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppHeaderSkeleton extends StatelessWidget {
  const AppHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo + Text
            Row(
              children: [
                // Logo placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // ODAN FM text placeholder
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'ODAN FM',
                    style: TextStyle(
                      color: Colors.transparent,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                      backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
              ],
            ),
            // Avatar placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
