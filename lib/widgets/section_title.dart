import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll; // opsional, kalau mau ada tombol "Lihat Semua"
  final TextStyle? titleStyle;

  const SectionTitle({
    super.key,
    required this.title,
    this.onSeeAll,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
                titleStyle ??
                theme.textTheme.titleMedium?.copyWith(letterSpacing: 0.5),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                "Lihat Semua",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
