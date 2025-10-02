import 'package:flutter/material.dart';

class UnreadMessagesLabel extends StatelessWidget {
  final int count;
  const UnreadMessagesLabel({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count == 1
        ? '1 pesan belum dibaca'
        : '$count pesan belum dibaca';

    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Color.alphaBlend(
          theme.colorScheme.onSurface.withValues(alpha: 0.54),
          theme.colorScheme.surface,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
