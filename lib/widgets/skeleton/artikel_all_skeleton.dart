import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ArtikelAllSkeleton extends StatelessWidget {
  final int itemCount;

  const ArtikelAllSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail shimmer
              Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceVariant,
                highlightColor: theme.colorScheme.surface,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul shimmer
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tags shimmer
                    Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: theme.colorScheme.surfaceVariant,
                          highlightColor: theme.colorScheme.surface,
                          child: Container(
                            width: 60,
                            height: 12,
                            color: theme.colorScheme.surfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Shimmer.fromColors(
                          baseColor: theme.colorScheme.surfaceVariant,
                          highlightColor: theme.colorScheme.surface,
                          child: Container(
                            width: 40,
                            height: 12,
                            color: theme.colorScheme.surfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date shimmer
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.surfaceVariant,
                      highlightColor: theme.colorScheme.surface,
                      child: Container(
                        width: 80,
                        height: 12,
                        color: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
